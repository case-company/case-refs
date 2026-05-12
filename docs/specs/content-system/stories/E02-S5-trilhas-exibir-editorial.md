---
id: E02-S5
title: "/trilhas: exibir campos editoriais no card expandido"
type: story
epic: E02
status: Done (front em prod 2026-05-12)
priority: P0
estimated_effort: S
date: 2026-05-12
owner: Kaique Rodrigues
depends_on: [E02-S3]
---

# Story E02-S5 — /trilhas: exibir campos editoriais no card expandido

## Story

**Como** cliente da CASE consultando uma referência promovida,
**eu quero** ver uma seção "Guia de uso" com os 3 campos editoriais dentro do card expandido em `/trilhas`,
**para que** eu entenda imediatamente quando aquele post deveria ser usado, por que funciona e como adaptar — sem precisar perguntar à Queila.

## Acceptance Criteria

1. Card expandido em `/trilhas.html` ganha seção "Guia de uso" com 3 subtítulos: "Quando usar", "Por que funciona", "Como adaptar".
2. Conteúdo dos 3 campos renderizado a partir da resposta da view `v_referencias_publicas`.
3. Se os 3 campos vierem NULL (itens legados pré-E02), a seção inteira fica oculta — não renderiza placeholder de "campos vazios".
4. Se apenas 1-2 campos vierem NULL (caso transitório raro), os campos com valor são exibidos e os NULL omitidos individualmente.
5. Estilo CSS consistente com o resto do card (sem nova fonte/cor que destoa).
6. Mobile 375px: seção legível, sem overflow horizontal.

## Tasks

- [ ] Localizar template do card expandido em `trilhas.html` (AC 1)
- [ ] Adicionar bloco condicional: renderizar `<section class="guia-uso">` só se `item.quando_usar || item.por_que_funciona || item.como_adaptar` (AC 3)
- [ ] Cada subtítulo renderiza só se o respectivo campo é truthy após `trim()` (AC 4)
- [ ] Adicionar CSS para `.guia-uso` (header pequeno, parágrafos com line-height confortável) (AC 5)
- [ ] Smoke visual mobile (AC 6)

## Dev Notes

- `/trilhas.html` é estático mas faz fetch dinâmico via `_auth.js` ou cliente Supabase. Os 3 campos novos virão automaticamente após E02-S3 (whitelist atualizada).
- Cuidado com HTML escape: campos são `TEXT` livre — usar `textContent` em vez de `innerHTML` para evitar XSS.
- Não exibir campo `notas` (e a view nem retorna mais — a regra de segurança vem do DB).

## Testing

- Promover um item via E02-S4, abrir card em `/trilhas` → seção visível.
- Abrir card de item legado (pré-E02) → seção ausente.
- Mobile: 375px width.

## Definition of Done

- [ ] AC 1-6 verificados
- [ ] Commit `feat(trilhas): exibir guia de uso editorial no card expandido`
