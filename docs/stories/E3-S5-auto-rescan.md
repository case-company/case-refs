# E3-S5 — Auto-rescan periódico de perfis

**Epic:** EPIC-03 — Intelligence & Integration
**Status:** 🔵 Discovery (não implementada nesta sprint — 100% backend)

## Por que não foi implementada agora

Esta story é **100% server-side** (cron n8n + Apify + Supabase). Zero código frontend. Saí do escopo de "rodar tudo que é UI" das outras stories.

## O que precisa ser feito (~1 dia)

### 1. Migration Supabase

```sql
ALTER TABLE referencias_conteudo ADD COLUMN IF NOT EXISTS last_scanned_at TIMESTAMPTZ;
ALTER TABLE referencias_conteudo ADD COLUMN IF NOT EXISTS unpinned_at TIMESTAMPTZ;

CREATE TABLE IF NOT EXISTS scan_runs (
  id BIGSERIAL PRIMARY KEY,
  ran_at TIMESTAMPTZ DEFAULT now(),
  perfis_processados INTEGER,
  refs_adicionadas INTEGER,
  refs_removidas INTEGER,
  duracao_segundos INTEGER,
  erros JSONB
);
```

### 2. Cron n8n

Workflow com trigger semanal (Domingo 22:00 BRT):
- Query Supabase: perfis cadastrados com `last_scanned_at < now() - 7d`
- Loop (max 30 perfis/run, throttle 30s/perfil):
  - Run Apify Actor `instagram-profile-scraper`
  - Diff: adds, removes (unpin), changes de posição
  - INSERT/UPDATE no Supabase
  - UPDATE `last_scanned_at = now()`
- INSERT em `scan_runs` com summary

### 3. Notificação (opcional)

Se há refs novas detectadas: trigger toast no `/live` ou banner na próxima visita do user.

## Custo estimado

- Apify scraper: ~$0.0008/perfil × 30 perfis × 4 semanas = **~$0.10/mês**
- n8n execution: incluído no plano existente

## Quando implementar

Faz sentido depois que volume de refs justifica (>500 perfis cadastrados) — aí o "perfil X postou um fixado novo" começa a ser perda real.

A story original (versão completa) fica como spec pronta pra execução em `docs/stories/E3-S5-auto-rescan.md`.
