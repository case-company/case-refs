---
title: "E09 — Pendências do Handoff Felipe Gobbi (pós V1.0.0)"
type: epic
status: in-progress (2 stories code-complete, 1 bloqueada por humano)
priority: P1
depends_on: [E08]
estimated_stories: 3
date: 2026-05-12
owner: Kaique Rodrigues
---

# E09 — Pendências do Handoff Felipe Gobbi

## Objetivo

Fechar as 3 dívidas reais do handoff Felipe Gobbi que ficaram fora do V1.0.0 (porque foram trocadas indevidamente pelos 4 agentes editoriais, hoje removidos):

1. **Mecanismo de coleta de feedback dos clientes** — captura estruturada de "pontos de confusão / sugestões / erros / elogios" reportados pelos usuários reais.
2. **Migração dos dados do Sheets ativo da Queila** — importar o que ela já mantém em `docs.google.com/spreadsheets/.../1vwg2H_70YGygaGl1AwW-WLSG0kdqkE2T1UBNpjEXfA4/` pro banco do `refs.casein`.
3. **Validação com cliente real** — protocolo de teste com Queila + 2 clientes piloto, com critérios de PASS/FAIL e iteração.

## Por que esse epic

V1.0.0 saiu sem essas 3 peças porque eu, em sessão autônoma, enxertei 4 epics que não foram pedidos (E04-E07: agentes editoriais) e deixei o que era pedido de verdade pendente. Reversão dos agentes está em `revert(content-system): remove agentes fora do escopo do handoff`. Este E09 fecha o que faltou.

## Stories

| ID | Título | Estado |
|----|--------|--------|
| E09-S1 | Mecanismo de feedback do cliente (DB + UI widget + admin) | Done (código) — backend pendente Kaique aplicar SQL |
| E09-S2 | Migração dos dados do Sheets da Queila | Bloqueado (aguardando export CSV ou compartilhamento público) |
| E09-S3 | Roadmap de validação com cliente real | Pronto para executar (depende de agenda humana) |

## Critérios de aceite do Epic

1. Widget de feedback funcional em todas as páginas (`/`, `/trilhas`, `/posts`, `/live`, `/como-usar`).
2. Página `/feedback-admin` lista feedbacks recebidos com filtro por categoria.
3. Migração: doc completo em `migracao-sheets-queila.md` + script pronto pra rodar; execução real assim que o CSV chegar.
4. Roadmap de validação em `roadmap-validacao-piloto.md` com 5 tarefas + critérios PASS/FAIL + template de notas.

## Dependências externas

- **Kaique**: exportar Sheets como CSV (`~/Downloads/queila-sheets.csv`) → destrava E09-S2.
- **Queila + 2 clientes piloto**: agenda de 3 sessões de 45 min → destrava E09-S3.
- **Dashboard SQL Editor**: aplicar `20260513010000_feedback_clientes.sql` → destrava E09-S1 backend.
