# E2-S3 — Filtro por data customizada (range)

**Epic:** EPIC-02 — Curadoria Power Tools
**Status:** Ready
**Prioridade:** P2
**Estimate:** 2h
**Owner:** Kaique
**Dependências:** Nenhuma

---

## User Story

Como **curador**, quero filtrar por **range de datas customizado** ("entre 15/04 e 20/04"), pra **investigar batches específicos** que adicionei (ex: depois de uma sessão de pesquisa no Instagram).

## Contexto

Hoje `/live` tem filtros preset: 1h, 24h, hoje, 7d, 30d. Não cobre "semana passada do dia 14 ao 21" ou "abril inteiro".

## Critérios de Aceite

1. **Novo opção "Período personalizado..."** no select existente de período
2. Ao selecionar, abre **mini-popup com 2 date inputs**: De / Até
3. Validação: `de` ≤ `até`, ambos obrigatórios, ambos não-futuros
4. Botão "Aplicar" filtra cards com `created_at` entre as datas (inclusivo)
5. Indicador visual no select: "Personalizado: 15/04 → 20/04"
6. Botão "✕" no indicador limpa filtro
7. **URL state**: filtro persiste em hash (`#periodo=2026-04-15:2026-04-20`)
8. Compatível com filtro de ordem (recente/antigo)

## Notas Técnicas

```html
<!-- Adicionar opção no select periodo -->
<option value="custom">Período personalizado...</option>

<!-- Popup escondido inicialmente -->
<div id="customDateRange" style="display:none">
  <input type="date" id="dateFrom" max="${today}">
  <input type="date" id="dateTo" max="${today}">
  <button onclick="applyCustomRange()">Aplicar</button>
</div>
```

```js
function periodoCutoff(p) {
  // ... casos existentes
  if (p === 'custom') {
    const from = new Date(document.getElementById('dateFrom').value).getTime();
    const to = new Date(document.getElementById('dateTo').value).getTime() + 86400000;
    return { from, to };
  }
  return null;
}

// No filter
let rows = DATA.filter(r => {
  if (cutoff && typeof cutoff === 'object') {
    const t = new Date(r.created_at).getTime();
    if (t < cutoff.from || t > cutoff.to) return false;
  } else if (cutoff) {
    if (new Date(r.created_at).getTime() < cutoff) return false;
  }
  return true;
});
```

## Definition of Done

- [ ] Opção "Personalizado" no select de período
- [ ] Popup com 2 date inputs aparece
- [ ] Filtro aplicado e visível na UI
- [ ] Filtro limpável com 1 clique
- [ ] State persiste em URL (compartilhável)
- [ ] Compatível com outros filtros (trilha, etapa, ordem)

## Não cobre

- Time picker (só data, não hora)
- Filtro relativo ("últimos N dias" custom) — usa input de data
