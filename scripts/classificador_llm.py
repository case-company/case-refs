#!/usr/bin/env python3
"""
Classificador LLM standalone — recebe payload Apify de 1 post, chama Claude
via subprocess `claude -p`, devolve JSON com classificação editorial DECIDA.

Uso (CLI):
    cat post.json | python3 classificador_llm.py
    # ou
    python3 classificador_llm.py < post.json

Input (stdin, JSON único item Apify):
    { "shortCode": "...", "caption": "...", "transcricao": "...",
      "ownerUsername": "...", "videoDuration": 60, ... }

Output (stdout, JSON com classificação + quality_score):
    { "trilha": "scale", "etapa_funil": "CONFIANCA",
      "tipo_estrategico": "Prova / Case / Autoridade",
      "objetivo": "Confiar",
      "quando_usar": "...", "por_que_funciona": "...", "como_adaptar": "...",
      "quality_score_editorial": 85 }

Esse script é chamado pelo workflow n8n (HTTP Execute Command node) ou rodado
manualmente. Não escreve no banco — só classifica.
"""

import json, subprocess, sys, time

TRILHA_KEYWORDS = {
    'clinic': ['clinica','clínica','consultorio','consultório','paciente','medico','médico',
               'dermatologia','estetica','estética','harmonizacao','harmonização','lifting',
               'botox','pele','tratamento','procedimento','dentista','odonto','cirurgiao','cirurgião'],
    'scale': ['mentoria','mentorada','empreendedor','ticket','agenda','vendas','oferta',
              'posicionamento','autoridade','lancamento','lançamento','conteudo','conteúdo',
              'instagram','negocio','negócio','escala','faturamento'],
}

ETAPAS = ['DESCOBERTA','CONFIANCA','ACAO']
LINHAS = [
    'Alerta de Erro, Perda ou Risco',
    'Ganho, Solução ou Caminho',
    'Contrassenso / Quebra de Crença',
    'Comparação / Contraste',
    'CIS / Identificação',
    'História / Curiosidade / Experiência',
    'Prova / Case / Autoridade',
    'Mecanismo / Método / Causa Real',
    'Análise / Decodificação',
    'Objeção / Decisão / Ação',
]
OBJETIVOS = ['Atrair','Identificar','Desejo','Confiar','Vender']

def guess_trilha(perfil, caption, transcricao):
    """Heurística de trilha baseada em keywords."""
    text = ' '.join(filter(None, [perfil, caption[:500] if caption else '', transcricao[:500] if transcricao else ''])).lower()
    scores = {k: sum(1 for kw in v if kw in text) for k, v in TRILHA_KEYWORDS.items()}
    if scores['clinic'] == 0 and scores['scale'] == 0:
        return None
    return max(scores, key=scores.get)

def quality_score(item):
    """0-100 score técnico (engajamento + conteúdo + duração)."""
    s = 0
    likes = item.get('likesCount') or 0
    views = item.get('videoViewCount') or item.get('videoPlayCount') or 0
    caption = item.get('caption') or ''
    transcricao = item.get('transcricao') or ''
    dur = item.get('videoDuration') or 0
    if likes >= 5000: s += 20
    elif likes >= 1000: s += 10
    if views >= 50000: s += 20
    elif views >= 10000: s += 10
    if len(transcricao) >= 200: s += 15
    if len(caption) >= 150: s += 10
    if item.get('verified'): s += 10
    if 30 <= dur <= 180: s += 10
    if caption.count('#') >= 5: s += 5
    return min(s, 100)

