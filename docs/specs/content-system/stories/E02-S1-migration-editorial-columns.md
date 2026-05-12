---
id: E02-S1
title: "Migration: adicionar 3 colunas editoriais"
type: story
epic: E02
status: Done (aplicada em prod via Dashboard SQL Editor 2026-05-12)
priority: P0
estimated_effort: S
date: 2026-05-12
owner: Kaique Rodrigues
depends_on: [E01-S5]
---

# Story E02-S1 — Migration: adicionar 3 colunas editoriais

## Story

**Como** mantenedor do schema Supabase do `refs.casein.com.br`,
**eu quero** adicionar as colunas `quando_usar`, `por_que_funciona`, `como_adaptar` e `objetivo` à tabela `agente.referencias_conteudo` via migration idempotente,
**para que** o fluxo de promoção possa exigir esses campos sem reescrever schema depois e itens legados continuem funcionando com valores NULL.

## Acceptance Criteria

1. Migration `supabase/migrations/20260513000000_referencias_conteudo_editorial_fields.sql` criada conforme spec-tech §2.1.
2. As 4 colunas adicionadas como `TEXT` nullable: `quando_usar`, `por_que_funciona`, `como_adaptar`, `objetivo`.
3. Constraint `chk_promoted_requires_editorial_fields` adicionada: linha promovida (`promoted_at IS NOT NULL`) precisa ter os 3 campos editoriais não-vazios e com `char_length >= 20` cada.
4. Constraint **NÃO** se aplica a linhas já promovidas antes da migration (cláusula `NOT VALID` ou estratégia equivalente — itens legados permanecem como estão).
5. Índice `idx_refs_objetivo` e `idx_refs_etapa_promoted` criados.
6. Migration aplicada em staging via `supabase db push` sem erro.
7. Aplicação em produção via mesmo comando, com backup `pg_dump` salvo antes.

## Tasks

- [ ] Escrever a migration conforme spec-tech (AC 1, 2, 3, 5)
- [ ] Resolver a tensão da constraint em itens legados: aplicar `NOT VALID` + `VALIDATE CONSTRAINT` futuro só após backfill, OU usar `WHERE promoted_at > 'data_migration'` no CHECK (AC 4)
- [ ] Aplicar em branch staging do Supabase (AC 6)
- [ ] Smoke: tentar inserir linha promovida sem `quando_usar` — deve falhar (AC 3)
- [ ] Smoke: tentar atualizar linha legada (promovida antes) — deve passar (AC 4)
- [ ] Salvar backup `pg_dump` antes de aplicar em prod (AC 7)
- [ ] Aplicar em prod (AC 7)

## Dev Notes

- A spec-tech tem o SQL pronto em `02-spec-tech.md §2.1` — copiar literalmente, ajustando só a estratégia de constraint para legados.
- Estratégia preferida para AC 4: adicionar a constraint `NOT VALID` (Postgres permite — não aplica retroativamente). Em fase futura quando todos os itens promovidos tiverem os campos, rodar `ALTER TABLE ... VALIDATE CONSTRAINT`.
- **NÃO mudar** a view `v_referencias_publicas` aqui — isso é a E02-S3 (e a safe-view já foi aplicada).
- View `v_referencias_promovidas` é criada também na S3.

## Testing

- Smoke staging: INSERT/UPDATE conforme AC 3, 4.
- Verificar lock contention: tabela tem ~75 itens promovidos, ALTER TABLE deve ser instantâneo. Sem necessidade de janela de manutenção.

## Definition of Done

- [ ] AC 1-7 verificados
- [ ] `pg_dump` salvo em local seguro (não no repo)
- [ ] Commit `feat(db): colunas editoriais quando_usar/por_que_funciona/como_adaptar/objetivo`
