# E2-S5 — Bulk add (20 links de uma vez)

**Epic:** EPIC-02 — Curadoria Power Tools
**Status:** Ready
**Prioridade:** P1
**Estimate:** 3h
**Owner:** Kaique
**Dependências:** Endpoint n8n `/bulk-add` (criar)

---

## User Story

Como **curador em sessão de pesquisa**, quero **colar 20 links de uma vez** e disparar processamento em lote, pra **não repetir 20 vezes** o formulário "URL → trilha → enviar".

## Contexto

Caso típico: Queila/Gobbi varre Instagram por 1h, junta 20-50 perfis interessantes em uma planilha/notes, depois precisa cadastrar todos. Hoje: 20× clicar "+ Adicionar", colar, escolher trilha, enviar. Demora 10+ minutos.

## Critérios de Aceite

1. **Modal de adicionar referência tem botão "Bulk add"** (toggle entre 1 e N)
2. Modo bulk substitui input único por **textarea** ("1 link por linha")
3. **Pré-validação visual**: cada linha vira chip com 🟢 (válido) ou 🔴 (inválido) + tipo detectado (perfil/post)
4. **Trilha única** aplicada a todos os links do batch
5. **Notas** opcional, aplicada a todos
6. **Botão "Adicionar N referências"** mostra contador
7. **Envia em batch** pro endpoint `/bulk-add` com array de payloads
8. **Progress bar** durante envio
9. **Resultado**: "18 enviadas ✓ · 2 falharam (link inválido)" + lista das que falharam pra retry

## Notas Técnicas

### Front

```js
function parseLinks(textarea) {
  return textarea.split('\n')
    .map(l => l.trim())
    .filter(l => l)
    .map(l => ({ raw: l, parsed: parseInput(l) }));
}

async function bulkAdd() {
  const lines = parseLinks(document.getElementById('bulkInput').value);
  const valid = lines.filter(l => l.parsed);
  if (!valid.length) { showToast('Nenhum link válido'); return; }
  
  const trilha = document.getElementById('f_trilha_uni').value;
  const notas = document.getElementById('f_notas_uni').value || '';
  
  const payloads = valid.map(l => ({
    ...l.parsed,
    trilha, notas,
    origem: 'manual_form_bulk',
    created_at: new Date().toISOString()
  }));
  
  const btn = document.getElementById('btnBulkAdd');
  btn.disabled = true; btn.textContent = `Enviando 0/${payloads.length}...`;
  
  let success = 0, failed = [];
  for (let i = 0; i < payloads.length; i++) {
    try {
      const res = await fetch(QUEUE_WEBHOOK, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payloads[i])
      });
      if (res.ok) success++;
      else failed.push(valid[i].raw);
    } catch (e) {
      failed.push(valid[i].raw);
    }
    btn.textContent = `Enviando ${i+1}/${payloads.length}...`;
  }
  
  showToast(`${success} enviadas ✓ · ${failed.length} falharam`);
  if (failed.length) {
    document.getElementById('bulkInput').value = failed.join('\n');
    showToast('Reabri os links que falharam pra retry');
  }
}
```

### Endpoint n8n alternativo (recomendado)

- Path: `/webhook/case-refs-bulk-add`
- Body: `{ items: [...], trilha, notas }`
- Loop interno no n8n (mais eficiente que 20 requests do front)
- Resposta: `{ ok: true, processed: 18, failed: [{raw, error}] }`

## Definition of Done

- [ ] Toggle "Único / Bulk" no modal
- [ ] Textarea aceita até 100 linhas
- [ ] Pré-validação visual em tempo real (debounced)
- [ ] Progress durante envio
- [ ] Falhas re-aparecem pra retry
- [ ] Endpoint bulk no n8n criado e testado

## Edge cases

- **Link duplicado** dentro do batch: dedup automaticamente, mostra "X removidos como duplicados"
- **Link já existe no banco**: backend retorna `already_exists`, contabilizado separado
- **Mistura perfis e posts no mesmo batch**: ok, cada um vira payload do tipo certo

## Limites

- Max 100 links por batch (UI bloqueia além disso)
- Throttle: 1 request por 200ms pra não estourar Apify rate limit
