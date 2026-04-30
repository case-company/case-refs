# E3-S1 — Dashboard de uso

**Epic:** EPIC-03 — Intelligence & Integration
**Status:** ✅ Done (sem tracking de cliques — fica em iteração futura)
**Concluído em:** 2026-04-30

## Implementação (no ar em `/dashboard`)

Página standalone `dashboard.html` com 6 cards + 2 heatmaps:

### Cards
1. **Volume total** — total de refs, perfis únicos, breakdown por tipo de artefato
2. **Crescimento (sparkline)** — gráfico de barras das últimas 12 semanas + contador 7d/30d
3. **Por trilha** — Clínica vs Mentoria com barras proporcionais
4. **Por etapa do funil** — Descoberta / Confiança / Ação
5. **Por tipo estratégico** — top 10 (Apresentação, Prova Social, etc)
6. **Top 10 perfis** — perfis com mais referências

### Heatmaps de cobertura
- **Trilha Clínica** — matriz Tipo × Etapa
- **Trilha Mentoria** — idem
- Códigos de cor: 🔴 ≤2 refs (gap) · 🟡 3-5 (atenção) · 🟢 6+ (saudável)

### Alerta de saturação no topo
- Banner vermelho aparece se há ≥1 categoria com ≤2 refs
- Lista até 8 categorias críticas com contagem
- Cobre E3-S4 também (parte client-side)

## Arquivos modificados

- `dashboard.html` — nova página
- `index.html` — link "Dashboard" na landing

## Não implementado (iteração futura)

- **Tracking de cliques** ("top consultadas") — requer tabela `ref_views` + endpoint
- **Filtro por período** customizado no dashboard — usa todos os dados
- **Export CSV** dos cards — não implementado
- **Alerta semanal por email** — fica em E3-S4 (cron n8n)
