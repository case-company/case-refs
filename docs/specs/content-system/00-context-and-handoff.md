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

**Fonte canônica do método DECIDA**: material consolidado da Queila (texto curto que descreve os 3 grupos e a regra de mix).

> **Nota retrospectiva (2026-05-12)**: a primeira versão desta seção 4 listava também os "4 agentes editoriais" do método interno da Queila (Mapa de Interesse, Download do Expert, Estrategista, Modelador) como se fossem escopo de produto. **Não eram.** O handoff Felipe Gobbi pediu banco curado + workflow editorial + onboarding cliente + planejamento fase 2 APIs — não pediu agentes. A seção foi revogada e o que tinha sido implementado em código (`/agentes/*`, tabelas `agente.mapas_interesse` etc.) foi removido. Ver commit `revert(content-system): remove agentes fora do escopo do handoff`.

---

## 4. Gap Analysis — handoff vs. estado atual

| Pedido handoff | Estado atual | Gap | Prioridade |
|---|---|---|---|
| Taxonomia DECIDA (D+E / C+I+D / A) | etapa_funil ≈ bate | Relabel + documentar regra de mix | P0 |
| Vertical (Clínica/Mentoria) | trilha (clinic/scale) ≈ bate | Renomear UX-friendly | P1 |
| Campo "quando usar" | ❌ ausente | Adicionar coluna + obrigar na promoção | P0 |
| Campo "por que funciona" | ❌ ausente | Adicionar coluna + obrigar na promoção | P0 |
| Campo "como adaptar" | ❌ ausente | Adicionar coluna + obrigar na promoção | P0 |
| Campo "objetivo" (separado de etapa) | ❌ | Adicionar (Atrair, Identificar, Desejo, Confiar, Vender) | P1 |
| Página "Como usar" cliente-facing | ❌ | Criar `/como-usar.html` | P0 |
| Workflow editorial promoção c/ campos | 🟡 parcial (promote sem campos) | Modal de promoção exigir 3 campos | P0 |
| Validação com uso real (cliente piloto) | ❌ | Roadmap de testes com Queila/cliente real | P2 |
| Roadmap automação fase 2 (RapidAPI etc.) | ❌ | Doc `fase-2-monitoramento-apis.md` | P0 |
| Subtarefa "resumir feedback / organizar pontos de melhoria" | ❌ | Mecanismo de captura de feedback do cliente | P2 |
| Migração de dados existentes do Sheets ativo da Queila | ❌ | Importar `1vwg2H_70YGygaGl1AwW-WLSG0kdqkE2T1UBNpjEXfA4` | P1 |

---

## 5. Decisões Estratégicas Tomadas

- **D1**: Adotar DECIDA como taxonomia oficial. Renomear `etapa_funil.CONFIANCA` → label "C+I+D" no front (sem migration de dados).
- **D2**: Campos "quando usar / por que funciona / como adaptar" são **obrigatórios na promoção** (gatekeeper).
- **D3**: ~~V1 inclui os 4 agentes editoriais como módulos~~ — **REVOGADA 2026-05-12**. Os 4 agentes não estavam no handoff Felipe Gobbi; foram enxertados por erro de leitura do material da Queila. Removidos via commit `revert(content-system): remove agentes fora do escopo do handoff`.
- **D4**: Docs vivem em `case-references/docs/specs/content-system/` no repo do site.
- **D5**: `refs.casein.com.br` é o produto. Notion/planilha do handoff são abandonados.

---

## 6. Mapa de Pastas do Projeto

```
case-references/
├── index.html, trilhas.html, posts.html, live.html, dashboard.html, como-usar.html
├── _auth.js, _decida.js, _tour.js
├── supabase/
│   ├── migrations/      # 20260430..20260513
│   └── functions/case-refs-mutate/
└── docs/specs/content-system/
    ├── 00-context-and-handoff.md   ← este arquivo
    ├── 01-prd.md                   ← visão de produto consolidada
    ├── 02-spec-tech.md             ← arquitetura técnica
    ├── guia-decida.md              ← guia DECIDA cliente-facing
    ├── fase-2-monitoramento-apis.md← backlog fase 2 (pedido handoff)
    ├── CHANGELOG.md
    ├── adrs/                       ← decisões arquiteturais
    │   ├── 0001-decida-taxonomy.md
    │   ├── 0002-promotion-mandatory-fields.md
    │   ├── 0004-frontend-stays-static-with-dynamic-overlay.md
    │   └── 0005-keep-n8n-pipeline-extend-not-replace.md
    ├── epics/                      ← E01, E02, E03, E08
    ├── stories/                    ← 16 stories (E01-S1..S5, E02-S1..S6, E03-S1..S4, E08-S1)
    └── test-runs/
```

---

## 7. Referências Externas Consolidadas

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
