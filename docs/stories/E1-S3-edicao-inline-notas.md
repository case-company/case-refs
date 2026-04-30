# E1-S3 — Edição inline de notas em cards

**Epic:** EPIC-01 — Quick Wins
**Status:** 🟡 Frontend Done — aguarda backend (webhook n8n + migration)
**Prioridade:** P0
**Estimate:** 2h (front) + 30min (backend)
**Owner:** Kaique
**Concluído front em:** 2026-04-30

---

## User Story

Como **curador**, quero **editar a nota** de uma referência sem precisar deletar e recriar.

## Estado atual

### ✅ Frontend (deployado em produção)

Em `/live`, ao abrir modal de qualquer card:

- Seção **Notas** mostra texto atual + botão **"✏️ Editar"**
- Clicar abre **textarea editável** + botões "Salvar" / "Cancelar"
- **Salvar** chama `POST https://webhook.manager01.feynmanproject.com/webhook/case-refs-mutate`
  - Body: `{ op: 'update_note', id: <ref_id>, notas: <texto_novo> }`
- Em sucesso: textarea fecha, texto novo aparece, toast "Nota salva ✓"
- Em erro (webhook 404 etc): toast "Erro: HTTP {status}"
- Atualiza DATA local em memória pra refletir sem reload

### ⏳ Backend (pendente — bloqueador pra funcionar end-to-end)

**Webhook n8n a criar** (path: `/case-refs-mutate`):

```
Trigger: Webhook (POST)
Path: case-refs-mutate

Switch on body.op:
  case 'update_note':
    UPDATE referencias_conteudo SET notas = $body.notas WHERE id = $body.id
    Return { ok: true, id, notas }
  case 'soft_delete':
    UPDATE referencias_conteudo SET deleted_at = now() WHERE id = $body.id
    Return { ok: true, id }
```

**Migration Supabase necessária** (compartilhada com E1-S4):

```sql
-- Para soft delete (E1-S4)
ALTER TABLE referencias_conteudo ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

-- Atualizar view pública pra filtrar deletadas
CREATE OR REPLACE VIEW v_referencias_publicas AS
  SELECT * FROM referencias_conteudo WHERE deleted_at IS NULL;
```

## Critérios de Aceite

1. ✅ Botão "Editar" aparece no modal de detalhes em `/live`
2. ✅ Clicar transforma texto em textarea editável
3. ✅ Salvar dispara webhook
4. ✅ Erro de rede mostra toast (não silencia)
5. ⏳ Reload da página mostra nota atualizada **(depende do webhook + migration)**
6. ⏳ Endpoint n8n criado e testado **(pendente)**

## Como destravar

1. Aplicar migration no Supabase Case
2. Criar workflow n8n com path `/case-refs-mutate`
3. Testar: abrir `/live`, editar nota de uma ref, salvar
4. Atualizar status pra `✅ Done`

## Arquivos modificados

- `live.html` — função `editNotes()`, `saveNotes()`, `cancelEditNotes()` + CSS `.btn-mini`
