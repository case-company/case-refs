# E3-S6 — API pública pra outros apps Case

**Epic:** EPIC-03 — Intelligence & Integration
**Status:** Ready
**Prioridade:** P2
**Estimate:** 1.5 dia
**Owner:** Kaique
**Dependências:** Decisão sobre auth (anon vs. tokens)

---

## User Story

Como **dev de outros apps Case** (Spalla, dossiê pipeline, Maestro), quero **consultar referências via REST** sem duplicar dados ou copiar lógica, pra **reusar** o banco em qualquer contexto.

## Contexto

Hoje: cada app que precisa de ref copia/cola URLs ou consulta direto Supabase. Sem contrato estável → quebra quando schema muda.

## Critérios de Aceite

1. **Endpoint base**: `https://refs.case.com.br/api/v1/`
2. **Endpoints**:
   - `GET /references` — lista paginada com filtros
   - `GET /references/:id` — uma ref completa
   - `GET /references/search?q=...` — busca textual
   - `GET /perfis` — lista de perfis cadastrados
   - `GET /coverage` — heatmap de cobertura
3. **Filtros (query params)**: `trilha`, `etapa`, `tipo`, `tag`, `mentorada_id`, `created_after`, `created_before`, `limit`, `offset`
4. **Response format**: JSON estável com versioning
5. **Auth**: API key via header `X-API-Key` (whitelist em env)
6. **Rate limit**: 100 req/min por IP/key
7. **CORS**: liberado pra `*.case.com.br` e localhost
8. **Documentação**: README + OpenAPI spec em `/api/v1/openapi.json`
9. **Versionamento**: breaking changes vão pra `/api/v2/`

## Notas Técnicas

### Stack

Como case-refs é estático, **não dá** pra ter API serverless via Vercel Functions sem subir o plano.

**Opção A (recomendada):** Cloudflare Worker como proxy pra Supabase
- Worker roteia + valida API key + rate limit
- Backend = Supabase REST direto
- Free tier: 100k req/dia

**Opção B:** Vercel Functions (Pro plan necessário)
- `api/v1/references.ts` etc
- Mesmo runtime do Vercel

**Opção C:** n8n como API gateway
- Já existe, só add endpoints
- Menos performático mas zero novo runtime

### Schema de resposta

```json
{
  "data": [
    {
      "id": 123,
      "perfil": "clinicavolpe",
      "trilha": "clinic",
      "tipo_artefato": "post_fixado",
      "tipo_estrategico": "Prova Social",
      "etapa_funil": "CONFIANCA",
      "shortcode": "ABC123",
      "url": "https://www.instagram.com/p/ABC123/",
      "thumb_url": "https://refs.case.com.br/thumbs/...",
      "caption": "...",
      "transcricao": "...",
      "tags": ["favorito", "dossie-elina"],
      "mentoradas_vinculadas": [42, 17],
      "created_at": "2026-04-30T12:34:56Z",
      "vinculos_count": 2,
      "language_code": "pt"
    }
  ],
  "pagination": {
    "total": 1247,
    "limit": 20,
    "offset": 0,
    "next": "/api/v1/references?offset=20"
  },
  "meta": {
    "version": "1.0",
    "generated_at": "2026-04-30T12:35:00Z"
  }
}
```

### Worker (Cloudflare)

```js
export default {
  async fetch(req, env) {
    const url = new URL(req.url);
    
    // Auth
    const key = req.headers.get('X-API-Key');
    if (!env.API_KEYS_ALLOWED.split(',').includes(key)) {
      return new Response('Unauthorized', { status: 401 });
    }
    
    // Rate limit (via Durable Object ou KV)
    if (await isRateLimited(req, env)) {
      return new Response('Rate limit', { status: 429 });
    }
    
    // Route
    if (url.pathname === '/api/v1/references') {
      return await listReferences(url.searchParams, env);
    }
    // ... outros endpoints
    
    return new Response('Not found', { status: 404 });
  }
};

async function listReferences(params, env) {
  const supaUrl = new URL(`${env.SUPABASE_URL}/rest/v1/v_referencias_publicas`);
  // Map query params pro PostgREST
  if (params.get('trilha')) supaUrl.searchParams.set('trilha', `eq.${params.get('trilha')}`);
  if (params.get('etapa')) supaUrl.searchParams.set('etapa_funil', `eq.${params.get('etapa')}`);
  // ... etc
  supaUrl.searchParams.set('limit', params.get('limit') || '20');
  supaUrl.searchParams.set('offset', params.get('offset') || '0');
  
  const r = await fetch(supaUrl, {
    headers: {
      'apikey': env.SUPABASE_ANON,
      'Authorization': `Bearer ${env.SUPABASE_ANON}`,
      'Prefer': 'count=exact'
    }
  });
  const data = await r.json();
  const total = parseInt(r.headers.get('content-range')?.split('/')[1] || 0);
  
  return new Response(JSON.stringify({
    data,
    pagination: { total, limit: parseInt(params.get('limit')||20), offset: parseInt(params.get('offset')||0) },
    meta: { version: '1.0', generated_at: new Date().toISOString() }
  }), { headers: { 'Content-Type': 'application/json' } });
}
```

### OpenAPI

Gerar spec automático em `/api/v1/openapi.json` (manual ou via codegen).

## Definition of Done

- [ ] Worker deployado em Cloudflare
- [ ] DNS `api.refs.case.com.br` ou `refs.case.com.br/api/`
- [ ] Auth via API key funcionando
- [ ] Rate limit testado (forçar 101 reqs em 1min)
- [ ] CORS configurado
- [ ] OpenAPI spec acessível
- [ ] README com exemplos curl
- [ ] Spalla / dossiê pipeline conseguem consumir

## Não cobre

- Webhooks pra "notificar quando ref nova" — fica em E3-S5 e separado
- GraphQL (REST suficiente)
- Mutations via API (só leitura na v1)

## Versionamento

- `v1` é o contrato congelado
- Breaking changes vão pra `v2` em path separado
- v1 mantém suporte mínimo 1 ano após v2
