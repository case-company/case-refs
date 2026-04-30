# E2-S6 — Notificação quando processamento termina

**Epic:** EPIC-02 — Curadoria Power Tools
**Status:** ✅ Done (heurística client-side, sem realtime)
**Concluído em:** 2026-04-30

## Implementação

### Tracking de pendentes

- Ao adicionar referência (single ou bulk), `trackPending(payload)` salva chave `url|created_at` em localStorage
- Lista de pendentes persiste entre reloads e abas

### Detecção de conclusão

- `checkPendingComplete()` roda a cada `load()` (a cada 30s pelo auto-refresh)
- Pra cada chave pendente, procura nos cards recém-carregados (últimos 10 min) match por `url` ou `shortcode`
- Match → toast "✓ @perfil processado" + Notification do navegador (se permitido) + remove da fila

### UI

- **Banner discreto no topo** de `/live` mostra "⏳ N referência(s) processando…" enquanto há pendentes
- **Toast por ref completa**
- **Notification do navegador** (com permissão) funciona com aba em background
- Pede permissão automaticamente no primeiro acesso com pendentes

## Arquivos modificados

- `live.html` — `PENDING_IDS` Set + localStorage sync, `addPending`/`updatePendingBanner`/`checkPendingComplete`, banner CSS, request de Notification permission
- `trilhas.html` — `trackPending()` chamado em `addReference()` (single + bulk)

## Decisões técnicas

- **Heurística por URL/shortcode** ao invés de Realtime Supabase: simpler, no extra dependency, dados já chegam via auto-refresh de 30s
- **Não há coluna `status` na tabela** — detecção é "apareceu na view pública" = "processado". Refs que falham processamento nunca ficam visíveis = nunca disparam toast (acceptable)

## Iteração futura

- Coluna `status` em `referencias_conteudo` (`pending`/`processing`/`processed`/`failed`)
- Supabase Realtime via `postgres_changes` em vez de polling
- Timeout: pendentes >10min → toast "Algumas refs ainda processando…"
