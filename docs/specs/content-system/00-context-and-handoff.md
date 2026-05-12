---
title: Content System CASE — Contexto e Handoff Consolidado
type: context
status: draft-v0
date: 2026-05-12
owner: Kaique Rodrigues
---

# 00 — Contexto e Handoff Consolidado

**Documento-fonte** pro PRD, ADRs, Epics e Stories do Content System CASE.
Cristaliza handoff do Felipe Gobbi + estado atual do `refs.casein.com.br` + método consolidado da Queila.

---

## 1. Por que esse documento existe

Existia um projeto paralelo "Sistema/Central de Conteúdo CASE" tocado pelo Felipe Gobbi (BU-CASE). Eles planejavam Notion → recuaram pra planilha → fizeram handoff pro Kaique consolidar. Em paralelo, o Kaique já levantou `refs.casein.com.br` que cobre uma parte significativa do escopo deles, mas com schema/taxonomia diferentes.

Este projeto agora **assume o handoff**, incorpora o método canônico da Queila (DECIDA + 4 agentes editoriais) e expande o `refs.casein.com.br` pro escopo completo.

---

## 2. Estado atual (refs.casein.com.br)

**Stack**:
- Frontend: Vercel (HTML estático + fetch dinâmico parcial)
- Backend: Supabase (Postgres + Edge Functions)
- Pipeline ingest: n8n + Apify (`apify/instagram-scraper`) + AssemblyAI (transcrição)
- Repo: github.com/case-company/case-refs

**Páginas vivas**:
- `/` (landing) — 3 cards (Trilhas, Posts Fixados, Cadastrar)
- `/trilhas` — 75 itens curados estáticos + fetch de promovidos via Supabase
- `/posts` — posts fixados + destaques
- `/live` — cadastros pelo form, badge ⏳ pendente, botão "Promover ao Banco"
- `/dashboard` — escondido da landing, ainda acessível por URL

**Schema DB** (`agente.referencias_conteudo`):
- `id BIGINT, perfil, trilha (clinic|scale), tipo_artefato, posicao, url, shortcode, formato, caption, display_url, video_url, cover_url, highlight_id, titulo, likes, comments, views, timestamp_post, transcricao, language_code, audio_duration_ms, tipo_estrategico, etapa_funil (DESCOBERTA|CONFIANCA|ACAO), notas, origem, created_at, deleted_at, tags TEXT[], promoted_at`

**View pública**: `public.v_referencias_publicas` — filtra `deleted_at IS NULL`, expõe `promoted_at`.

**Edge Function**: `case-refs-mutate` — ops `update_note`, `update_tags`, `soft_delete`, `promote`, `unpromote`.

**Fluxo atual de curadoria**:
1. Item entra via webhook n8n (Apify scraper + AssemblyAI)
2. Aparece em `/live` com badge ⏳ "pendente curadoria"
3. Curador abre modal → clica "Promover ao Banco de Trilhas"
4. Some do `/live`, aparece em `/trilhas` no fim da categoria

---

## 3. Método consolidado da Queila — DECIDA

### O que NÃO é
- DECIDA não é acrônimo letra-por-letra
- 4 pilares antigos (DESEJAR/DESCOBRIR/IDENTIFICAR/CONFIAR) foram absorvidos

### O que É
Estrutura de **objetivos editoriais** organizada em 3 blocos:

| Bloco | Significado | % do ciclo padrão |
|---|---|---|
| **D + E** | Descoberta + Entendimento | 70% |
| **C + I + D** | Confiança + Identificação + Desejo | 30% |
| **A** | Ação / Decisão | 0-10% (ramp na fase de vendas) |

**Insight**: o schema atual já tem `etapa_funil ∈ {DESCOBERTA, CONFIANCA, ACAO}` — bate com o método. Só falta:
1. Renomear/relabel `CONFIANCA` → `C+I+D` (Confiança+Identificação+Desejo)
2. Documentar a regra de mix (70/30/0-10) no guia de uso

