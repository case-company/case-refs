# E2-S1 — Compartilhamento de card via deep-link

**Epic:** EPIC-02 — Curadoria Power Tools
**Status:** Ready
**Prioridade:** P1
**Estimate:** 2h
**Owner:** Kaique
**Dependências:** Nenhuma

---

## User Story

Como **time da Case**, quero compartilhar **uma referência específica** com colega/mentorada via WhatsApp/email, pra **direcionar a atenção** sem mandar a página inteira.

## Contexto

Hoje: pra mandar uma ref específica, dá print, descreve, ou cola URL do Instagram (perde transcrição/notas).
Queremos: link único que abre o modal da ref específica.

## Critérios de Aceite

1. **Cada card tem botão "🔗 Compartilhar"** (canto do card ou no modal)
2. Clicar **copia pro clipboard** o link `https://refs.case.com.br/live#card={id}` (ou `/posts#card={id}`)
3. Toast confirma: "Link copiado ✓"
4. **Abrir o link** carrega a página normal + abre o modal do card automaticamente
5. **Scroll automático** até o card na lista (pra contexto)
6. Funciona em `/live`, `/posts`, e `/trilhas`

## Notas Técnicas

```js
// Gerar link
function shareCard(refId) {
  const url = `${window.location.origin}${window.location.pathname}#card=${refId}`;
  navigator.clipboard.writeText(url).then(() => showToast('Link copiado ✓'));
}

// Ler hash no load
window.addEventListener('load', () => {
  const m = window.location.hash.match(/#card=(\d+)/);
  if (m) {
    const id = parseInt(m[1]);
    // espera DATA carregar, depois abre
    const tryOpen = () => {
      if (DATA.length) { openModal(id); scrollToCard(id); }
      else setTimeout(tryOpen, 200);
    };
    tryOpen();
  }
});

function scrollToCard(id) {
  const el = document.querySelector(`[data-card-id="${id}"]`);
  if (el) el.scrollIntoView({ behavior: 'smooth', block: 'center' });
}
```

## Marcações HTML

Adicionar `data-card-id="${r.id}"` em cada card no HTML gerado pelo render.

## Definition of Done

- [ ] Botão "🔗" visível em cada card (hover ou modal)
- [ ] Link copiado abre o modal correto
- [ ] Scroll suave até o card
- [ ] Funciona após auth (E1-S2) — link público mas só abre se logado

## Edge cases

- **Card deletado** (E1-S4): link não acha → toast "Referência não disponível" + abre lista normal
- **Card de outra trilha**: filtros aplicados podem esconder. Fix: `clearFilters()` antes de abrir modal via deep-link
