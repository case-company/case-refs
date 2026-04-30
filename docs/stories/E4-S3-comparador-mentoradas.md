# E4-S3 — Comparador automático entre mentoradas

**Epic:** EPIC-04 — AI & Mobile
**Status:** 🔵 Discovery (depende de E3-S3)

## Por que não foi implementada agora

Esta story é construída em cima de **E3-S3 (Vínculo ref → mentorada)**, que está bloqueada por decisões de schema/canon.

Sem dados de quem-recebeu-qual-ref, não há base pra comparar.

## Pré-requisitos

- [ ] E3-S3 destravada e populada com dados reais por 30+ dias
- [ ] LLM API configurada (mesmo proxy de E4-S2)

## Spec preserved

Versão completa com algoritmo de diff, narrative LLM, UI lado-a-lado em `docs/stories/E4-S3-comparador-mentoradas.md`.

## Quando implementar

Após E3-S3 estar live + 30 dias de dados de vinculação.
