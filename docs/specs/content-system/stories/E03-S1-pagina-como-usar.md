---
id: E03-S1
title: "Criar /como-usar.html"
type: story
epic: E03
status: Draft
priority: P0
estimated_effort: M
date: 2026-05-12
owner: Kaique Rodrigues
depends_on: [E01-S4]
---

# Story E03-S1 — Criar /como-usar.html

## Story

**Como** cliente novo da CASE acessando `refs.casein.com.br` pela primeira vez,
**eu quero** uma página estática `/como-usar` com 5 blocos explicando o método DECIDA e como navegar o site,
**para que** eu consiga me virar sozinho sem precisar de call de onboarding.

## Acceptance Criteria

1. Arquivo `como-usar.html` criado na raiz do projeto, no mesmo padrão estático de `trilhas.html` / `live.html`.
2. Estrutura da página com 5 blocos:
   - **Bloco 1**: O que é DECIDA (texto curto, 1 parágrafo)
   - **Bloco 2**: Os 3 grupos (D+E / C+I+D / A) com regra de mix 70/30/0-10
   - **Bloco 3**: Como navegar `/trilhas` (explicação do filtro, do card expandido)
   - **Bloco 4**: O que são os 3 campos editoriais (quando_usar / por_que_funciona / como_adaptar)
   - **Bloco 5**: Links — para `guia-decida.md`, para `/trilhas`, para `/posts`
3. Página 100% estática — zero chamadas a Supabase / Edge Function.
4. Reutiliza CSS existente do site (sem variáveis novas, sem novas fontes).
5. Responsiva em mobile 375px e desktop 1280px.
6. Linkada como `/como-usar` (sem `.html` na URL via `vercel.json` rewrite ou direto pelo Vercel).

## Tasks

- [ ] Criar `como-usar.html` reusando `<head>` e header de `trilhas.html` (AC 1, 4)
- [ ] Redigir os 5 blocos com base em `guia-decida.md` (AC 2)
- [ ] Validar visual em duas larguras (AC 5)
- [ ] Conferir rewrite no `vercel.json` ou ajustar (AC 6)

## Dev Notes

- `vercel.json` atual tem 50 bytes — provavelmente só `{ "cleanUrls": true }` ou similar. Conferir antes de assumir comportamento de rewrite.
- Conteúdo dos blocos vem do `guia-decida.md` (E01-S4): esta página é a **versão visual** do guia, com mais espaçamento e CTA. O `.md` continua sendo a fonte canônica em prosa longa.
- Anti-pattern: não inserir tour aqui (tour vive na E03-S2 como overlay sobre `/trilhas`).
- Anti-pattern: não inserir formulário de captura/email (fora de escopo, sem motivo de negócio agora).

## Testing

- Manual: abrir `/como-usar` em mobile e desktop.
- Lighthouse opcional para sanity (CLS, FID).

## Definition of Done

- [ ] AC 1-6 verificados em produção
- [ ] Commit `feat(content-system): pagina /como-usar estatica`
