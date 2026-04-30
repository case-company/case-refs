# E2-S4 — Tag livre por card

**Epic:** EPIC-02 — Curadoria Power Tools
**Status:** 🟡 Frontend Done — aguarda backend (webhook + migration)
**Concluído front em:** 2026-04-30

## Implementação frontend (no ar)

- **Seção "Tags"** no modal de `/live` — mostra chips removíveis
- Input "+ tag" inline com normalização automática (lowercase, hyphens, sem acentos)
- Adicionar dispara `POST /webhook/case-refs-mutate` com `{ op: 'update_tags', id, tags }`
- Remover (x no chip) idem
- **Tags aparecem no card** (até 3 visíveis) abaixo da caption
- Busca textual também procura em tags (já implementado)

## Backend pendente

### Migration Supabase

```sql
ALTER TABLE referencias_conteudo ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}';
CREATE INDEX IF NOT EXISTS idx_refs_tags ON referencias_conteudo USING gin(tags);

CREATE OR REPLACE VIEW v_referencias_publicas AS
  SELECT *, tags FROM referencias_conteudo WHERE deleted_at IS NULL;
```

### n8n switch case (no mesmo webhook `/case-refs-mutate`)

```
case 'update_tags':
  UPDATE referencias_conteudo SET tags = $body.tags WHERE id = $body.id
```

## Arquivos modificados

- `live.html` — `renderTagChips()`, `addTag()`, `removeTag()`, render de chips no card, CSS `.tag-chip`

## Iteração futura

- Filtro por tag na toolbar (multi-select) — não implementado
- Autocomplete com tags já usadas — não implementado
- Bulk tag edit (selecionar N cards, taggear todos) — fica em E3
