---
id: E01-S3
title: "Relabel etapa_funil em /live e modal de promoção"
type: story
epic: E01
status: Done
priority: P0
estimated_effort: S
date: 2026-05-12
owner: Kaique Rodrigues
depends_on: [E01-S1]
---

# Story E01-S3 — Relabel etapa_funil em /live e modal de promoção

## Story

**Como** curador trabalhando no fluxo de promoção (`/live` → `/trilhas`),
**eu quero** ver o vocabulário DECIDA ("C+I+D") em badges, selects e formulários do `/live` e do modal expandido,
**para que** eu use o mesmo critério de classificação que o cliente vai ver depois — sem ambiguidade entre "Confiança" e "C+I+D".

## Acceptance Criteria

1. Página `/live.html` exibe "C+I+D" em badges, selects e qualquer texto de etapa em vez de "Confiança".
2. Modal expandido (quando aberto via clique em item do `/live`) exibe etapa via `DECIDA_MAP[item.etapa_funil].label`.
3. Se houver `<select>` para curador escolher etapa, as `option` exibem `label` mas mantêm `value` igual ao enum DB.
4. `/dashboard.html` (página de curadoria escondida) também relabelada.
5. Grep por `"Confiança"` em `live.html` e `dashboard.html` retorna zero ocorrências como label/badge/option.

## Tasks

- [ ] Importar `DECIDA_MAP` em `live.html` (AC 1, 5)
- [ ] Substituir strings hardcoded de etapa em badges e selects (AC 1, 3)
- [ ] Mesma operação em `dashboard.html` (AC 4, 5)
- [ ] Conferir modal expandido (provavelmente compartilha código com /trilhas) (AC 2)
- [ ] Lint guard: `grep -n 'Confiança' live.html dashboard.html` retorna vazio (AC 5)

## Dev Notes

- `live.html` tem 43KB; `dashboard.html` tem 11KB. Mais leve que `/trilhas` mas mesmo cuidado contextual.
- Em `<select>`, garantir que o `value` da option NÃO mude (deve continuar `CONFIANCA` para o filtro funcionar).
- O modal de promoção desta story exibe etapa SOMENTE como leitura. O E02 (`S2.4-modal-campos-editoriais`) é quem adiciona os 3 campos editoriais ao modal.

## Testing

- Manual: abrir `/live`, filtrar por etapa, abrir modal expandido — verificar label.
- Manual: abrir `/dashboard`, conferir badges e selects.
- Smoke: criar uma promoção de teste no `/live` para garantir que o `value` enum não foi corrompido.

## Definition of Done

- [ ] AC 1-5 verificados em produção
- [ ] Commit `feat(live,dashboard): relabel etapa CONFIANCA como C+I+D`
