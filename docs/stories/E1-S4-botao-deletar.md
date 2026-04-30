# E1-S4 — Botão deletar referência com confirm

**Epic:** EPIC-01 — Quick Wins
**Status:** Ready
**Prioridade:** P0
**Estimate:** 1.5h
**Owner:** Kaique
**Dependências:** Endpoint n8n `/delete-ref` (criar) + E1-S2 (auth recomendado antes)

---

## User Story

Como **curador**, quero **remover** uma referência cadastrada errada (URL inválida, duplicada, conteúdo fora do escopo), pra **manter o banco limpo** sem precisar abrir Supabase.

## Contexto

Hoje: ref errada fica lá pra sempre. Pra deletar, abre Supabase Studio, encontra a row, deleta manualmente. Curador médio não tem acesso ao Supabase.

## Critérios de Aceite

1. **No modal de detalhes** da ref, botão **"🗑️ Excluir"** discreto (canto inferior, vermelho)
2. Clicar abre **confirm dialog** com:
   - Texto: "Excluir esta referência? Essa ação não pode ser desfeita."
   - Mostra perfil + caption preview pra confirmar visualmente
   - Botões "Cancelar" (default) e "Excluir" (vermelho)
3. **Confirmar** chama `POST /delete-ref/{id}` no webhook n8n
4. Em sucesso: modal fecha, card some da lista (otimista), toast "Excluído ✓"
5. Em erro: card volta, toast "Erro: {msg}"
6. **Soft-delete preferido** (`deleted_at` timestamp) ao invés de DELETE — permite undelete depois
7. **View pública filtra** `WHERE deleted_at IS NULL`

## Notas Técnicas

```js
async function deleteRef(refId, perfilLabel, captionPreview) {
  if (!confirm(`Excluir referência de @${perfilLabel}?\n\n"${captionPreview.slice(0,80)}..."\n\nEssa ação não pode ser desfeita.`)) return;
  const res = await fetch(WEBHOOK_DELETE, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ op: 'soft_delete', id: refId })
  });
  if (!res.ok) { showToast('Erro: HTTP ' + res.status); return; }
  showToast('Excluído ✓');
  closeModal();
  // re-render list (filter out deleted)
  DATA = DATA.filter(r => r.id !== refId);
  render();
}
```

## Migration Supabase

```sql
ALTER TABLE referencias_conteudo ADD COLUMN deleted_at timestamptz;

-- Update view pra filtrar
CREATE OR REPLACE VIEW v_referencias_publicas AS
  SELECT * FROM referencias_conteudo WHERE deleted_at IS NULL;
```

## Endpoint n8n necessário

- Path: `/webhook/case-refs-delete`
- Método: POST
- Body: `{ op: 'soft_delete', id: number }`
- Faz: `UPDATE referencias_conteudo SET deleted_at = now() WHERE id = $1`
- Retorna: `{ ok: true, id }` ou `{ ok: false, error }`

## Definition of Done

- [ ] Botão "Excluir" presente nos modais de `/posts` e `/live`
- [ ] Confirm dialog mostra contexto (perfil + caption)
- [ ] Soft-delete via webhook funciona end-to-end
- [ ] View pública filtra deletadas
- [ ] Migration Supabase aplicada
- [ ] Erro de rede mostra toast claro
