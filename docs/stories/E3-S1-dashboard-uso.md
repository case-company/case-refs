# E3-S1 — Dashboard de uso

**Epic:** EPIC-03 — Intelligence & Integration
**Status:** Ready
**Prioridade:** P2
**Estimate:** 1.5 dia
**Owner:** Kaique
**Dependências:** Tracking de "ref consultada" (logs no front)

---

## User Story

Como **Queila/Gobbi**, quero um **dashboard semanal** com métricas do banco (refs por trilha, mais consultadas, gargalos do funil sem cobertura), pra **decidir onde investir tempo de curadoria** com base em dado, não intuição.

## Contexto

Hoje: zero visibilidade de uso. Não sabemos se trilha Clínica está saturada ou se etapa Confiança da Mentoria tem só 2 refs (gap claro).

## Critérios de Aceite

1. **Nova página `/dashboard`** com:
   - **Card "Volume"**: total de refs, breakdown por trilha + etapa + tipo
   - **Card "Crescimento"**: gráfico de refs/semana últimas 12 semanas
   - **Card "Cobertura"**: matriz trilha × etapa × tipo (heatmap, vermelho onde tem ≤2 refs)
   - **Card "Top consultadas"**: top 10 refs mais clicadas (precisa tracking)
   - **Card "Top contribuidores"**: quem mais adiciona refs (origem do payload)
   - **Card "Pendentes"**: refs com `status=pending` há +30min (alerta)
2. **Filtros**: período (default 30d), trilha
3. **Export CSV**: botão "📥 Baixar dados" pra cada card
4. **Atualização automática**: dados refrescam a cada minuto (live)

## Notas Técnicas

### Tracking de cliques (precondição)

```js
// Em openModal, registrar view
async function trackView(refId) {
  await fetch(WEBHOOK_TRACK, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ op: 'view', ref_id: refId, ts: Date.now() })
  });
}
```

### Migration

```sql
CREATE TABLE ref_views (
  id BIGSERIAL PRIMARY KEY,
  ref_id BIGINT REFERENCES referencias_conteudo(id),
  viewed_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_views_ref ON ref_views(ref_id);
CREATE INDEX idx_views_date ON ref_views(viewed_at);

-- View pra dashboard
CREATE OR REPLACE VIEW v_dashboard_cobertura AS
SELECT
  trilha,
  etapa_funil,
  tipo_estrategico,
  COUNT(*) as total,
  CASE WHEN COUNT(*) <= 2 THEN 'gap' WHEN COUNT(*) <= 5 THEN 'fraco' ELSE 'ok' END as nivel
FROM referencias_conteudo
WHERE deleted_at IS NULL
GROUP BY trilha, etapa_funil, tipo_estrategico;

CREATE OR REPLACE VIEW v_dashboard_top_consultadas AS
SELECT r.id, r.perfil, r.shortcode, r.resumo, COUNT(v.id) as views
FROM referencias_conteudo r
LEFT JOIN ref_views v ON v.ref_id = r.id
WHERE r.deleted_at IS NULL AND v.viewed_at > now() - interval '30 days'
GROUP BY r.id, r.perfil, r.shortcode, r.resumo
ORDER BY views DESC
LIMIT 10;
```

### Visualização

- **Lib**: Chart.js (CDN, sem build) ou D3.js
- **Heatmap**: tabela HTML com cores via CSS gradient

```js
// Heatmap simplificado
function renderHeatmap(data) {
  const trilhas = [...new Set(data.map(r => r.trilha))];
  const etapas = ['DESCOBERTA', 'CONFIANCA', 'ACAO'];
  const tipos = [...new Set(data.map(r => r.tipo_estrategico))];
  
  let html = '<table class="heatmap">';
  html += '<tr><th></th>' + etapas.map(e => `<th>${e}</th>`).join('') + '</tr>';
  trilhas.forEach(t => {
    tipos.forEach(tipo => {
      html += `<tr><th>${t} / ${tipo}</th>`;
      etapas.forEach(e => {
        const cell = data.find(r => r.trilha===t && r.etapa_funil===e && r.tipo_estrategico===tipo);
        const n = cell?.total || 0;
        const cls = n <= 2 ? 'gap' : n <= 5 ? 'fraco' : 'ok';
        html += `<td class="${cls}" title="${n} refs">${n}</td>`;
      });
      html += '</tr>';
    });
  });
  html += '</table>';
  return html;
}
```

## Definition of Done

- [ ] Página `/dashboard` no ar com 6 cards
- [ ] Heatmap de cobertura visível (vermelho onde gap)
- [ ] Tracking de views funcionando
- [ ] Top consultadas baseado em views reais
- [ ] Export CSV em cada card
- [ ] Mobile-responsive
- [ ] Migration aplicada

## Não cobre

- Comparação semana × semana (delta) — fica em E3-S4 (saturação)
- Filtro por mentorada — fica em E3-S3
- Email semanal automático com dashboard — futuro
