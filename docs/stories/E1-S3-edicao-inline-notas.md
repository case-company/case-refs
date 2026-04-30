# E1-S3 — Edição inline de notas em cards

**Epic:** EPIC-01 — Quick Wins
**Status:** Ready
**Prioridade:** P0
**Estimate:** 2h
**Owner:** Kaique
**Dependências:** Endpoint n8n `/update-ref` (criar)

---

## User Story

Como **curador**, quero **editar a nota** de uma referência sem precisar deletar e recriar, pra **iterar contexto** ("ah, descobri que esse ref tá funcionando bem na fase Confiança").

## Contexto

Hoje: nota é definida no momento de adicionar. Pra mudar, precisa deletar + cadastrar de novo (perde transcrição reprocessada, perde data original).
Queremos: editar nota in-place no modal/card.

## Critérios de Aceite

1. **No modal de detalhes** da ref (ao clicar no card), seção "Notas" tem botão **"✏️ Editar"**
2. Clicar abre **textarea editável** no lugar do texto
3. Botões **"Salvar"** e **"Cancelar"**
4. **Salvar** chama `PATCH /update-ref/{id}` no webhook n8n com `{ id, notas: novoTexto }`
5. Em sucesso: textarea fecha, texto novo aparece, toast "Salvo ✓"
6. Em erro: mantém modo edição, toast "Erro: {msg}"
7. **Não permite ediçāo sem auth** (depois que E1-S2 entrar)

## Notas Técnicas

```js
// posts.html, live.html — modal de detalhes
function editNote(refId) {
  const sec = document.getElementById('noteSec');
  const cur = sec.dataset.value || '';
  sec.innerHTML = `
    <textarea id="noteEdit" rows="3">${escapeHtml(cur)}</textarea>
    <button onclick="saveNote('${refId}')">Salvar</button>
    <button onclick="cancelNote()">Cancelar</button>
  `;
  document.getElementById('noteEdit').focus();
}

async function saveNote(id) {
  const txt = document.getElementById('noteEdit').value;
  const res = await fetch(WEBHOOK_UPDATE, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ op: 'update_note', id, notas: txt })
  });
  if (!res.ok) { showToast('Erro: HTTP ' + res.status); return; }
  showToast('Salvo ✓');
  // re-render note section
}
```

## Endpoint n8n necessário

- Path: `/webhook/case-refs-update`
- Método: POST
- Body: `{ op: 'update_note', id: number, notas: string }`
- Faz: `UPDATE referencias_conteudo SET notas = $1 WHERE id = $2`
- Retorna: `{ ok: true, id, notas }` ou `{ ok: false, error }`

## Definition of Done

- [ ] Botão "Editar" aparece em todos os modais que mostram nota
- [ ] Edição salva no Supabase via webhook
- [ ] Reload da página mostra nota atualizada
- [ ] Endpoint n8n criado, testado com curl
- [ ] Erro de rede mostra toast (não silencia)
