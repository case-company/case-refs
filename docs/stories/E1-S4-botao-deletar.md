# E1-S4 — Botão deletar referência com confirm

**Epic:** EPIC-01 — Quick Wins
**Status:** 🟡 Frontend Done — aguarda backend (webhook n8n + migration)
**Prioridade:** P0
**Estimate:** 1.5h (front) + 30min (backend, compartilhado com E1-S3)
**Owner:** Kaique
**Concluído front em:** 2026-04-30

---

## User Story

Como **curador**, quero **remover** uma referência cadastrada errada (URL inválida, duplicada, fora do escopo), pra **manter o banco limpo** sem precisar abrir Supabase.

## Estado atual

### ✅ Frontend (deployado em produção)

Em `/live`, ao abrir modal de qualquer card:

- Botão **"🗑️ Excluir referência"** no rodapé do modal (estilo `btn-danger`, vermelho)
- Clicar dispara **confirm dialog nativo**:
  - "Excluir referência de @{perfil}?"
  - Mostra preview da caption (80 chars)
  - "Essa ação não pode ser desfeita pela interface."
- Confirmar chama `POST /webhook/case-refs-mutate`
  - Body: `{ op: 'soft_delete', id: <ref_id> }`
- Em sucesso: card some da lista (otimista), modal fecha, toast "Excluído ✓"
- Em erro: toast "Erro: HTTP {status}", card permanece

### ⏳ Backend (pendente — compartilhado com E1-S3)

Mesma migration + webhook descritos em E1-S3. **Nota:** soft-delete via `deleted_at` permite restauração via Supabase Studio se erro.

```sql
ALTER TABLE referencias_conteudo ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

CREATE OR REPLACE VIEW v_referencias_publicas AS
  SELECT * FROM referencias_conteudo WHERE deleted_at IS NULL;
```

n8n switch case:
```
case 'soft_delete':
  UPDATE referencias_conteudo SET deleted_at = now() WHERE id = $body.id
  Return { ok: true, id }
```

## Critérios de Aceite

1. ✅ Botão "Excluir" presente no modal de `/live`
2. ✅ Confirm dialog mostra contexto (perfil + caption)
3. ✅ Card removido otimisticamente da UI
4. ⏳ Soft-delete persiste no Supabase **(depende do webhook)**
5. ⏳ View pública filtra deletadas **(depende da migration)**
6. ✅ Erro de rede mostra toast claro

## Como destravar

Mesmas 4 etapas da E1-S3 (compartilham webhook + migration).

## Não cobrimos

- Botão "Restaurar" pra desfazer delete na UI — fica em iteração futura. Hoje, restauração via Supabase Studio (`UPDATE ... SET deleted_at = NULL`).
- Hard delete (`DELETE FROM`) — soft-delete é mais seguro.

## Arquivos modificados

- `live.html` — função `deleteRef()` + CSS `.btn-danger`
