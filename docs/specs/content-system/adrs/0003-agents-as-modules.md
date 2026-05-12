---
title: ADR-0003 — Cada agente editorial é módulo independente (tabela própria + UI dedicada)
status: accepted
date: 2026-05-12
deciders: [Kaique, Queila]
supersedes: null
related:
  - 02-spec-tech.md#1.2
  - 02-spec-tech.md#2.2
  - 02-spec-tech.md#2.3
  - 02-spec-tech.md#2.4
  - 02-spec-tech.md#2.5
  - 00-context-and-handoff.md#4
---

# ADR-0003 — Agentes editoriais como módulos independentes

## Context

A Queila tem 4 agentes editoriais consolidados e validados (`STATUS_DOS_AGENTES.md`):

- **Agente 00** — Mapa de Interesse (12 gavetas: dores, desejos, medos, etc.)
- **Agente 00.5** — Download do Expert (crenças, teses, provas, histórias, método, linguagem)
- **Agente 01** — Estrategista de Conteúdo Editorial (plano + banco de ideias por linha)
- **Agente 02** — Modelador de Referências (preserva estrutura, adapta conteúdo)

Eles têm uma **ordem de execução natural** (00 → 00.5 → 01 → 02), mas cada um produz output **autocontido** que tem valor independente. O briefing Queila explicitamente trata cada um como artefato separado.

Decisão arquitetural: **como representar isso no schema?**

Opções no espectro:
- **Extremo A**: tudo vira coluna em `referencias_conteudo` (uma única tabela "wide").
- **Extremo B**: cada agente tem tabela própria, Edge Function própria, UI própria. Zero coupling.
- **Meio**: tabela `agente_outputs` polimórfica com `tipo + payload jsonb`.

## Decision

**Cada agente é um módulo independente: tabela própria, Edge Function própria, página HTML própria. Sem foreign keys obrigatórias entre agentes.**

Concretamente:

| Agente   | Tabela                         | Edge Function                  | UI                                    |
|----------|--------------------------------|--------------------------------|---------------------------------------|
| 00       | `agente.mapas_interesse`       | `case-agente-mapa`             | `/agentes/mapa-interesse.html`        |
| 00.5     | `agente.downloads_expert`      | `case-agente-download`         | `/agentes/download-expert.html`       |
| 01       | `agente.planos_editoriais`     | `case-agente-estrategista`     | `/agentes/plano-editorial.html`       |
| 02       | `agente.roteiros_modelados`    | `case-agente-modelador`        | `/agentes/modelador.html`             |

**Foreign keys são opcionais (`ON DELETE SET NULL`)**:
- `downloads_expert.mapa_id` pode ser NULL → posso fazer Download sem ter Mapa.
- `planos_editoriais.mapa_id`, `.download_id` podem ser NULL → idem.
- `roteiros_modelados.referencia_id` ou `.referencia_url` (XOR via CHECK) → modelador funciona com URL solta.

Cada agente:
- Tem `cliente_slug TEXT` próprio (não normaliza pra tabela `clientes` em V1).
- Tem `versao INT` (UNIQUE com cliente_slug) pra reprocessar sem perder histórico.
- Tem `status ∈ {draft, aprovado, arquivado}`.
- Tem campos de provenance (`modelo_llm, prompt_versao, custo_usd, duracao_ms`).
- Tem `soft_delete` via `deleted_at`.

## Consequences

### Positivas

- **Zero coupling — desenvolvimento paralelo**: pode-se construir Agente 02 sem o Agente 00 estar pronto. Crítico, porque a Queila quer começar usando o Modelador (mais simples) antes do Mapa (mais conceitual).
- **Failure isolation**: bug no Agente 01 não derruba o Agente 02. Edge Functions são processos independentes.
- **Cost isolation**: rate limit + custo cap por agente, não por sistema.
- **Schema clean**: `referencias_conteudo` continua sendo o que sempre foi (catálogo de prints/posts), sem virar god-table.
- **Schema evolution local**: adicionar campo no Agente 00 não toca nas outras tabelas.
- **Versioning natural**: `(cliente_slug, versao)` permite reprocessar Mapa V2 sem deletar V1. Histórico completo.
- **UI mental model 1:1**: cada página = um agente. Fácil pra Queila e Kaique navegarem.

### Negativas / Trade-offs

- **Mais código boilerplate**: 4 Edge Fns vs 1 polimórfica. ~600 linhas extras de código.
  - Mitigação: helper compartilhado em `_shared/agent-helpers.ts` (chamada LLM, polling, custo).
- **Joins editoriais ficam no app, não no DB**: pra mostrar "todos os roteiros dessa mentorada", o front faz 4 queries (1 por tabela) ao invés de 1 join. Aceitável dado volume baixo (<100 artefatos/cliente esperado em 1 ano).
- **Sem schema unificado pra "todos os outputs do cliente X"**: relatórios cross-agente precisam UNION ALL. Aceito — view utilitária pode ser criada depois.
- **Drift de convenção**: cada agente pode evoluir pra ter campos diferentes de provenance. Mitigação: linter de schema (CI script) que valida 4 campos provenance comuns.

### Neutras

- `cliente_slug` denormalizado em 4 tabelas. Aceito porque tabela `clientes` ainda não existe e criar agora seria YAGNI.

## Alternatives Considered

### Alt A — Coluna em `referencias_conteudo`
- Adicionar `mapa_interesse_id`, `download_expert_id`, etc. na tabela master.
- **Por que rejeitada**: confunde dois conceitos diferentes (referência externa vs artefato gerado). Tabela vira god-table com colunas mais NULL que preenchidas. Quebra ortogonalidade.

### Alt B — Tabela polimórfica `agente_outputs(id, tipo, cliente_slug, payload jsonb)`
- Uma tabela só, `tipo ∈ {mapa, download, plano, roteiro}`, payload em JSONB.
- **Por que rejeitada**:
  - Perde validação de schema por tipo (todos os campos viram JSONB livre).
  - Indexar por campo dentro de JSONB é mais lento e exige expression indexes.
  - Constraints específicas (ex: `roteiros` exige referencia_id XOR url) viram CHECK em JSONB — frágil.
  - "Vantagem" da uniformidade não compensa: as 4 tabelas têm shapes muito diferentes.

### Alt C — Microservices reais (cada agente = Cloud Run / VPS dedicada)
- Edge Function própria não é o suficiente; cada agente vira processo separado com DB próprio.
- **Por que rejeitada**: overkill brutal pra escala atual (Queila + 1-3 mentoradas piloto). Edge Functions já dão isolamento suficiente. Custo de orquestração não vale.

### Alt D — Tudo numa só Edge Function `case-agente` com `op` discriminando
- Não criar 4 Edge Fns; só uma.
- **Por que rejeitada**:
  - Bundle grande → cold start lento.
  - Deploy de patch num agente força redeploy dos outros.
  - Perde quota/rate limit isolado por endpoint.

## Implementation Hooks

- Migrations 3, 4, 5, 6 da spec (§5).
- Edge Functions: `case-agente-mapa`, `case-agente-download`, `case-agente-modelador` em V1; `case-agente-estrategista` em V1.5.
- Helper compartilhado: `supabase/functions/_shared/agent-helpers.ts` (criar com primeiro agente).
- Frontend: subdir `/agentes/` com 4 HTMLs + componentes em `/_components/agent-*.js`.

## Related ADRs

- ADR-0004 (frontend estático) — cada UI de agente segue o mesmo padrão HTML+JS vanilla.
- ADR-0005 (n8n preserved) — agentes podem disparar workflows n8n pra processamento longo.
