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

- [ ] [E3-S1: Dashboard de uso](../stories/E3-S1-dashboard-uso.md)
- [ ] [E3-S2: Modo apresentação (slide/PDF)](../stories/E3-S2-modo-apresentacao.md)
- [ ] [E3-S3: Vincular referência → mentorada](../stories/E3-S3-vinculo-mentorada.md)
- [ ] [E3-S4: Detector de saturação](../stories/E3-S4-detector-saturacao.md)
- [ ] [E3-S5: Auto-rescan periódico de perfis](../stories/E3-S5-auto-rescan.md)
- [ ] [E3-S6: API pública pra outros apps Case](../stories/E3-S6-api-publica.md)

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
