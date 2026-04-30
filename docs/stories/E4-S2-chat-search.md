# E4-S2 — Chat-to-search via embedding

**Epic:** EPIC-04 — AI & Mobile
**Status:** Discovery
**Prioridade:** P3
**Estimate:** 1 semana
**Owner:** Kaique
**Dependências:** pgvector no Supabase + API embeddings + LLM

---

## User Story

Como **curador buscando exemplo específico**, quero **perguntar em linguagem natural** ("3 refs de prova social pra dermato") e receber **matches relevantes** com explicação, pra **não depender de filtros estruturados** que nem sempre cobrem o que penso.

## Contexto

Filtros atuais (trilha/etapa/tipo/tag) são estruturados. Quando o conceito que busco não bate exatamente com a categoria registrada, é frustrante. Chat com embedding vê semântica.

## Critérios de Aceite

1. **Nova página `/chat`** ou widget no header de qualquer página
2. **Input "Pergunte..."** com placeholder de exemplos:
   - "3 refs de prova social pra dermato"
   - "Refs com hook forte, etapa Descoberta"
   - "Posts onde a pessoa aparece em vídeo, trilha Mentoria"
3. **Pipeline**:
   - Embed da query (OpenAI text-embedding-3-small)
   - Cosine similarity contra embeddings das refs (top-K=10)
   - Re-rank com LLM (Claude Haiku 4.5 ou GPT-4o-mini) avaliando relevância
   - Resposta: top 3-5 refs com **justificativa LLM** ("Esta é prova social porque...")
4. **UI**:
   - Mostra cards das refs encontradas
   - Cada card com **"💡 Por que essa?"** mostrando justificativa
   - Botão "Refinar busca" pra continuar conversa
5. **Histórico de conversas** em localStorage
6. **Custo controlado**: rate limit 20 queries/dia/usuário, cache de queries idênticas (24h)

## Notas Técnicas

### Migration

```sql
CREATE EXTENSION IF NOT EXISTS vector;

ALTER TABLE referencias_conteudo ADD COLUMN embedding vector(1536);
CREATE INDEX idx_refs_embedding ON referencias_conteudo USING hnsw (embedding vector_cosine_ops);

-- RPC pra search
CREATE OR REPLACE FUNCTION search_refs(query_embedding vector, match_count int DEFAULT 10)
RETURNS TABLE (id bigint, perfil text, similarity float) AS $$
  SELECT id, perfil, 1 - (embedding <=> query_embedding) as similarity
  FROM referencias_conteudo
  WHERE deleted_at IS NULL AND embedding IS NOT NULL
  ORDER BY embedding <=> query_embedding
  LIMIT match_count;
$$ LANGUAGE SQL STABLE;
```

### Backfill embeddings

Script n8n one-shot:
```
For each ref where embedding is null:
  text = perfil + caption + transcricao + tipo + etapa
  embed = OpenAI text-embedding-3-small
  UPDATE ref set embedding = $1
```

Custo backfill 1000 refs × 500 tokens × $0.02/1M = **~$0.01** (insignificante).

### Pipeline de query

```js
async function chatSearch(query) {
  // 1. Embed
  const embedRes = await fetch('https://api.openai.com/v1/embeddings', {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${OPENAI_KEY}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ model: 'text-embedding-3-small', input: query })
  });
  const { data } = await embedRes.json();
  const queryEmbedding = data[0].embedding;
  
  // 2. Search Supabase
  const { data: matches } = await supa.rpc('search_refs', { 
    query_embedding: queryEmbedding, 
    match_count: 10 
  });
  
  // 3. Get full refs
  const ids = matches.map(m => m.id);
  const { data: refs } = await supa.from('v_referencias_publicas')
    .select('*').in('id', ids);
  
  // 4. Re-rank com LLM
  const prompt = `User asked: "${query}"\n\nRank these refs by relevance and explain why:\n${refs.map((r, i) => `${i+1}. @${r.perfil} - ${r.tipo_estrategico} - ${(r.caption||'').slice(0,200)}`).join('\n')}\n\nReturn JSON: { ranked: [{ id, score, why }] }`;
  
  const llmRes = await fetch('/api/chat', { 
    method: 'POST', 
    body: JSON.stringify({ prompt, model: 'claude-haiku-4-5' }) 
  });
  const ranked = await llmRes.json();
  
  return ranked.ranked.slice(0, 5).map(r => ({
    ref: refs.find(x => x.id === r.id),
    why: r.why
  }));
}
```

### Custo por query

- Embedding: ~$0.00003
- LLM re-rank: ~$0.001 (Claude Haiku 4.5)
- **Total: ~$0.001/query**
- 1000 queries/mês = $1/mês

### Webhook proxy pro LLM (sem expor keys)

Worker Cloudflare ou n8n endpoint:
```
POST /api/chat
Body: { prompt, model }
→ chama Anthropic/OpenAI com server-side key
→ retorna resposta
```

## Definition of Done

- [ ] pgvector ativo
- [ ] Coluna embedding + índice HNSW
- [ ] Backfill de 1000+ refs feito
- [ ] RPC `search_refs` retorna top-K
- [ ] Página /chat funcional
- [ ] Re-rank LLM mostra justificativa
- [ ] Rate limit 20/dia
- [ ] Cache de queries (24h TTL)
- [ ] Histórico em localStorage
- [ ] Custo medido < $5/mês

## Edge cases

- **Embedding falha**: fallback pra busca textual (full-text search Supabase)
- **LLM rate limit**: degrada pra só similarity (sem re-rank)
- **Refs novas sem embedding**: cron periódico backfilla

## Não cobre

- Conversa multi-turn (cada query é independente)
- Geração de novas refs (só busca/recomendação)
- Personalização ("baseado nas que vc curtiu antes")
