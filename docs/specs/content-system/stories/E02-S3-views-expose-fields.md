---
id: E02-S3
title: "Views: expor campos editoriais sem `notas`"
type: story
epic: E02
status: Done (aplicada em prod via Dashboard 2026-05-12)
priority: P0
estimated_effort: S
date: 2026-05-12
owner: Kaique Rodrigues
depends_on: [E02-S1]
---

# Story E02-S3 — Views: expor campos editoriais sem `notas`

## Story

**Como** frontend do `/trilhas`,
**eu quero** consultar `v_referencias_publicas` e receber os 3 campos editoriais junto com os campos atuais,
**para que** o card expandido (E02-S5) consiga renderizar a seção "Guia de uso" sem fazer round-trip extra.

## Acceptance Criteria

1. Migration `20260513000100_views_expose_editorial.sql` criada — sucessora da safe-view (`20260512200000_safe_view_no_notas.sql`).
2. `v_referencias_publicas` mantém whitelist explícita; adiciona `quando_usar`, `por_que_funciona`, `como_adaptar`, `objetivo`. **`notas` permanece de fora.**
3. View nova `v_referencias_promovidas` criada com mesma whitelist (sem `notas`) e filtro `promoted_at IS NOT NULL`, `ORDER BY promoted_at DESC`.
4. `GRANT SELECT ON v_referencias_promovidas TO anon, authenticated` aplicado.
5. Smoke staging: `SELECT * FROM v_referencias_publicas LIMIT 1` retorna os novos campos no schema.
6. Smoke staging: `SELECT * FROM v_referencias_promovidas` retorna apenas itens com `promoted_at` setado.
7. Conferência manual: `SELECT column_name FROM information_schema.columns WHERE table_name = 'v_referencias_publicas'` não inclui `notas`.

## Tasks

- [ ] Escrever a migration combinando spec-tech §2.1 + safe-view pattern (AC 1, 2, 3)
- [ ] Garantir GRANT (AC 4)
- [ ] Aplicar em staging (AC 5, 6, 7)
- [ ] Aplicar em produção
- [ ] Atualizar comment da view explicando a regra "nunca expor `notas`" (mantém a invariante de segurança)

## Dev Notes

- Esta story **substitui** a view criada pela safe-view migration (`20260512200000`). O `CREATE OR REPLACE` é idempotente — sem necessidade de DROP.
- Ordem das colunas na whitelist segue a spec-tech §2.1 atualizada (sem `notas`).
- Anti-regressão: se algum dev futuro for tentado a fazer `SELECT *` na view, o COMMENT da view tem que alertar.

## Testing

- Staging: aplicar migration, rodar 3 queries de smoke (AC 5, 6, 7).
- Prod: aplicar migration, conferir que `/trilhas` continua carregando (a UI ainda não usa os campos novos, mas não pode quebrar).

## Definition of Done

- [ ] AC 1-7 verificados
- [ ] Commit `feat(db): views expoem campos editoriais (sem notas)`
