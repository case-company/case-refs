---
id: E05-S1
title: "Agente 00.5 — Download do Expert (tabela + view + RPC + página)"
type: story
epic: E05
status: Done
priority: P1
estimated_effort: M
date: 2026-05-12
owner: Kaique Rodrigues
depends_on: [E04-S1]
---

# Story E05-S1 — Agente 00.5: Download do Expert

## Story

**Como** curador trabalhando o entendimento profundo do expert,
**eu quero** registrar o repositório de crenças/teses/provas/histórias/método/linguagem/fontes do expert vinculado a um Mapa de Interesse,
**para que** o Agente Estrategista (E06) tenha insumo_expert disponível para cada ideia gerada.

## Acceptance Criteria

1. Migration `20260513002000_downloads_expert.sql` cria `agente.downloads_expert` conforme spec-tech §2.3.
2. Foreign key `mapa_id` aponta pra `agente.mapas_interesse(id)` com `ON DELETE SET NULL` (não cascateia).
3. View `public.v_downloads_expert` expõe campos públicos.
4. RPC `case_agente_download_save` versiona por cliente_slug.
5. Página `/agentes/download-expert` com form de 7 blocos JSON.

## Tasks

- [x] Migration + FK + índices (AC 1, 2)
- [x] View + RPC (AC 3, 4)
- [x] Frontend (AC 5)

## Dev Notes

- `mapa_id` é opcional — permite criar Download "solto" (sem Mapa formal vinculado).
- 7 blocos: crencas/teses/provas/historias/metodo/linguagem/fontes (todos JSONB nullable).

## Definition of Done

- [x] Frontend em prod
- [x] Backend em prod (SQL aplicado 2026-05-12)
- [x] Smoke E2E PASS
