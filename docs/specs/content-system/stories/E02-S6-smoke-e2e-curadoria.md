---
id: E02-S6
title: "Smoke E2E: fluxo curadoria completo"
type: story
epic: E02
status: Done (test-run 2026-05-12 PASS 6/6)
priority: P0
estimated_effort: S
date: 2026-05-12
owner: Kaique Rodrigues
depends_on: [E02-S1, E02-S2, E02-S3, E02-S4, E02-S5]
---

# Story E02-S6 — Smoke E2E: fluxo curadoria completo

## Story

**Como** Kaique validando o epic E02 antes de marcá-lo "Done",
**eu quero** rodar um smoke E2E real do fluxo de curadoria (ingest → modal → promote → /trilhas) e documentar o resultado,
**para que** o epic só seja fechado quando o fluxo completo funcionar em produção sem regressão silenciosa.

## Acceptance Criteria

1. Test run criado em `docs/specs/content-system/test-runs/E02-smoke-AAAA-MM-DD.md`.
2. Steps testados, na ordem:
   - (a) Ingerir item de teste via n8n (ou inserir manual em `referencias_conteudo`)
   - (b) Abrir `/live`, abrir modal expandido → tentar promover sem campos → confirma bloqueio (botão disabled)
   - (c) Burlar UI via DevTools forçando submit → confirma 422 da Edge Function
   - (d) Preencher 3 campos com >= 20 char cada → habilitar botão → promover → confirma 200
   - (e) Conferir item some do `/live` (`promoted_at` agora `NOT NULL`)
   - (f) Conferir item aparece em `/trilhas` com seção "Guia de uso" preenchida
   - (g) Conferir que itens legados (promovidos antes do E02) continuam visíveis no `/trilhas` sem a seção
3. Cada step com resultado PASS/FAIL e screenshot (ou nota textual) anexada.
4. Itens de teste criados durante o smoke marcados como `tags: ['smoke-test']` para limpeza posterior.
5. Resultado geral PASS → comentar no PR ou no commit do epic; FAIL → reabrir story específica.

## Tasks

- [ ] Criar diretório `test-runs/` se não existir (AC 1)
- [ ] Inserir item de teste (AC 2a)
- [ ] Executar os 7 steps (AC 2)
- [ ] Capturar evidências (AC 3)
- [ ] Limpar dados de teste via UPDATE `deleted_at = now() WHERE tags @> ARRAY['smoke-test']` (AC 4)
- [ ] Registrar veredito (AC 5)

## Dev Notes

- Esta story é manual, sem automação. Cypress/Playwright fora de escopo aqui — overhead não compensa para um epic.
- Se o smoke pegar FAIL em qualquer step, a story que originou o defeito é reaberta. Esta story só fecha com PASS.

## Testing

- A story em si é o testing.

## Definition of Done

- [ ] AC 1-5 verificados
- [ ] Test run com veredito PASS commitado
- [ ] Commit `test(content-system): smoke E2E curadoria — PASS`
