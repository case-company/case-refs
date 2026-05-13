---
id: E09-S3
title: "Validação com cliente real — protocolo + execução"
type: story
epic: E09
status: Ready (depende de agenda humana — Queila + 2 clientes)
priority: P1
estimated_effort: M (3 sessões de 45 min cada + análise)
date: 2026-05-12
owner: Kaique Rodrigues
---

# Story E09-S3 — Validação com cliente real

## Story

**Como** Kaique fechando o handoff Felipe Gobbi,
**eu quero** rodar 3 sessões de validação (Queila + 2 clientes piloto) com 5 tarefas pré-definidas e critérios PASS/FAIL,
**para que** o V1.0.0 seja validado em uso real — não pelo smoke automatizado meu de 2026-05-12 que só prova que a stack tá viva.

## Acceptance Criteria

1. Roadmap `roadmap-validacao-piloto.md` no repo com protocolo completo: participantes, 5 tarefas, critérios PASS/FAIL, template de notas.
2. 3 sessões executadas (1 com Queila, 2 com clientes).
3. 3 test-runs `test-runs/piloto-<nome>-<data>.md` salvos.
4. Veredito agregado em `test-runs/piloto-veredito-<data>.md`.
5. Para cada FAIL, issue/story aberta com prefixo `piloto-fix-`.
6. Para cada feedback capturado via widget durante o piloto, triagem em ≤ 72h.

## Tasks

- [x] Doc `roadmap-validacao-piloto.md` com protocolo (5 tarefas + critérios + template).
- [ ] Kaique agendar 3 slots (sugestão: spread em 5 dias úteis).
- [ ] Executar sessão 1 (Queila).
- [ ] Executar sessão 2 (cliente piloto 1).
- [ ] Executar sessão 3 (cliente piloto 2).
- [ ] Consolidar veredito.
- [ ] Triar feedback capturado via widget durante o período.
- [ ] Abrir issues `piloto-fix-*` se houver.

## Critérios PASS/FAIL do piloto inteiro

V1.0.0 passa se:
- ≥ 4 de 5 tarefas com PASS em pelo menos 2 das 3 sessões.
- **0 FAIL na tarefa 4 (gatekeeper editorial — Queila)** — não-negociável.
- ≥ 1 feedback espontâneo positivo via widget durante o piloto.
- ≤ 3 tipos distintos de fricção identificados.

Se reprovar, mapping de epic pra reabrir está no `roadmap-validacao-piloto.md` §4.

## Dev Notes

- Sessões são presenciais ou por vídeo com gravação (ZOOM/Meet). Tema da gravação: só o uso do site (não a pessoa).
- Observador (Kaique) anota, não interfere durante o think-aloud.
- Entrevista pós-tarefa cobre: o que confundiu, o que voltaria, indicaria pra um amigo.

## Definition of Done

- [ ] AC 1-6 verificados
- [ ] Commit `chore(content-system): piloto V1 — veredito + issues`
