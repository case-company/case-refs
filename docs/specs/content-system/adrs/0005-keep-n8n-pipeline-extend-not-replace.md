---
title: ADR-0005 — Manter pipeline n8n + Apify + AssemblyAI; estender com fallback defensivo, não substituir
status: accepted
date: 2026-05-12
deciders: [Kaique]
supersedes: null
related:
  - 02-spec-tech.md#1.1
  - 02-spec-tech.md#1.2
  - 00-context-and-handoff.md#2
---

# ADR-0005 — Pipeline n8n preservado, com patch defensivo

## Context

O `refs.casein.com.br` hoje ingere conteúdo via:

- **n8n** (self-host na VPS Hetzner)
- **Apify Actor** `apify/instagram-scraper` (puxa post + caption + media)
- **AssemblyAI** (transcrição de vídeo/áudio em PT-BR)
- **Webhook → Supabase** (insert em `agente.referencias_conteudo`)

Esse pipeline funciona desde Abr/26. Custo atual ~$30-50/mês (Apify pay-per-use + AssemblyAI ~$0.04/min). Existem ~5.000 itens ingeridos.

Problema atual conhecido: o `apify/instagram-scraper` retorna `restricted_page` em ~12% dos perfis (perfis privados, geo-restricted, ou rate-limited pelo Instagram). Esses falhos hoje **somem silenciosamente** — não geram retry, não geram log estruturado, não viram backlog.

Com a expansão pro Content System CASE (mais perfis monitorados, mais clientes pilotando), surgem opções:

1. **Substituir Apify por scraper próprio** (Playwright headless, custo zero mas manutenção alta)
2. **Trocar Apify por concorrentes** (zhorex/instagram-scraper, scrapfly, etc.)
3. **Manter Apify, adicionar patch defensivo no workflow**
4. **Substituir AssemblyAI por Whisper local no Mac mini Tailscale** (custo zero, latência maior)

E há a tentação geral de "consolidar" — trocar n8n por código em Edge Function pra ter "stack única".

## Decision

**Manter n8n + Apify + AssemblyAI. Adicionar patch defensivo no workflow pra lidar com `restricted_page`. Não substituir nada em V1.**

Concretamente:

### Patch 1 — Defensive retry pra `restricted_page`
No workflow n8n de ingest, adicionar nó `IF restricted_page`:
- 1ª falha → retry com `proxy: residential` (Apify built-in, custo +30%).
- 2ª falha → fila `apify_failed` (nova tabela `agente.ingest_failures`) com `reason, perfil, url, timestamp, retry_count`.
- 3ª falha → notification webhook pro Telegram do Kaique.

### Patch 2 — Dedup por shortcode antes de inserir
Hoje a inserção pode duplicar item já presente. Adicionar `ON CONFLICT (shortcode) DO NOTHING` na RPC `case_refs_ingest`.

### Patch 3 — Tag `origem`
Inserir `origem ∈ {instagram_apify, instagram_apify_residential, manual_curador, manual_url}` em todo item. Permite rastrear custo e sucesso por origem.

### Patch 4 — Workflow de ingest emite log estruturado
n8n nó `Webhook /metrics` envia `{fonte, qtd_ok, qtd_fail, custo_apify, custo_assembly, duracao_ms}` ao final de cada execução. Persiste em `agente.ingest_runs` pra dashboard.

### O que NÃO entra
- Substituir Apify: custo de migração + risco de regressão > benefício marginal.
- Substituir AssemblyAI por Whisper local: feature de V2 (tem ganho real $$$), mas exige rede Tailscale estável VPS↔Mac mini, e fica fora do escopo Content System.
- Substituir n8n por código em Edge Fn: perde a UI visual de debug que o Felipe/Kaique usam pra inspecionar runs.

## Consequences

### Positivas

- **Zero downtime de ingest**: pipeline atual continua rodando; patches são aditivos.
- **Visibilidade de falhas**: `restricted_page` deixa de ser silencioso. Backlog reprocessável.
- **Custo controlado**: residential proxy só em retry → custo extra estimado +5-8% (não +30% sempre).
- **Dedup estrutural**: elimina classe inteira de bugs de duplicação.
- **Foundation pra dashboard `/dashboard` métricas**: §7.2 da spec depende de `ingest_runs` populado.
- **Reuso da expertise existente**: Kaique já opera n8n. Substituir = reaprender stack.