**Fonte canônica**: `~/Downloads/copia projeto agentes/Manuais dos agentes/05_Base_Metodologica/metodologia_referencia_agentes.md` (linhas 36-77) e `STATUS_DOS_AGENTES.md` (linha 110).

---

## 4. Os 4 Agentes Editoriais da Queila

Todos prontos e validados pelo material (STATUS_DOS_AGENTES.md). Ordem de execução:

```
Agente 00 (Mapa de Interesse)
   ↓
Agente 00.5 (Download do Expert)
   ↓
Agente 01 (Estrategista de Conteúdo Editorial)
   ├→ Agente 02 (Modelador de Referências) — opcional, paralelo
   └→ Agente 03 (Roteirista) — futuro, fora do V1
```

### Agente 00 — Mapa de Interesse
- **Input**: público (quem, nível, contexto), oferta/promessa, sinais externos (YouTube, TikTok, comentários, concorrentes)
- **Output**: 12 gavetas (dores, desejos, medos, dúvidas, erros, crenças, valores, comparações, cenas, identidades, inimigos, referências) + top assuntos priorizados
- **Status**: Pronto

### Agente 00.5 — Download do Expert
- **Input**: Mapa de Interesse + perguntas cirúrgicas (opiniões, valores, provas, cases, histórias, método, frases próprias)
- **Output**: Repositório de crenças/teses/provas/histórias/storytelling/método/linguagem do expert
- **Status**: Aprovado e finalizado

### Agente 01 — Estrategista de Conteúdo Editorial
- **Input**: Mapa + Download + fase (D+E ou Vendas) + capacidade de produção + histórico
- **Output**: Plano Editorial + Banco de Ideias por linha (objetivo, linha, insumo público, insumo expert, tensão de captura, gancho)
- **Critério crítico**: TODA ideia precisa ter insumo do público E insumo do expert. Senão output é inválido.
- **Status**: Aprovado

### Agente 02 — Modelador de Referências
- **Input**: referência externa (link/vídeo/carrossel) + formato visual + ideia a encaixar
- **Output**: roteiro modelado (estrutura preservada, conteúdo adaptado)
- **Princípio**: copia ESTRUTURA, não copia CONTEÚDO
- **Status**: Aprovado pra uso inicial

---

## 5. Gap Analysis — handoff vs. estado atual

| Pedido handoff | Estado atual | Gap | Prioridade |
|---|---|---|---|
| Taxonomia DECIDA (D+E / C+I+D / A) | etapa_funil ≈ bate | Relabel + documentar regra de mix | P0 |
| Vertical (Clínica/Mentoria) | trilha (clinic/scale) ≈ bate | Renomear UX-friendly | P1 |
| Campo "quando usar" | ❌ ausente | Adicionar coluna + obrigar na promoção | P0 |
| Campo "por que funciona" | ❌ ausente | Adicionar coluna + obrigar na promoção | P0 |
| Campo "como adaptar" | ❌ ausente | Adicionar coluna + obrigar na promoção | P0 |
| Campo "objetivo" (separado de etapa) | ❌ | Adicionar (Atrair, Identificar, Desejo, Confiar, Vender) | P1 |
| Página "Como usar" cliente-facing | ❌ | Criar `/como-usar.html` | P0 |
| Agente 00 (Mapa de Interesse) | ❌ não implementado | Construir pipeline + UI | P1 |
| Agente 00.5 (Download Expert) | ❌ | Construir pipeline + UI | P1 |
| Agente 01 (Estrategista) | ❌ | Construir pipeline + UI | P2 |
| Agente 02 (Modelador) | ❌ | Construir pipeline + UI | P2 |
| Workflow editorial promoção c/ campos | 🟡 parcial (promote sem campos) | Modal de promoção exigir 3 campos | P0 |
| Validação com uso real | ❌ | Roadmap de testes com Queila/cliente | P2 |
| Roadmap automação fase 2 | parcial (já tem n8n) | Documentar próximas fontes (RapidAPI etc) | P3 |

