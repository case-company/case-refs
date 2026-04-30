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

| Horizonte | Epic | Stories | Estimate total |
|---|---|---|---|
| Imediato | EPIC-01 Quick Wins | 4 | ~1 dia |
| Curto prazo | EPIC-02 Curadoria Power Tools | 6 | ~2-3 dias |
| Médio prazo | EPIC-03 Intelligence & Integration | 6 | ~8-12 dias |
| Longo prazo | EPIC-04 AI & Mobile | 3 | ~3-4 semanas |
| **Total** | **4 epics** | **19 stories** | **~6 semanas** |

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
