# E2-S3 — Filtro por data customizada (range)

**Epic:** EPIC-02 — Curadoria Power Tools
**Status:** ✅ Done
**Concluído em:** 2026-04-30

## Implementação

- Nova opção **"Personalizado…"** no select de período em `/live`
- Selecionar mostra **2 date inputs** (De / Até) inline na toolbar
- Default ao primeiro toggle: últimos 7 dias
- Filtro inclui dias completos (00:00 do "De" → 23:59 do "Até")
- Compatível com filtros existentes (trilha, etapa, ordem, busca)
- Re-render em qualquer alteração

## Arquivos modificados

- `live.html` — opção `custom` no select, inputs `#dateFrom`/`#dateTo`, lógica em `periodoCutoff()`, listeners

## Iteração futura

- State persistente em URL (`#periodo=2026-04-15:2026-04-20`) pra compartilhar filtro — não implementado
