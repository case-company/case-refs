---
title: Content System CASE — Índice
type: index
status: active
date: 2026-05-12
owner: Kaique Rodrigues
---

# Content System CASE

Documentação consolidada do projeto que assume o handoff do Felipe Gobbi e absorve o método DECIDA da Queila no `refs.casein.com.br`.

## Como navegar

| Documento | Tipo | Conteúdo |
|-----------|------|----------|
| [00-context-and-handoff.md](00-context-and-handoff.md) | contexto | Handoff recebido + gap analysis + decisões estratégicas. Comece aqui. |
| [01-prd.md](01-prd.md) | PRD | Visão, problema, personas, escopo V1, métricas, roadmap, riscos. |
| [02-spec-tech.md](02-spec-tech.md) | spec técnica | Arquitetura, schema, APIs, sequence diagrams, migrations, RLS, observabilidade. |
| [guia-decida.md](guia-decida.md) | guia cliente | O método DECIDA explicado para cliente. Versão curta do método. |

## ADRs (decisões arquiteturais)

| ID | Decisão |
|----|---------|
| [0001](adrs/0001-decida-taxonomy.md) | Adotar DECIDA como taxonomia oficial — mapeamento UX-only, sem migration |
| [0002](adrs/0002-promotion-mandatory-fields.md) | Promoção exige 3 campos editoriais (quando usar / por que funciona / como adaptar) |
| [0003](adrs/0003-agents-as-modules.md) | Cada agente editorial vive como módulo independente |
| [0004](adrs/0004-frontend-stays-static-with-dynamic-overlay.md) | Frontend permanece estático com overlay dinâmico — sem SPA |
| [0005](adrs/0005-keep-n8n-pipeline-extend-not-replace.md) | Pipeline n8n existente é estendido, não substituído |

## Epics

| ID | Prioridade | Status | Stories |
|----|-----------|--------|---------|
| [E01](epics/E01-foundations-decida.md) | P0 | em implementação | 5 |
| [E02](epics/E02-curadoria-editorial.md) | P0 | not-started | 6 |
| [E03](epics/E03-onboarding-cliente.md) | P0 | not-started | 4 |
| [E04](epics/E04-agente-mapa-interesse.md) | P1 | code-complete | 1 |
| [E05](epics/E05-agente-download-expert.md) | P1 | code-complete | 1 |
| [E06](epics/E06-agente-estrategista.md) | P1 | code-complete | 1 |
| [E07](epics/E07-agente-modelador.md) | P2 | code-complete | 1 |
| [E08](epics/E08-validacao-e-rollout.md) | P0 | in-progress | 1 |

## Stories

Listadas em [`stories/`](stories/). Nomenclatura: `EXX-SY-slug.md`.

## Convenções

- **Idioma**: pt-BR com acentuação completa. Nomes de sistema em en-US.
- **Frontmatter YAML** obrigatório em todo `.md`.
- **Migrações Supabase** ficam em `supabase/migrations/` na raiz do repo (não aqui).
- **Antes de adicionar coluna nova** em `v_referencias_publicas` ou `v_referencias_promovidas`, conferir se ela pode ser exposta ao anon. Whitelist explícita (sem `SELECT *`).
