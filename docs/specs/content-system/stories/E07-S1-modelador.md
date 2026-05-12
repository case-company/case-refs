---
id: E07-S1
title: "Agente 02 — Modelador (tabela + view + RPC + página)"
type: story
epic: E07
status: Done
priority: P2
estimated_effort: M
date: 2026-05-12
owner: Kaique Rodrigues
depends_on: [E06-S1]
---

# Story E07-S1 — Agente 02: Modelador de Referências

## Story

**Como** curador transformando uma referência em roteiro adaptado,
**eu quero** produzir um roteiro que preserva a estrutura da referência e adapta o conteúdo ao contexto do cliente,
**para que** o output mantenha o princípio P5 (estrutura se copia, conteúdo não).

## Acceptance Criteria

1. Migration `20260513004000_roteiros_modelados.sql` cria `agente.roteiros_modelados` conforme spec-tech §2.5.
2. `formato_visual` é restrito (CHECK) a `'reel'|'carrossel'|'story'|'live'|'post_estatico'|'video_longo'`.
3. CHECK constraint exige `referencia_id IS NOT NULL OR referencia_url IS NOT NULL`.
4. Status lifecycle: `draft → aprovado → publicado → arquivado`.
5. Página `/agentes/modelador` com dropdown que carrega itens de `v_referencias_promovidas` (link banco) + fallback de URL solta.
6. Página exibe separadamente `estrutura` (esqueleto preservado) e `roteiro` (conteúdo novo) para reforçar visualmente P5.

## Tasks

- [x] Migration + CHECK constraints (AC 1, 2, 3)
- [x] Status lifecycle (AC 4)
- [x] Página com dropdown de referências (AC 5)
- [x] Renderização separada estrutura/roteiro (AC 6 — via `<details>` colapsável)

## Dev Notes

- Como o Modelador usa referências do banco, é o único agente que faz JOIN com `referencias_conteudo` (via FK opcional `referencia_id`).
- `referencia_url` permite trabalhar com referências externas (ex: Instagram de outro perfil que ainda não está promovido no banco).

## Definition of Done

- [x] Frontend em prod
- [x] Backend em prod (SQL aplicado 2026-05-12)
- [x] Smoke E2E PASS (referencia_url + plano_id encadeado)
