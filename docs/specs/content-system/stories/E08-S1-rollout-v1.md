---
id: E08-S1
title: "V1 Rollout — release notes + smoke pós-deploy + métricas baseline"
type: story
epic: E08
status: Done
priority: P0
estimated_effort: S
date: 2026-05-12
owner: Kaique Rodrigues
depends_on: [E01, E02, E03, E04-S1, E05-S1, E06-S1, E07-S1]
---

# Story E08-S1 — V1 Rollout

## Story

**Como** Kaique fechando o V1 do Content System CASE,
**eu quero** um release notes consolidado + checklist pós-deploy + baseline de métricas que permita medir adoção,
**para que** V1.5 (refinamento) tenha base concreta pra decidir o que vale otimizar.

## Acceptance Criteria

1. `docs/specs/content-system/CHANGELOG.md` criado com seções `[1.0.0] — 2026-05-12 — V1 Release` listando todas as features entregues + bugs corrigidos.
2. `docs/specs/content-system/test-runs/` tem ao menos 1 smoke run PASS por agente (`E04`, `E05`, `E06`, `E07`).
3. Checklist de sanidade pós-deploy executada (ver Tasks abaixo).
4. Baseline de uso registrada: contagem de itens em `agente.referencias_conteudo` (promovidos vs pendentes) no dia do release.
5. README do `content-system/` lista o V1 como "released" com data e link pro CHANGELOG.

## Tasks

- [x] Redigir CHANGELOG.md
- [x] Smoke E2E real de cada um dos 4 agentes via curl (test-runs/E04-E07-agentes-smoke-2026-05-12.md PASS)
- [x] Verificar links de navegação em todas as páginas (todas atualizadas com nav 'Agentes')
- [x] Query baseline: contagem de itens promovidos via E02 (smoke test-run em test-runs/E02-smoke-2026-05-12.md)
- [x] Atualizar README com data + status released (1.0.0 — 2026-05-12)

## Dev Notes

- O smoke E2E dos agentes é simétrico ao do E02 (que já passou): tentar save sem campos obrigatórios → erro semântico; save válido → 200 + id + versao; GET na view → confirmar campos.
- A constraint `chk_promoted_requires_editorial_fields` é só de E02 (referencias_conteudo). Os agentes têm validações próprias via RAISE EXCEPTION nas RPCs — não usam CHECK constraints rígidas.

## Definition of Done

- [ ] AC 1-5 verificados
- [ ] Commit `chore(content-system): V1 release`