---

## 6. Decisões Estratégicas Tomadas (validar com Kaique)

- **D1**: Adotar DECIDA como taxonomia oficial. Renomear `etapa_funil.CONFIANCA` → label "C+I+D" no front (sem migration de dados).
- **D2**: Campos "quando usar / por que funciona / como adaptar" são **obrigatórios na promoção** (gatekeeper).
- **D3**: V1 inclui os 4 agentes editoriais como módulos (Epics próprios).
- **D4**: Docs vivem em `case-references/docs/specs/content-system/` no repo do site.
- **D5**: `refs.casein.com.br` é o produto. Notion/planilha do handoff são abandonados.

---

## 7. Mapa de Pastas do Projeto

```
case-references/
├── index.html, trilhas.html, posts.html, live.html, dashboard.html
├── supabase/
│   ├── migrations/      # 20260430_, 20260512_promotion, [novos]
│   └── functions/case-refs-mutate/
└── docs/specs/content-system/
    ├── 00-context-and-handoff.md   ← este arquivo
    ├── 01-prd.md                   ← visão de produto consolidada
    ├── 02-spec-tech.md             ← arquitetura técnica
    ├── adrs/                       ← decisões arquiteturais
    │   ├── 0001-decida-taxonomy.md
    │   ├── 0002-promotion-mandatory-fields.md
    │   └── ...
    ├── epics/                      ← breakdown por epic
    │   ├── E01-foundations-decida.md
    │   ├── E02-curadoria-editorial.md
    │   ├── E03-onboarding-cliente.md
    │   ├── E04-agente-mapa-interesse.md
    │   ├── E05-agente-download-expert.md
    │   ├── E06-agente-estrategista.md
    │   ├── E07-agente-modelador.md
    │   └── E08-validacao-e-rollout.md
    └── stories/                    ← stories AIOX-format
        └── ...
```

---

## 8. Referências Externas Consolidadas

**Material Queila (canônico)**:
- `~/Downloads/copia projeto agentes/STATUS_DOS_AGENTES.md` — matriz de prontidão
- `~/Downloads/copia projeto agentes/LEIA_PRIMEIRO_ORGANIZACAO.md`
- `~/Downloads/copia projeto agentes/Manuais dos agentes/RESUMO_CONTINUIDADE_PROJETO.md`
- `~/Downloads/copia projeto agentes/Manuais dos agentes/05_Base_Metodologica/metodologia_referencia_agentes.md`
- `~/Downloads/copia projeto agentes/Manuais dos agentes/05_Base_Metodologica/fluxo_00_mapa_de_interesse.md`
- `~/Downloads/copia projeto agentes/Manuais dos agentes/05_Base_Metodologica/fluxo_02_modelador_de_referencias.md`
- `~/Downloads/copia projeto agentes/Manuais dos agentes/03_Agente_01_Estrategista_de_Conteudo_Editorial/briefing_agente_01_estrategista_editorial.md`

**Handoff Felipe (referência histórica)**:
- `/Users/felipegobbi/Documents/VibeworkV2/BU-CASE/docs/specs/content-reference-system/` (4 arquivos draft)
- ClickUp 868j7ych3 + subtarefas canceladas

**Sheets/docs Queila atualizados**:
- `https://docs.google.com/spreadsheets/d/1vwg2H_70YGygaGl1AwW-WLSG0kdqkE2T1UBNpjEXfA4/` — referências atuais
- `https://docs.google.com/document/d/1ZJdax9vQiV7Z9r1DxgnsFcwDPUeyMobBwsDHx0F3_N4/` — método

---

**Próximo passo**: 01-prd.md + adrs/0001 + epics/E01.