def build_prompt(item, trilha_guess):
    caption = (item.get('caption') or '')[:2000]
    transcricao = (item.get('transcricao') or '')[:3000]
    perfil = item.get('ownerUsername') or 'desconhecido'

    return f"""Você é curador editorial seguindo o método DECIDA da Queila Trizotti (Case). Classifique 1 referência de conteúdo do Instagram e produza um Guia de uso.

DADOS DA REFERÊNCIA:
- Perfil: @{perfil}
- Trilha sugerida (heurística): {trilha_guess or 'indeterminado'}
- Caption: {caption}
- Transcrição: {transcricao}

CLASSIFIQUE EM TODOS OS CAMPOS, em JSON puro (sem markdown, sem prosa):

{{
  "trilha": "clinic" OU "scale",
  "etapa_funil": "DESCOBERTA" OU "CONFIANCA" OU "ACAO",
  "tipo_estrategico": <UMA das 10 linhas oficiais: "Alerta de Erro, Perda ou Risco" | "Ganho, Solução ou Caminho" | "Contrassenso / Quebra de Crença" | "Comparação / Contraste" | "CIS / Identificação" | "História / Curiosidade / Experiência" | "Prova / Case / Autoridade" | "Mecanismo / Método / Causa Real" | "Análise / Decodificação" | "Objeção / Decisão / Ação">,
  "objetivo": "Atrair" OU "Identificar" OU "Desejo" OU "Confiar" OU "Vender",
  "quando_usar": "1-2 frases (30-180 chars) — em que momento do calendário/jornada usar",
  "por_que_funciona": "1-2 frases (40-200 chars) — mecânica editorial; cite gatilho ou padrão concreto",
  "como_adaptar": "1-2 frases (40-220 chars) — caminho prático pro cliente CASE; específico",
  "quality_score_editorial": <0-100, integer — quanto vale pro cliente CASE>
}}

REGRAS:
- DECIDA: D+E (Descoberta + Entendimento) 60% / C+I+D (Confiança + Identificação + Desejo) 30% / A (Ação) 10%
- pt-BR, tom consultivo
- Zero anglicismos (não use framework, pipeline, ICP, B2B, moat)
- Zero ROI/semanas/garantia
- Se não houver insumo suficiente, devolva quality_score_editorial <= 30
- APENAS o JSON, sem prosa antes/depois"""

def call_claude(prompt):
    proc = subprocess.run(
        ['claude','-p',prompt,'--output-format','text'],
        capture_output=True, text=True, timeout=120
    )
    return proc.stdout.strip()

def parse_json_loose(s):
    s = s.strip()
    if s.startswith('```'):
        s = s.split('```',2)[1]
        if s.startswith('json'): s = s[4:]
        s = s.strip()
    depth = 0; start = None
    for i,c in enumerate(s):
        if c == '{':
            if depth == 0: start = i
            depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0 and start is not None:
                return json.loads(s[start:i+1])
    return json.loads(s)

def classify(item):
    t0 = time.time()
    trilha_guess = guess_trilha(
        item.get('ownerUsername',''),
        item.get('caption',''),
        item.get('transcricao','')
    )
    raw = call_claude(build_prompt(item, trilha_guess))
    parsed = parse_json_loose(raw)

    # Validação dos enums — se LLM alucinou valor inválido, devolve None
    if parsed.get('etapa_funil') not in ETAPAS: parsed['etapa_funil'] = None
    if parsed.get('tipo_estrategico') not in LINHAS: parsed['tipo_estrategico'] = None
    if parsed.get('objetivo') not in OBJETIVOS: parsed['objetivo'] = None
    if parsed.get('trilha') not in ('clinic','scale'): parsed['trilha'] = trilha_guess

    # Quality_score técnico + override pelo editorial se mais alto
    q_tech = quality_score(item)
    q_ed = int(parsed.get('quality_score_editorial') or 0)
    parsed['quality_score'] = max(q_tech, q_ed)
    parsed['_meta'] = {'duration_s': round(time.time()-t0, 1),
                       'quality_tech': q_tech, 'quality_editorial': q_ed}
    return parsed

if __name__ == '__main__':
    item = json.load(sys.stdin)
    out = classify(item)
    print(json.dumps(out, ensure_ascii=False))
