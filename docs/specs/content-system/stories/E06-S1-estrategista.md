---
id: E06-S1
title: "Agente 01 — Estrategista (tabela + view + RPC + página)"
type: story
epic: E06
status: Done
priority: P1
estimated_effort: L
date: 2026-05-12
owner: Kaique Rodrigues
depends_on: [E04-S1, E05-S1]
---

# Story E06-S1 — Agente 01: Estrategista Editorial

## Story

**Como** curador montando o calendário editorial de um cliente,
**eu quero** gerar um Plano Editorial com Banco de Ideias estruturado (cada ideia tem `insumo_publico` E `insumo_expert`),
**para que** nenhuma ideia entre no calendário sem fundação dupla (P6 do PRD).

## Acceptance Criteria

1. Migration `20260513003000_planos_editoriais.sql` cria `agente.planos_editoriais` conforme spec-tech §2.4.
2. Coluna `valido BOOLEAN GENERATED` é calculada automaticamente: `valido = true` quando `banco_ideias` é array não-vazio.
3. `fase` aceita apenas `'D+E' | 'VENDAS' | 'MISTO'` (CHECK constraint).
4. `mix_alvo` tem default `{"D_E":0.7,"C_I_D":0.3,"A":0.0}`.
5. View + RPC + página `/agentes/estrategista`.

## Tasks

- [x] Migration com `GENERATED` column (AC 1, 2)
- [x] CHECK constraint fase (AC 3)
- [x] Default mix_alvo (AC 4)
- [x] View + RPC + página (AC 5)

## Dev Notes

- A validação P6 (insumo_publico E insumo_expert preenchidos em cada ideia) **NÃO** é enforced no DB. O DB só garante que `banco_ideias` é array não-vazio. A semântica de cada item é checada no frontend (ou no Agente LLM quando V2 plugar).
- `out_valido` retornado pra UI sinalizar ao curador se o plano está OK ou marcado como inválido (banco_ideias vazio).

## Definition of Done

- [x] Frontend em prod
- [ ] Backend em prod (pendente Kaique aplicar SQL)
