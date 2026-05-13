# n8n manual setup — pipeline retroalimentação

> Construir nó-a-nó no editor é mais confiável que import JSON da minha mão.
> Cada nó é simples — só copia-cola os 3 campos: tipo, URL/code, body.

## Env vars antes (Settings → Variables)

```
APIFY_TOKEN=<sua chave Apify — pega no app.apify.com/settings/integrations>
OPENROUTER_API_KEY=<sua chave openrouter.ai/keys>
```

Postgres (Supabase) você já tem credencial salva no n8n — usar nó nativo **Postgres** nos nós 2 e 11.

---

## Nó 1 — Schedule Trigger

- Tipo: **Schedule Trigger**
- Trigger Rule: **Cron Expression** → `0 6 * * 0`
- (domingo 06:00)

---

## Nó 2 — Postgres (seed top players)

- Tipo: **Postgres**
- Credential: a do Supabase Case já cadastrada
- Operation: **Execute Query**
- Query:
  ```sql
  SELECT perfil, refs_count, max_score, trilha
    FROM public.case_refs_top_players_seed(30, 60);
  ```

---

## Nó 3 — Code (monta input Apify)

- Tipo: **Code** (JavaScript)
- Mode: **Run Once for All Items**
- Code:
```javascript
const rows = $input.all().map(n => n.json);
const urls = rows.map(r => `https://www.instagram.com/${r.perfil}/`);
return [{ json: { directUrls: urls, resultsType: 'posts', resultsLimit: 10, addParentData: false } }];
```

---

## Nó 4 — HTTP Request (Apify scraper)

- Method: `POST`
- URL: `=https://api.apify.com/v2/acts/apify~instagram-scraper/run-sync-get-dataset-items?token={{$env.APIFY_TOKEN}}&timeout=600`
- Send Body: **ON**
- Body Content Type: **JSON**
- Specify Body: **Using JSON**
- JSON: `={{ JSON.stringify($json) }}`
- Options → Response → Response Format: **JSON**
- Options → Timeout: `600000`

---

## Nó 5 — Code (filtro bruto)

- Tipo: **Code**
- Code:
```javascript
const items = $input.first().json;
const KEYWORDS_CLINIC = ['clinica','clínica','consultorio','consultório','paciente','medico','médico','dermatologia','estetica','estética','harmonizacao','harmonização','lifting','botox','pele','tratamento','procedimento','dentista','odonto','cirurgiao','cirurgião'];
const KEYWORDS_SCALE  = ['mentoria','mentorada','empreendedor','ticket','agenda','vendas','oferta','posicionamento','autoridade','lancamento','lançamento','conteudo','conteúdo','instagram','negocio','negócio','escala','faturamento'];
const now = Date.now();
const ANO_MS = 365*24*60*60*1000;

const survivors = [];
for (const it of items) {
  if (!it.shortCode) continue;
  const ts = it.timestamp ? Date.parse(it.timestamp) : null;
  if (ts && (now - ts) > ANO_MS) continue;
  const likes = it.likesCount || 0;
  const views = it.videoViewCount || it.videoPlayCount || 0;
  if (likes < 500 && views < 10000) continue;
  const text = ((it.ownerUsername||'') + ' ' + (it.caption||'').slice(0,500)).toLowerCase();
  const clinic = KEYWORDS_CLINIC.some(k => text.includes(k));
  const scale  = KEYWORDS_SCALE.some(k => text.includes(k));
  if (!clinic && !scale) continue;
  survivors.push(it);
}
return survivors.map(s => ({ json: s }));
```

---

## Nó 6 — HTTP Request (Whisper)

- Method: `POST`
- URL: `http://172.18.0.1:9999/transcribe`
- Send Body: **ON**
- Body Content Type: **JSON**
- Specify Body: **Using JSON**
- JSON:
```json
{
  "url": "={{ $json.videoUrl || $json.audioUrl }}",
  "language": "pt",
  "model": "small"
}
```
- Options → Timeout: `300000`
- Options → Response → Never Error: **ON**

---

## Nó 7 — Code (merge Apify + Whisper)

- Tipo: **Code**
- Code:
```javascript
const all = $input.all();
return all.map(n => {
  const apifyItem = n.json.item || n.json;
  const trans = n.json.text || '';
  return { json: { ...apifyItem, transcricao: trans } };
});
```

---

## Nó 8 — HTTP Request (Classificador OpenRouter)

- Method: `POST`
- URL: `https://openrouter.ai/api/v1/chat/completions`
- Send Headers: **ON**
  - `Authorization` = `=Bearer {{$env.OPENROUTER_API_KEY}}`
  - `Content-Type` = `application/json`
  - `HTTP-Referer` = `https://refs.casein.com.br`
  - `X-Title` = `case-refs pipeline`
