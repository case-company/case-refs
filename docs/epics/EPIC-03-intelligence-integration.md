# EPIC-03 — Intelligence & Integration

**Status:** Ready
**Horizonte:** Médio prazo (1-2 dias por story)
**Prioridade:** P2
**Owner:** Kaique Rodrigues
**Estimate:** 8-12 dias total (6 stories × 1-2 dias cada)

---

## Goal

Transformar banco passivo em sistema ativo de inteligência. Ele não só armazena — ele observa, alerta, gera artefatos, e conversa com outros sistemas Case (Spalla, dossiê pipeline, Maestro).

## Stories

- [x] ✅ [E3-S1: Dashboard de uso](../stories/E3-S1-dashboard-uso.md) — concluído 2026-04-30
- [x] ✅ [E3-S2: Modo apresentação (PDF)](../stories/E3-S2-modo-apresentacao.md) — concluído 2026-04-30
- [ ] 🔵 [E3-S3: Vincular referência → mentorada](../stories/E3-S3-vinculo-mentorada.md) — Discovery (depende de schema mentoradas)
- [x] ✅ [E3-S4: Detector de saturação](../stories/E3-S4-detector-saturacao.md) — concluído 2026-04-30 (parte client) / 🔵 (parte cron-email)
- [ ] 🔵 [E3-S5: Auto-rescan periódico](../stories/E3-S5-auto-rescan.md) — Discovery (100% backend)
- [ ] 🔵 [E3-S6: API pública](../stories/E3-S6-api-publica.md) — Discovery (fora do repo estático)

## Progresso

**3/6 stories concluídas** (1, 2, 4-parcial). 3 marcadas como Discovery com motivos claros nos arquivos:
- E3-S3 aguarda decisão sobre schema canônico de mentoradas
- E3-S5 é 100% backend (cron n8n + Apify, ~1 dia)
- E3-S6 requer Cloudflare Worker ou Vercel Pro

## Critérios de Sucesso

- Queila vê dashboard semanal com "trilha X / etapa Y tem só 2 refs — gap"
- Cria slide com 5 refs selecionadas em <1 minuto
- Sabe quais refs cada mentorada já recebeu (e evitar repetir)
- Sistema avisa quando trilha tem cobertura abaixo de threshold
- Perfil cadastrado é re-analisado automaticamente toda semana
- Spalla / dossiê pipeline / Maestro consultam refs via REST sem precisar duplicar dados

## Não inclui

- Geração automática de slides (sem decisão humana) — fica em E4
- Editor visual do slide — usa template fixo
- Multi-step approval do API request — endpoint público com rate limit

## Dependências externas

- Tabela `mentorada_referencias` (Supabase migration)
- Cron job no n8n (auto-rescan)
- API key/auth pública (decidir: anon supabase vs. cloudflare workers)
- Biblioteca de geração de PDF/slide (avaliar: jsPDF, html2canvas, ou Apify Actor)
