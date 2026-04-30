# case-refs — Documentação

Estrutura de docs no padrão AIOX (PRD + Epics + Stories).

## Estrutura

```
docs/
├── README.md             ← você está aqui
├── prd.md                ← Product Requirements Document
├── epics/
│   ├── EPIC-01-quick-wins.md
│   ├── EPIC-02-curadoria-power-tools.md
│   ├── EPIC-03-intelligence-integration.md
│   └── EPIC-04-ai-mobile.md
└── stories/
    ├── E1-S1-dominio-customizado.md
    ├── E1-S2-protecao-por-senha.md
    ├── E1-S3-edicao-inline-notas.md
    ├── E1-S4-botao-deletar.md
    ├── E2-S1-deep-link-card.md
    ├── E2-S2-copia-transcricao.md
    ├── E2-S3-filtro-data-custom.md
    ├── E2-S4-tag-livre.md
    ├── E2-S5-bulk-add.md
    ├── E2-S6-notificacao-processamento.md
    ├── E3-S1-dashboard-uso.md
    ├── E3-S2-modo-apresentacao.md
    ├── E3-S3-vinculo-mentorada.md
    ├── E3-S4-detector-saturacao.md
    ├── E3-S5-auto-rescan.md
    ├── E3-S6-api-publica.md
    ├── E4-S1-pwa-mobile.md
    ├── E4-S2-chat-search.md
    └── E4-S3-comparador-mentoradas.md
```

## Roadmap visual

| Horizonte | Epic | Stories | Estimate total | Status |
|---|---|---|---|---|
| Imediato | EPIC-01 Quick Wins | 4 (4 ✅) | ~1 dia | ✅ Done |
| Curto prazo | EPIC-02 Curadoria Power Tools | 6 (6 ✅) | ~2-3 dias | ✅ Done |
| Médio prazo | EPIC-03 Intelligence & Integration | 6 (3 ✅ + 3 🔵) | ~8-12 dias | 🟡 Parcial |
| Longo prazo | EPIC-04 AI & Mobile | 3 (1 ✅ + 2 🔵) | ~3-4 semanas | 🟡 Parcial |
| **Total** | **4 epics** | **19 stories (14 ✅ + 5 🔵)** | **~6 semanas** | |

## Stories concluídas

- ✅ **E1-S1** — Domínio customizado `refs.casein.com.br` (2026-04-30)
- ✅ **E1-S2** — Proteção por senha gate client-side (2026-04-30)
- ✅ **E1-S3** — Edição inline de notas (2026-04-30)
- ✅ **E1-S4** — Botão deletar com soft-delete (2026-04-30)
- ✅ **E2-S1** — Deep-link de card (2026-04-30)
- ✅ **E2-S2** — Cópia de transcrição (2026-04-30)
- ✅ **E2-S3** — Filtro por data customizada (2026-04-30)
- ✅ **E2-S4** — Tag livre por card (2026-04-30)
- ✅ **E2-S5** — Bulk add (2026-04-30)
- ✅ **E2-S6** — Notificação processamento via heurística client (2026-04-30)
- ✅ **E3-S1** — Dashboard de uso em /dashboard (2026-04-30)
- ✅ **E3-S2** — Modo apresentação com PDF via jsPDF (2026-04-30)
- ✅ **E3-S4** — Detector saturação (banner client-side; cron/email = Discovery)
- ✅ **E4-S1** — PWA mobile instalável (manifest + Service Worker + ícones) (2026-04-30)

## Stories em Discovery (requerem decisão/setup externo)

- 🔵 **E3-S3** — Vincular ref → mentorada (precisa schema canônico de mentoradas)
- 🔵 **E3-S5** — Auto-rescan (100% backend; cron n8n + Apify)
- 🔵 **E3-S6** — API pública (Cloudflare Worker ou Vercel Pro)
- 🔵 **E4-S2** — Chat-to-search (pgvector + OpenAI/Claude API)
- 🔵 **E4-S3** — Comparador mentoradas (depende E3-S3)

## Como contribuir

1. **Pegar story**: leia o markdown da story, valide critérios de aceite com Kaique se houver dúvida
2. **Branch**: `feature/E{N}-S{M}-{slug}` (ex: `feature/E1-S1-dominio-customizado`)
3. **Commit**: `feat(E1-S1): adiciona domínio customizado` (referenciar story id)
4. **PR**: descrição lista os critérios atendidos com checkboxes
5. **Merge em main**: dispara deploy automático no Vercel

## Status legend

- `Discovery` — escopo ainda em validação, pode mudar significativamente
- `Ready` — pronto pra desenvolvimento, escopo congelado
- `In Progress` — alguém está trabalhando
- `Done` — mergeado em produção

## Convenções

- **IDs de epics**: `EPIC-NN`
- **IDs de stories**: `EN-SM` (Epic N, Story M dentro do epic)
- **Prioridade**: P0 (bloqueador), P1 (alto valor), P2 (médio), P3 (futuro)
- **Estimate**: realista, em horas/dias úteis (não dias-corridos)

## Próximos passos sugeridos

1. **Sprint 1** (esta semana): fechar EPIC-01 inteiro (4 stories, ~1 dia)
2. **Sprint 2** (próxima): atacar EPIC-02 (6 stories, 2-3 dias)
3. **Sprint 3+**: EPIC-03 incremental, validando uso real antes de continuar
4. **Reavaliar EPIC-04** após 60 dias com dados de uso reais

## Owner

Kaique Rodrigues — atualiza prioridades baseado em feedback Queila/Gobbi e uso do time.