- Send Body: **ON**
- Body Content Type: **JSON**
- Specify Body: **Using JSON**
- JSON (cola exato — tem expression `={{ ... }}` no início):
```
={{ JSON.stringify({
  model: 'anthropic/claude-sonnet-4-6',
  max_tokens: 800,
  response_format: { type: 'json_object' },
  messages: [
    { role: 'system', content: 'Voce e curador editorial seguindo o metodo DECIDA da Queila Trizotti (Case). Classifica 1 referencia de conteudo do Instagram. Responde APENAS JSON puro, sem markdown, sem prosa.' },
    { role: 'user', content:
      'DADOS:\nPerfil: @' + ($json.ownerUsername || 'desconhecido') +
      '\nCaption: ' + (($json.caption||'').substring(0,2000)) +
      '\nTranscricao: ' + (($json.transcricao||'').substring(0,3000)) +
      '\nLikes: ' + ($json.likesCount||0) + ' / Views: ' + ($json.videoViewCount||$json.videoPlayCount||0) +
      '\nDuracao: ' + ($json.videoDuration||0) + 's' +
      '\n\nDevolva JSON com EXATAMENTE estes campos:\n' +
      '{\n  "trilha": "clinic" OU "scale",\n  "etapa_funil": "DESCOBERTA" OU "CONFIANCA" OU "ACAO",\n' +
      '  "tipo_estrategico": UMA das 10 linhas oficiais,\n' +
      '  "objetivo": "Atrair"|"Identificar"|"Desejo"|"Confiar"|"Vender",\n' +
      '  "quando_usar": frase 30-180 chars,\n  "por_que_funciona": frase 40-200 chars,\n' +
      '  "como_adaptar": frase 40-220 chars,\n  "quality_score": 0-100 inteiro\n}\n' +
      '\n10 linhas oficiais: "Alerta de Erro, Perda ou Risco" | "Ganho, Solucao ou Caminho" | ' +
      '"Contrassenso / Quebra de Crenca" | "Comparacao / Contraste" | "CIS / Identificacao" | ' +
      '"Historia / Curiosidade / Experiencia" | "Prova / Case / Autoridade" | ' +
      '"Mecanismo / Metodo / Causa Real" | "Analise / Decodificacao" | "Objecao / Decisao / Acao"' +
      '\n\nREGRAS:\n- DECIDA mix 60% D+E / 30% C+I+D / 10% A\n- pt-BR tom consultivo\n' +
      '- Zero anglicismos (sem framework/pipeline/ICP/B2B)\n- Zero ROI/semanas/garantia'
    }
  ]
}) }}
```
- Options → Timeout: `60000`

---

## Nó 9 — Code (parse classificação)

- Tipo: **Code**
- Code:
```javascript
const original = $('Merge Apify+Whisper').item.json;
const resp = $input.first().json;
const raw = resp.choices?.[0]?.message?.content || '';
let cls = {};
try {
  let s = raw.trim();
  if (s.startsWith('```')) {
    s = s.split('```')[1];
    if (s.startsWith('json')) s = s.slice(4);
  }
  const m = s.match(/\{[\s\S]*\}/);
  if (m) cls = JSON.parse(m[0]);
} catch (e) {
  console.error('parse classificacao failed:', e.message, raw.slice(0,200));
}
return [{ json: { ...original, ...cls } }];
```

---

## Nó 10 — Code (monta payload inbox)

- Tipo: **Code**
- Code:
```javascript
const items = $input.all().map(n => {
  const it = n.json;
  return {
    shortcode: it.shortCode,
    url: `https://www.instagram.com/p/${it.shortCode}/`,
    perfil: it.ownerUsername,
    tipo_artefato: it.type === 'Video' ? 'reel' : 'publicacao_avulsa',
    plataforma: 'instagram',
    caption: it.caption,
    display_url: it.displayUrl,
    video_url: it.videoUrl,
    cover_url: it.displayUrl,
    likes: it.likesCount,
    comments: it.commentsCount,
    views: it.videoViewCount || it.videoPlayCount,
    timestamp_post: it.timestamp,
    transcricao: it.transcricao,
    language_code: 'pt',
    audio_duration_ms: (it.videoDuration || 0) * 1000,
    trilha: it.trilha,
    etapa_funil: it.etapa_funil,
    tipo_estrategico: it.tipo_estrategico,
    objetivo: it.objetivo,
    quando_usar: it.quando_usar,
    por_que_funciona: it.por_que_funciona,
    como_adaptar: it.como_adaptar,
    quality_score: it.quality_score,
    origem: 'pipeline_semanal',
    top_player_perfil: it.ownerUsername,
  };
});
return [{ json: { p_items: items } }];
```

---

## Nó 11 — Postgres (chama case_refs_inbox_submit)

- Tipo: **Postgres**
- Credential: a mesma do Supabase Case
- Operation: **Execute Query**
- Query (parameterizada — n8n substitui `$1` pelo Query Parameters):
  ```sql
  SELECT inserted_count, rejected_count, rejected_reasons
    FROM public.case_refs_inbox_submit($1::jsonb);
  ```
- Query Parameters: `={{ JSON.stringify($json.p_items) }}`

---

## Nó 12 — Code (log final)

- Tipo: **Code**
- Code:
```javascript
const r = $input.first().json;
// Postgres node devolve direto a row (não array como REST)
return [{ json: {
  inserted: r.inserted_count || 0,
  rejected: r.rejected_count || 0,
  rejected_reasons: r.rejected_reasons || [],
  ran_at: new Date().toISOString()
}}];
```

---

## Conexões (ordem linear)

```
Schedule → Seed → Monta Apify → Apify scraper → Filtro bruto
  → Whisper → Merge Apify+Whisper → Classificador OR → Parse cls
  → Monta payload → POST inbox_submit → Log final
```

Cada nó conecta com o anterior pelo output → input.

---

## Como testar incremental

1. **Cria só os nós 1-2** (Schedule + Seed). Executa nó 2 manual. Confere se volta lista de perfis.
2. Adiciona **3-4** (Monta input + Apify). Executa 4. Confere se volta lista de posts.
3. Adiciona **5** (Filtro). Confere quantos sobrevivem.
4. Adiciona **6** (Whisper). Executa em 1 item só (limite o filtro). Confere texto.
5. Adiciona **7-8-9** (Merge + Classificador + Parse). Confere JSON classificado.
6. Adiciona **10-11-12**. Executa fim-a-fim.

Cada nó testado isolado → você sabe exatamente onde quebrar quando algo der erro.