### Negativas / Trade-offs

- **Lock-in com Apify mantido**: se Apify subir preço 2x, ficamos expostos. Mitigação: abstrair via "ingest adapter" no n8n permite trocar sem refazer workflow inteiro.
- **n8n na VPS é SPOF**: se VPS cai, ingest para. Aceito em V1 (downtime ≤24h é tolerável pra produto editorial). Mitigação V2: backup workflow em n8n cloud.
- **AssemblyAI custo escalonado**: cresce linearmente com vídeos. Limite atual ~$15/mês (estimado em 5h de vídeo/mês). Reconsiderar quando passar de $50/mês.
- **Patch 1 tem complexidade extra no workflow** (ramo IF + tabela `ingest_failures`): pequena, ~30 minutos pra aplicar.

### Neutras

- Stack permanece "polyglot" (n8n + Edge Fn Deno + HTML estático). Aceito pelo princípio de "ferramenta certa pro problema certo".

## Alternatives Considered

### Alt A — Substituir Apify por scraper próprio com Playwright na VPS
- Custo Apify zerado (~$30-50/mês economia).
- **Por que rejeitada**:
  - Manutenção alta: Instagram quebra DOM ~mensal. Apify trata isso.
  - Risco de IP-ban no Vercel/VPS afeta outros serviços.
  - "Free não é grátis": tempo do Kaique custa mais que $50/mês.

### Alt B — Trocar `apify/instagram-scraper` por `zhorex/instagram-scraper`
- Outro actor Apify. Já usado pra Bilibili (vide MEMORY).
- **Por que rejeitada (em V1)**: smoke test exigiria reescrever mapeamento de campos (schema diferente). Custo de teste > benefício marginal. Reavaliar se `apify/instagram-scraper` falhar acima de 25%.

### Alt C — Substituir n8n por workflow em código (Deno + cron Vercel)
- Stack consolidada em TS/Deno.
- **Por que rejeitada**:
  - Perda da UI visual de debug do n8n.
  - Re-implementar retry/error handling em código vs nodes.
  - Vercel Cron Jobs têm limites de 10s timeout (Apify pode demorar muito mais).

### Alt D — Substituir AssemblyAI por Whisper local Mac mini
- Custo $0 / transcrição.
- **Por que rejeitada (em V1)**:
  - Exige Tailscale estável VPS↔Mac mini (já é, mas fora do escopo).
  - Latência: Whisper large-v3 leva ~3min/min de áudio. AssemblyAI faz em ~30s.
  - Mac mini é compartilhado com outros projetos (Nous Radar, Qwen).
  - Reconsiderar em V2 quando custo AssemblyAI passar $50/mês ou quando GPU dedicada estiver disponível.

### Alt E — Plug full-managed (Make/Zapier) + retirar n8n
- **Por que rejeitada**: lock-in pior, custo crescente por execução, e perde controle sobre nodes custom.

## Implementation Hooks

- **Workflow n8n**: editar `wf_ingest_instagram` adicionando 4 nodes (IF restricted, retry residential, fila failures, log metrics).
- **Migration**: nova migration `20260513008000_ingest_failures_and_runs.sql` cria 2 tabelas:
  ```
  agente.ingest_failures(id, fonte, url, perfil, reason, retry_count, created_at, resolved_at)
  agente.ingest_runs(id, fonte, qtd_ok, qtd_fail, custo_usd, duracao_ms, started_at, finished_at)
  ```
- **Edge Fn helper**: `case-refs-mutate` ganha `op=ingest_retry(id)` que repõe falha na fila.
- **Dashboard**: query `ingest_runs` pra mostrar painel de saúde do pipeline.

## Revisitar quando

- Falhas Apify passarem de 25% (hoje 12%).
- Custo Apify > $100/mês.
- Custo AssemblyAI > $50/mês.
- Necessidade de fontes além do Instagram (TikTok, YouTube) — aí a abstração de "ingest adapter" fica obrigatória.
- VPS começar a virar gargalo (CPU/RAM consistentemente > 80%).

## Related ADRs

- ADR-0003 (agentes como módulos) — agentes podem disparar workflows n8n pra processamento longo (ex: Agente 00 batch).
- ADR-0004 (frontend estático) — pipeline backend complexo libera frontend pra ser simples.
