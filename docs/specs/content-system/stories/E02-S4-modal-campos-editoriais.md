---
id: E02-S4
title: "Modal de promoção: 3 campos obrigatórios"
type: story
epic: E02
status: Review (front pronto, depende de E02-S1+S2+S3 aplicados em prod)
priority: P0
estimated_effort: M
date: 2026-05-12
owner: Kaique Rodrigues
depends_on: [E02-S2, E02-S3]
---

# Story E02-S4 — Modal de promoção: 3 campos obrigatórios

## Story

**Como** curador trabalhando no `/live`,
**eu quero** que o modal de promoção exija 3 textareas (quando_usar, por_que_funciona, como_adaptar) com placeholders orientativos antes de habilitar o botão "Promover",
**para que** seja impossível promover um item sem documentar a inteligência editorial.

## Acceptance Criteria

1. Modal expandido do `/live.html` ganha 3 textareas labeladas em PT-BR: "Quando usar", "Por que funciona", "Como adaptar".
2. Cada textarea tem placeholder orientativo (sugestão visível, conteúdo de exemplo).
3. Cada textarea exige >= 20 caracteres (validação client-side).
4. Botão "Promover" fica `disabled` até as 3 condições da AC 3 serem satisfeitas (contador visual opcional).
5. Submit chama `case-refs-mutate` com `op: "promote_editorial"` e os 3 campos (E02-S2).
6. Resposta 422 da Edge Function exibe mensagem de erro inline no modal (não silenciosa).
7. Após sucesso, modal fecha, item some do `/live` e refresh do `/trilhas` mostra o item.
8. Link "Guia DECIDA" visível no topo do modal (apontando para `guia-decida.md` ou rota equivalente).

## Tasks

- [ ] Localizar markup do modal em `live.html` (AC 1)
- [ ] Adicionar 3 textareas com `aria-required="true"` e maxlength razoável (AC 1, 2)
- [ ] Implementar listener `input` que recalcula estado do botão (AC 3, 4)
- [ ] Trocar fetch do submit para `op: "promote_editorial"` (AC 5)
- [ ] Tratar resposta não-200: exibir banner de erro com `body.error` e listar `body.fields` (AC 6)
- [ ] Validar lifecycle pós-sucesso: fechar modal, remover card do DOM do `/live`, opcional toast (AC 7)
- [ ] Adicionar link "Guia DECIDA" no header do modal (AC 8)

## Dev Notes

- Modal hoje está provavelmente inline em `live.html` (43KB). Refatoração para componente pode ser tentação — **fora de escopo**: manter inline, só estender.
- Placeholders sugeridos (validar com Queila):
  - "Quando usar": "Ex.: para momentos do calendário em que a audiência está fria, precisa entender o problema antes da oferta."
  - "Por que funciona": "Ex.: mistura prova social com vulnerabilidade, criando identificação rápida."
  - "Como adaptar": "Ex.: trocar o exemplo do gatilho 'fim de ano' por contexto da mentorada (ex.: agenda da clínica)."
- Acessibilidade: `<label for>` correto, mensagens de erro com `role="alert"`.

## Testing

- Manual: abrir item no `/live`, tentar promover sem campos → bloqueado. Preencher → habilita → 200 → item move para `/trilhas`.
- Tentar burlar via DevTools (remover `disabled`) → submit cai no 422 da Edge Function (defesa-em-profundidade da E02-S2).
- Mobile 375px: textareas não vazam fora da viewport.

## Definition of Done

- [ ] AC 1-8 verificados
- [ ] Test run anotado em `docs/specs/content-system/test-runs/` (AC final do epic)
- [ ] Commit `feat(live): modal de promoção com 3 campos editoriais obrigatórios`
