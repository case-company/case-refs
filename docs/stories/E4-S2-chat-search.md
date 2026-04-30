# E4-S2 — Chat-to-search via embedding

**Epic:** EPIC-04 — AI & Mobile
**Status:** 🔵 Discovery (não implementada nesta sprint)

## Por que não foi implementada agora

Requer **3 dependências externas** que precisam decisão / config humana:

1. **pgvector no Supabase** — extensão precisa ser habilitada no projeto Case (pode ter custo dependendo do plano)
2. **API de embeddings** — OpenAI key (custo: ~$0.02 / 1M tokens; trivial mas precisa de billing config)
3. **LLM API** pro re-rank — Anthropic (Claude Haiku 4.5, ~$0.80/1M output) ou OpenAI (GPT-4o-mini, ~$0.15/1M output)

Sem essas decisões prévias, implementar a UI seria construir interface sem backend = sem valor.

## Pré-requisitos pra destravar

- [ ] Habilitar `vector` extension no Supabase Case
- [ ] Decisão: provider de embeddings (OpenAI text-embedding-3-small é default razoável)
- [ ] Decisão: LLM pro re-rank (recomendo Claude Haiku 4.5)
- [ ] Setup de proxy server-side pras keys (Cloudflare Worker, n8n, ou Vercel Function)
- [ ] Backfill embeddings (1-shot script, ~$0.01 pro banco atual)

## Custo operacional estimado

- 1000 queries/mês × ~$0.001/query = **~$1/mês**
- Backfill inicial: ~$0.01
- Ongoing embeddings de novas refs: ~$0.001/dia

## Quando implementar

Faz sentido quando:
- Banco passa de 1000+ refs (busca textual fica fraca)
- Time relata frustração com filtros estruturados
- Há dossiê / apresentação periódica que se beneficia ("me dá 3 refs de prova social pra dermato")

Pré-volume insuficiente: filtros + busca textual cobrem.

A spec completa com código (Supabase RPC, pipeline LLM, UI) fica em `docs/stories/E4-S2-chat-search.md`.
