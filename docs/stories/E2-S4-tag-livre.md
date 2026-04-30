# E2-S4 — Tag livre por card

**Epic:** EPIC-02 — Curadoria Power Tools
**Status:** Ready
**Prioridade:** P1
**Estimate:** 4h
**Owner:** Kaique
**Dependências:** Migration Supabase (coluna `tags` jsonb) + endpoint n8n update

---

## User Story

Como **curador**, quero adicionar **tags humanas** (livre) em refs além das classificações automáticas, pra **organizar do meu jeito** (ex: "favorito Queila", "candidato dossiê Elina", "exemplo de hook forte").

## Contexto

Hoje: classificação é automática (etapa do funil, tipo estratégico). Curador não tem dimensão pessoal/contextual ("usei essa pra mostrar pra X mentorada", "favorita do mês").

## Critérios de Aceite

1. **Migration Supabase**: coluna `tags TEXT[] DEFAULT '{}'`
2. **No modal de detalhes**, seção **"Tags"** mostra tags atuais como chips removíveis
3. **Input "+ Adicionar tag"** com autocomplete das tags já usadas no banco
4. **Salvar tag**: chama webhook `/update-tags` com `{ id, tags: [...] }`
5. **Remover tag**: clica no "✕" do chip
6. **Filtro por tag**: novo select "Tag" na toolbar (multi-select)
7. **Sugestões automáticas**: 5 tags mais usadas aparecem no input ao focar

## Notas Técnicas

### Migration

```sql
ALTER TABLE referencias_conteudo ADD COLUMN tags TEXT[] DEFAULT '{}';
CREATE INDEX idx_refs_tags ON referencias_conteudo USING gin(tags);

-- View pública atualizada (selecionar tags)
CREATE OR REPLACE VIEW v_referencias_publicas AS
  SELECT *, tags FROM referencias_conteudo WHERE deleted_at IS NULL;
```

### Endpoint n8n

- Path: `/webhook/case-refs-update`
- Body: `{ op: 'update_tags', id, tags: ['favorito', 'dossie-elina'] }`
- SQL: `UPDATE referencias_conteudo SET tags = $1 WHERE id = $2`

### Front

```js
async function addTag(refId, tag) {
  tag = tag.trim().toLowerCase().replace(/[^a-z0-9_-]/g, '-');
  if (!tag) return;
  const ref = DATA.find(r => r.id === refId);
  const newTags = [...new Set([...(ref.tags || []), tag])];
  await fetch(WEBHOOK_UPDATE, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ op: 'update_tags', id: refId, tags: newTags })
  });
  ref.tags = newTags;
  renderTags(refId);
  showToast('Tag adicionada ✓');
}

function tagSuggestions(prefix) {
  const allTags = new Set();
  DATA.forEach(r => (r.tags || []).forEach(t => allTags.add(t)));
  return [...allTags]
    .filter(t => t.startsWith(prefix.toLowerCase()))
    .sort()
    .slice(0, 8);
}
```

## Definition of Done

- [ ] Migration aplicada
- [ ] Endpoint n8n criado e testado
- [ ] Tags visíveis no modal como chips
- [ ] Adicionar/remover tag funciona end-to-end
- [ ] Autocomplete sugere tags existentes
- [ ] Filtro por tag na toolbar funciona
- [ ] Documentação README com convenções de naming (lowercase-hyphen)

## Convenções de naming

- Lowercase, hyphens (`favorito-queila`, `dossie-elina`, `hook-forte`)
- Sem acentos (já normalizado pelo regex)
- Sem espaços (vira hyphen)

## Não cobre

- Cores customizadas por tag (todas mesmo estilo)
- Bulk tag edit (selecionar 10 cards e taggear todos) — fica em E3
- Tag hierárquica (`marketing > prova-social`) — flat tags
