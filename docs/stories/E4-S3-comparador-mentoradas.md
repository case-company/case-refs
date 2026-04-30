# E4-S3 — Comparador automático entre mentoradas

**Epic:** EPIC-04 — AI & Mobile
**Status:** Discovery
**Prioridade:** P3
**Estimate:** 1 semana
**Owner:** Kaique
**Dependências:** E3-S3 (vínculo mentorada) + dados suficientes

---

## User Story

Como **mentor**, quero **comparar duas mentoradas concorrentes** lado-a-lado mostrando quais refs cada uma recebeu (e em qual etapa do funil), pra **identificar gaps** e **sugerir ajuste** ("Mentorada A recebeu 12 refs, B só 3 na fase Confiança — gap").

## Contexto

E3-S3 vincula refs ↔ mentoradas. Esta story usa esse dado pra comparar e sugerir.

## Critérios de Aceite

1. **Página `/comparar`**:
   - 2 dropdowns: "Mentorada A" / "Mentorada B"
   - Botão "Comparar"
2. **Resultado** em tabela trilha × etapa × tipo:
   - Coluna A: count de refs vinculadas
   - Coluna B: count de refs vinculadas
   - Diff visual: barra horizontal proporcional
   - Highlight em vermelho quando uma tem ≤3 refs e outra tem ≥7 (gap)
3. **Sugestões automáticas**:
   - "Mentorada B tem gap em Confiança/Prova Social. Sugerir refs X, Y, Z (que A já recebeu mas B não)"
   - LLM gera narrativa: "B se beneficiaria de exposição a refs como..."
4. **Export**: relatório PDF com a comparação + sugestões
5. **Salvar comparação** em histórico (`comparisons` table)
6. **Filtro por período**: comparar últimos 30/90/180 dias

## Notas Técnicas

### Algoritmo

```js
async function compare(mentorAId, mentorBId, periodDays = 90) {
  const since = new Date(Date.now() - periodDays * 86400000).toISOString();
  
  const refsA = await supa.from('mentorada_referencias')
    .select('ref_id, vinculado_em, referencias_conteudo(*)')
    .eq('mentorada_id', mentorAId)
    .gte('vinculado_em', since);
  
  const refsB = /* same for B */;
  
  // Group por trilha × etapa × tipo
  const grid = {};
  [...refsA.data, ...refsB.data].forEach(link => {
    const r = link.referencias_conteudo;
    const key = `${r.trilha}|${r.etapa_funil}|${r.tipo_estrategico}`;
    grid[key] = grid[key] || { trilha: r.trilha, etapa: r.etapa_funil, tipo: r.tipo_estrategico, a: [], b: [] };
    if (refsA.data.find(x => x.ref_id === r.id)) grid[key].a.push(r.id);
    if (refsB.data.find(x => x.ref_id === r.id)) grid[key].b.push(r.id);
  });
  
  // Identificar gaps
  const gaps = Object.values(grid).filter(g => 
    Math.abs(g.a.length - g.b.length) >= 4 && Math.min(g.a.length, g.b.length) <= 3
  );
  
  // Sugestões: refs que A recebeu e B não
  const suggestions = gaps.map(g => {
    const inALacking = g.a.length > g.b.length ? g.a : g.b;
    const target = g.a.length > g.b.length ? mentorBId : mentorAId;
    return { gap: g, target, suggest_ref_ids: inALacking.slice(0, 3) };
  });
  
  return { grid, gaps, suggestions };
}
```

### LLM narrative

```js
async function explainGaps(comparison, mentorADetails, mentorBDetails) {
  const prompt = `
Compara cobertura de duas mentoradas:

${mentorADetails.nome}:
- Total: ${comparison.grid /* sum */ } refs
- Foco em: ${ /* top 3 categorias */ }

${mentorBDetails.nome}:
- Total: ...
- Foco em: ...

Gaps identificados:
${comparison.gaps.map(g => `- ${g.trilha}/${g.etapa}/${g.tipo}: A=${g.a.length}, B=${g.b.length}`).join('\n')}

Escreva 2 parágrafos consultivos explicando os gaps e por que importam pra estratégia da mentorada com cobertura menor.
  `;
  
  const r = await fetch('/api/chat', {
    method: 'POST',
    body: JSON.stringify({ prompt, model: 'claude-sonnet-4-6' })
  });
  return (await r.json()).text;
}
```

### Visualização

Tabela HTML com barras CSS:
```html
<tr>
  <td>Mentoria / Confiança / Prova Social</td>
  <td><div class="bar bar-a" style="width:60%">12</div></td>
  <td><div class="bar bar-b" style="width:15%">3</div></td>
  <td class="gap">⚠️ Gap</td>
</tr>
```

### Migration

```sql
CREATE TABLE comparisons (
  id BIGSERIAL PRIMARY KEY,
  mentorada_a_id BIGINT,
  mentorada_b_id BIGINT,
  period_days INTEGER,
  result JSONB,
  generated_at TIMESTAMPTZ DEFAULT now(),
  generated_by TEXT
);
```

## Definition of Done

- [ ] Página /comparar com dropdowns
- [ ] Tabela comparativa com diff visual
- [ ] Sugestões automáticas baseadas em gap
- [ ] Narrativa LLM explica os gaps
- [ ] Export PDF do relatório
- [ ] Histórico salvo
- [ ] Filtro por período

## Edge cases

- **Mentorada com 0 refs**: mostra "Nenhuma ref vinculada ainda"
- **Mesma mentorada nos 2 dropdowns**: bloqueia, mostra erro
- **Sem dados suficientes** (<10 refs total entre as duas): aviso "Comparação requer mais dados"

## Não cobre

- Recomendação automática que aplica vínculo (humano sempre confirma)
- Comparação de N mentoradas (só 2 por vez)
- Predição de resultado ("se aplicar essas refs em B, ela vai converter +20%") — fora de escopo
