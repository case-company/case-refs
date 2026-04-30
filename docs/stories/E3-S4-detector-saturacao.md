# E3-S4 — Detector de saturação

**Epic:** EPIC-03 — Intelligence & Integration
**Status:** ✅ Done (parte client-side) · 🔵 Discovery (parte cron/email)
**Concluído em:** 2026-04-30

## Implementação client-side (no ar em `/dashboard`)

- **Banner vermelho fixo no topo** do dashboard
- Aparece automaticamente se ≥1 categoria (trilha × etapa × tipo) tem ≤2 refs
- Lista até 8 categorias críticas com contagem exata
- Mostra contador total se houver >8 ("+ N outras…")
- **Atualização automática** — recalcula a cada load do dashboard
- Cobre uso passivo: Queila/Gobbi vê quando abre dashboard

## Implementação cron/email (não feita)

A versão original previa cron job semanal n8n + email Resend pra Queila/Gobbi.

Não implementado porque:
- Cron requer config no n8n (você tem acesso, eu não)
- Email transactional precisa de provider (Resend? Mailgun? Já tem?)
- Snooze persistente requer tabela nova (`saturation_alerts`)

Pra você executar quando quiser (~30 min):

### n8n workflow
```
Trigger: Cron - Toda segunda 09:00 BRT
Step 1: HTTP GET v_referencias_publicas (anon key)
Step 2: Code node — agrupa por trilha/etapa/tipo, filtra count <= 2
Step 3: If criticos.length > 0:
  - Format markdown email
  - Resend / Mailgun → Queila + Gobbi
Step 4: INSERT em saturation_alerts (opcional, audit)
```

## Arquivos modificados

- `dashboard.html` — função `findGaps()` + render do `#alertBanner`

## Iteração futura

- View Supabase materialized `v_saturacao` pra evitar recalcular client-side todo load
- Snooze (botão "OK, vou cuidar (silenciar 7d)" persistido em localStorage)
- Threshold configurável pelo usuário
