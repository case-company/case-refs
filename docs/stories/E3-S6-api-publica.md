# E3-S6 — API pública pra outros apps Case

**Epic:** EPIC-03 — Intelligence & Integration
**Status:** 🔵 Discovery (não implementada nesta sprint — fora do escopo do repo estático)

## Por que não foi implementada agora

case-refs é hospedado como site estático no Vercel Hobby — sem suporte a Vercel Functions sem upgrade pra Pro.

Implementar API pública requer **uma de 3 opções**, todas fora do scope deste repo:

### Opção A — Cloudflare Worker (recomendado)
- Repo separado `case-refs-api`
- Deploy via `wrangler` no Cloudflare
- Free tier: 100k requests/dia
- Auth via API key (env vars)
- Rate limit via KV ou Durable Objects

### Opção B — Vercel Pro + Functions
- Mesmo repo, pasta `api/`
- Custo: $20/mês/membro

### Opção C — n8n como API gateway
- Já existe runtime
- Cria webhooks pra cada endpoint
- Menos performante mas zero infra nova

## Design proposto (já documentado)

Endpoints:
- `GET /api/v1/references` — lista paginada com filtros
- `GET /api/v1/references/:id`
- `GET /api/v1/references/search?q=...`
- `GET /api/v1/perfis`
- `GET /api/v1/coverage`

Auth: header `X-API-Key`
Rate limit: 100 req/min/IP
CORS: `*.case.com.br` + localhost

## Quando implementar

Faz sentido quando outro app Case (Spalla, dossiê pipeline, Maestro) explicitamente solicitar acesso programático ao banco. Hoje: nenhum app consome → premature optimization.

Workaround atual: outros apps podem ler direto a view pública do Supabase com a anon key (mesmo método do `/live`). Não é "API estável" mas funciona enquanto não cresce.

A story original (versão completa com schema de resposta + worker em código) fica em `docs/stories/E3-S6-api-publica.md` pronta pra execução.
