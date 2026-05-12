---
id: E03-S4
title: "Adicionar link 'Como usar' na navegação"
type: story
epic: E03
status: Done
priority: P0
estimated_effort: XS
date: 2026-05-12
owner: Kaique Rodrigues
depends_on: [E03-S1]
---

# Story E03-S4 — Adicionar link "Como usar" na navegação

## Story

**Como** cliente em qualquer página do site,
**eu quero** ter um link "Como usar" sempre visível no menu de navegação,
**para que** eu consiga voltar para o guia rápido a qualquer momento sem precisar lembrar a URL.

## Acceptance Criteria

1. Link "Como usar" presente no menu/header de: `index.html`, `trilhas.html`, `live.html`, `posts.html`, `dashboard.html`, `como-usar.html`.
2. Aponta para `/como-usar` (ou `/como-usar.html` se rewrite ainda não estiver).
3. Estilo consistente com os outros links de navegação (mesma fonte, cor, hover).
4. Ordem proposta no menu: `Trilhas | Como usar | Posts | Cadastre aqui`.
5. Em mobile 375px, link continua visível (sem hambúrguer dropdown — UX hoje é flat).
6. Não duplica links existentes nem quebra os já presentes (regressão).

## Tasks

- [ ] Identificar onde vive o markup do nav em cada HTML (provavelmente inline em cada arquivo, não compartilhado) (AC 1)
- [ ] Adicionar o link nos 6 arquivos (AC 1, 2)
- [ ] Conferir ordem proposta vs. existente — ajustar se Queila preferir outra (AC 4)
- [ ] Smoke visual desktop + mobile (AC 3, 5)
- [ ] Conferir que nenhum link existente sumiu (AC 6)

## Dev Notes

- Arquivos HTML são standalone — sem template engine. Cada nav é editado manualmente. Aceitar essa duplicação por enquanto (refactor para include é fora de escopo).
- Se em fase 2 vier um component-loader, fazer aí. Hoje a verdade é cópia-e-cola consciente.

## Testing

- Smoke manual: navegar entre páginas e conferir link presente.
- Mobile 375px.

## Definition of Done

- [ ] AC 1-6 verificados
- [ ] Commit `feat(nav): link 'Como usar' em todas as paginas`
