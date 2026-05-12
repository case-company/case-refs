---
id: E03-S2
title: "Tour de primeira visita via localStorage"
type: story
epic: E03
status: Done
priority: P0
estimated_effort: M
date: 2026-05-12
owner: Kaique Rodrigues
depends_on: [E03-S1]
---

# Story E03-S2 — Tour de primeira visita via localStorage

## Story

**Como** cliente acessando `refs.casein.com.br` pela primeira vez,
**eu quero** ver uma sequência de 3-4 tooltips explicando filtro DECIDA, card expandido e badge de curadoria,
**para que** eu entenda o uso sem ler o `/como-usar` antes — e que o tour não me incomode em visitas seguintes.

## Acceptance Criteria

1. Tour ativado na primeira visita a `/trilhas` (flag `caso-ref-toured` ausente do localStorage).
2. Tour tem 3-4 etapas, cada uma destacando um elemento da UI:
   - (a) Filtro por etapa DECIDA
   - (b) Card colapsado → "clique para expandir"
   - (c) Seção "Guia de uso" dentro do card expandido
   - (d) Badge "⏳ pendente curadoria" (em `/live` — opcional)
3. Cada step tem botão "Próximo" e "Pular tour".
4. Ao concluir ou pular: flag `caso-ref-toured = 'v1'` setada em localStorage.
5. Em visitas subsequentes, tour não reaparece.
6. Tour pode ser re-disparado manualmente via query string `?tour=1` (para QA e re-onboarding intencional).
7. CSS do tour não vaza para o restante do site (escopo via `[data-tour]` ou classe própria).
8. Mobile 375px: tooltips legíveis e posicionados sem cortar.

## Tasks

- [ ] Implementar componente vanilla JS de tour (sem dependência externa) (AC 1, 2)
- [ ] Adicionar marcadores `data-tour-step="1..4"` nos elementos relevantes em `trilhas.html` (e talvez `live.html` para step 4) (AC 2)
- [ ] Lógica de localStorage flag (AC 1, 4, 5)
- [ ] Query string override `?tour=1` (AC 6)
- [ ] CSS escoped do tour (AC 7)
- [ ] Smoke mobile (AC 8)

## Dev Notes

- Implementação simples preferível: tooltip absoluto posicionado por JS calculando bounding box do alvo. ~80-100 linhas de JS sem framework.
- Acessibilidade: `role="dialog"`, `aria-modal="true"`, focus trap não obrigatório nesta versão (re-avaliar se reclamarem).
- Anti-pattern: NÃO trazer libs tipo Shepherd/Intro.js — overhead pra projeto estático.

## Testing

- Manual: limpar localStorage, acessar `/trilhas`, percorrer tour, fechar — recarregar e confirmar que não aparece.
- `?tour=1` força reaparição.
- Mobile 375px.

## Definition of Done

- [ ] AC 1-8 verificados
- [ ] Commit `feat(trilhas): tour de primeira visita via localStorage`
