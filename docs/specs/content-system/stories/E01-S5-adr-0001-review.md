---
id: E01-S5
title: "Review e aprovação do ADR 0001 DECIDA"
type: story
epic: E01
status: Done
priority: P0
estimated_effort: XS
date: 2026-05-12
owner: Kaique Rodrigues
---

# Story E01-S5 — Review e aprovação do ADR 0001 DECIDA

## Story

**Como** time mantenedor do content-system,
**eu quero** o ADR 0001 (decida-taxonomy) revisado pelo Kaique e marcado como Accepted,
**para que** a decisão de adotar DECIDA como taxonomia oficial fique formalmente registrada — incluindo alternativas descartadas e consequências para futuras stories.

## Acceptance Criteria

1. ADR `adrs/0001-decida-taxonomy.md` lido e revisado pelo Kaique.
2. Status do ADR atualizado de `proposed` para `accepted` no frontmatter.
3. Seção "Consequences" cita explicitamente as 3 consequências práticas: (a) `etapa_funil` enum no DB não muda, (b) UX renderiza via `DECIDA_MAP`, (c) qualquer página nova precisa importar a constante.
4. Seção "Alternatives considered" lista pelo menos: (a) renomear o enum no DB (rejeitado por custo de migration), (b) manter "DESCOBERTA/CONFIANCA/ACAO" como labels (rejeitado por não comunicar a tripla).
5. ADR linkado em `00-context-and-handoff.md` e no `02-spec-tech.md`.

## Tasks

- [ ] Ler o ADR atual (89 linhas) (AC 1)
- [ ] Verificar se as seções Consequences e Alternatives cobrem os pontos da AC 3 e AC 4 — completar se faltar (AC 3, 4)
- [ ] Trocar status frontmatter (AC 2)
- [ ] Conferir links cruzados nos docs irmãos (AC 5)
- [ ] Adicionar entrada no Changelog do ADR

## Dev Notes

- ADR já existe (gerado pelo arquiteto AIOX no handoff). Esta story é review + aprovação, não autoria.
- Se durante o review o Kaique decidir mudar a decisão (improvável), reverter status para `proposed` e abrir story de revisão.

## Testing

- N/A (documento).

## Definition of Done

- [ ] AC 1-5 verificados
- [ ] Commit `docs(adr): aceitar ADR 0001 — taxonomia DECIDA`
