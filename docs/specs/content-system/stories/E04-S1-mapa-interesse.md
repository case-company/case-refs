---
id: E04-S1
title: "Agente 00 — Mapa de Interesse (tabela + view + RPC + página)"
type: story
epic: E04
status: Done
priority: P1
estimated_effort: M
date: 2026-05-12
owner: Kaique Rodrigues
---

# Story E04-S1 — Agente 00: Mapa de Interesse

## Story

**Como** curador iniciando o trabalho editorial para um cliente CASE,
**eu quero** registrar um Mapa de Interesse (público + oferta + sinais externos + 12 gavetas) e versionar por `cliente_slug`,
**para que** todo material editorial subsequente (Download do Expert, Plano, Roteiros) tenha a mesma fundação de entendimento do público.

## Acceptance Criteria

1. Migration `20260513001000_mapas_interesse.sql` cria `agente.mapas_interesse` com schema da spec-tech §2.2.
2. View `public.v_mapas_interesse` expõe todos os campos exceto `modelo_llm/prompt_versao/custo_usd/duracao_ms/deleted_at`.
3. RPC `public.case_agente_mapa_save(cliente_slug, titulo, publico, oferta, sinais, gavetas, top_assuntos)` cria nova versão (auto-increment) e retorna `out_id, out_versao`.
4. Página `/agentes/mapa-interesse` permite: criar novo (form com 7 campos), filtrar listagem por `cliente_slug`, expandir detalhes JSON.
5. Erros (cliente_slug vazio, título vazio) retornam mensagem inline sem reload.

## Tasks

- [x] Migration (AC 1, 2)
- [x] RPC com versionamento automático (AC 3)
- [x] HTML standalone reusando `_agente-styles.css` + `_agente-shared.js` (AC 4)
- [x] Validações client-side + server-side (AC 5)

## Dev Notes

- Versionamento: cada save com mesmo `cliente_slug` incrementa `versao` (1, 2, 3...).
- `UNIQUE (cliente_slug, versao)` no DB previne race.
- JSONB tolerante: campos vazios viram `{}` ou `null` no DB.
- Output `out_id/out_versao` em vez de `id/versao` pra evitar ambiguidade com colunas da tabela no RETURNING.

## Testing

- Smoke via curl direto contra `case_agente_mapa_save` RPC. Validar via REST GET em `v_mapas_interesse`.

## Definition of Done

- [x] AC 1-5 verificados
- [x] Frontend em prod (Vercel deploy automático)
- [x] Backend em prod (SQL aplicado via Dashboard 2026-05-12)
- [x] Smoke E2E PASS (curl → 200 + view retorna 1 row)
