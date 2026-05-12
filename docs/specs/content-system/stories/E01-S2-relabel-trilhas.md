---
id: E01-S2
title: "Relabel etapa_funil em /trilhas"
type: story
epic: E01
status: Draft
priority: P0
estimated_effort: S
date: 2026-05-12
owner: Kaique Rodrigues
depends_on: [E01-S1]
---

# Story E01-S2 — Relabel etapa_funil em /trilhas

## Story

**Como** cliente da CASE consultando o banco de referências,
**eu quero** ver "C+I+D" (Confiança · Identificação · Desejo) em vez de "Confiança" em todos os filtros e badges de `/trilhas`,
**para que** eu entenda que o bloco do meio do DECIDA cobre uma tripla (não só Confiança) e escolha conteúdo com base no critério certo.

## Acceptance Criteria

1. Página `/trilhas.html` exibe "C+I+D" no chip/filtro do bloco do meio em vez de "Confiança".
2. Tooltip ou hover do filtro exibe o `label_long` ("Confiança · Identificação · Desejo").
3. Filtro continua funcional: clicar em "C+I+D" mostra apenas itens com `etapa_funil = 'CONFIANCA'`.
4. Card expandido (quando aplicável) exibe a etapa usando o mesmo label.
5. Grep por `"Confiança"` em `trilhas.html` retorna zero ocorrências como label/badge/filtro.

## Tasks

- [ ] Importar `DECIDA_MAP` de `_decida.js` no `<script type="module">` de `trilhas.html` (AC 1, 5)
- [ ] Substituir strings hardcoded de etapa por leitura via `DECIDA_MAP[item.etapa_funil].label` (AC 1)
- [ ] Adicionar atributo `title` ou tooltip CSS com `label_long` no chip de filtro (AC 2)
- [ ] Validar manualmente que o filtro `?etapa=CONFIANCA` continua retornando os mesmos itens (AC 3)
- [ ] Conferir que card expandido usa o label novo (AC 4)
- [ ] Rodar `grep -n 'Confiança' trilhas.html` — deve retornar vazio (AC 5)

## Dev Notes

- `/trilhas.html` é o arquivo mais pesado do projeto (231KB). Cuidado com find-and-replace cego — `"Confiança"` pode aparecer em texto descritivo legítimo. Filtrar por contexto: `>Confiança<`, `label.*Confiança`, `'Confiança'`.
- Filtros do `/trilhas` usam `data-etapa` ou similar — preservar o **valor** (`CONFIANCA`) e mudar só o **texto exibido**.
- Esta story NÃO altera o schema do DB; nem RPCs; nem RLS.

## Testing

- Manual visual: smoke em `/trilhas`, filtrar pelas 3 etapas, verificar labels.
- Mobile (375px): conferir que chip "C+I+D" não quebra layout.

## Definition of Done

- [ ] AC 1-5 verificados em produção (Vercel deploy)
- [ ] Mobile testado em 375px
- [ ] Commit `feat(trilhas): relabel etapa CONFIANCA como C+I+D`
