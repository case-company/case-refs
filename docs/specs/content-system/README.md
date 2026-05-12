---
title: Content System CASE — Índice
type: index
status: active
date: 2026-05-12
owner: Kaique Rodrigues
---

# Content System CASE

**Status: V1.0.0 RELEASED — 2026-05-12.**

Documentação do projeto que assume o handoff do Felipe Gobbi e absorve a taxonomia DECIDA da Queila no `refs.casein.com.br`. Detalhes do release em [`CHANGELOG.md`](CHANGELOG.md).

## Como navegar

| Documento | Tipo | Conteúdo |
|-----------|------|----------|
| [00-context-and-handoff.md](00-context-and-handoff.md) | contexto | Handoff recebido + gap analysis + decisões estratégicas. Comece aqui. |
| [01-prd.md](01-prd.md) | PRD | Visão, problema, personas, escopo V1, métricas, roadmap, riscos. |
| [02-spec-tech.md](02-spec-tech.md) | spec técnica | Arquitetura, schema, APIs, fluxos, migrations, RLS, observabilidade. |
| [guia-decida.md](guia-decida.md) | guia cliente | O método DECIDA explicado para cliente. Versão markdown longa. |
| [fase-2-monitoramento-apis.md](fase-2-monitoramento-apis.md) | backlog | Planejamento explícito da fase 2 (automação + APIs) — pedido direto do handoff. |
| [CHANGELOG.md](CHANGELOG.md) | changelog | Histórico de releases. |

## ADRs (decisões arquiteturais)

| ID | Decisão |
|----|---------|
| [0001](adrs/0001-decida-taxonomy.md) | Adotar DECIDA como taxonomia oficial — mapeamento UX-only, sem migration |
| [0002](adrs/0002-promotion-mandatory-fields.md) | Promoção exige 3 campos editoriais (quando usar / por que funciona / como adaptar) |
| [0004](adrs/0004-frontend-stays-static-with-dynamic-overlay.md) | Frontend permanece estático com overlay dinâmico — sem SPA |
| [0005](adrs/0005-keep-n8n-pipeline-extend-not-replace.md) | Pipeline n8n existente é estendido, não substituído |

> ADR-0003 (agentes como módulos) foi **revogado** — escopo estava fora do handoff. Ver CHANGELOG seção "Removido durante o desenvolvimento".

## Epics

| ID | Prioridade | Status | Stories |
|----|-----------|--------|---------|
| [E01](epics/E01-foundations-decida.md) | P0 | **Done** | 5 |
| [E02](epics/E02-curadoria-editorial.md) | P0 | **Done** | 6 |
| [E03](epics/E03-onboarding-cliente.md) | P0 | **Done** | 4 |
| [E08](epics/E08-validacao-e-rollout.md) | P0 | **Done** | 1 |

> Epics E04-E07 (4 agentes editoriais) foram removidos — fora do escopo do handoff. Ver CHANGELOG.

## Stories

Listadas em [`stories/`](stories/). Nomenclatura: `EXX-SY-slug.md`.

## Convenções

- **Idioma**: pt-BR com acentuação completa. Nomes de sistema em en-US.
- **Frontmatter YAML** obrigatório em todo `.md`.
- **Migrações Supabase** ficam em `supabase/migrations/` na raiz do repo.
- **Antes de adicionar coluna nova** em `v_referencias_publicas` ou `v_referencias_promovidas`, conferir se ela pode ser exposta ao anon. Whitelist explícita (sem `SELECT *`).
