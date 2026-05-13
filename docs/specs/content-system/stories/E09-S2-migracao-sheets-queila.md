---
id: E09-S2
title: "Migração dos dados do Sheets ativo da Queila"
type: story
epic: E09
status: Blocked (aguardando export CSV ou tornar Sheets público)
priority: P1
estimated_effort: S (depois de destravado)
date: 2026-05-12
owner: Kaique Rodrigues
---

# Story E09-S2 — Migração Sheets Queila

## Story

**Como** Kaique fechando o handoff Felipe Gobbi,
**eu quero** importar o conteúdo que a Queila já vinha mantendo no Sheets ativo para `agente.referencias_conteudo`,
**para que** o banco `refs.casein` reflita o conhecimento acumulado e a Queila não precise re-cadastrar manualmente.

## Acceptance Criteria

1. Documento `migracao-sheets-queila.md` com mapping de schemas + script Node + checklist de pré-checagens.
2. Script `import-queila-sheets.mjs` pronto pra rodar (descrito no doc, criado quando CSV chegar).
3. Import roda em modo `--dry-run` primeiro, gera relatório (count + sample).
4. Após aprovação Kaique, import real com flag `--commit`.
5. Itens importados marcados com `origem = 'import_queila_sheets_2026-05-12'` pra rastreio.
6. Promoção fica em humano: import entra como `promoted_at IS NULL` — vai pra `/live`.

## Tasks

- [x] Tentar acessar Sheets via export CSV public → HTTP 400 (Sheets não é público).
- [x] Doc `migracao-sheets-queila.md` com plano + script + risk matrix.
- [ ] Kaique exportar Sheets → `~/Downloads/queila-sheets.csv`.
- [ ] Ajustar `mapRow()` no script conforme schema real do Sheets.
- [ ] Rodar `--dry-run` → relatório.
- [ ] Rodar import real.
- [ ] Smoke spot check (3 itens random no `/live`).

## Bloqueio atual

Sheets `1vwg2H_70YGygaGl1AwW-WLSG0kdqkE2T1UBNpjEXfA4` não está com link público. Opções pra destravar:

- (a) Kaique exporta como CSV → coloca em `~/Downloads/queila-sheets.csv`. ✅ Mais rápido.
- (b) Tornar Sheets "Anyone with the link → Viewer".
- (c) Compartilhar com service account Supabase (overkill).

## Dev Notes

- Schema real do Sheets é hipotético no doc — só validamos quando o CSV chegar.
- `normalizeTrilha()` e `normalizeEtapa()` cobrem variações (Clinica/clinic, Confiança/C+I+D/CID, Ação/A).
- Dedup por `shortcode` evita re-import de itens que já estão no banco vindos da curadoria inicial.

## Definition of Done

- [ ] AC 1-6 verificados
- [ ] Commit `feat(content-system): import sheets queila — N itens`
- [ ] Relatório no test-run anexado
