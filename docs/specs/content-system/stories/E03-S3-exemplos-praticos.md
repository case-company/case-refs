---
id: E03-S3
title: "Seção de exemplos práticos na /como-usar"
type: story
epic: E03
status: Done (Queila optou por não refinar — exemplos genéricos no /como-usar.html ficam como entregue)
priority: P0
estimated_effort: M
date: 2026-05-12
owner: Kaique Rodrigues
depends_on: [E03-S1, E02-S5]
---

# Story E03-S3 — Seção de exemplos práticos na /como-usar

## Story

**Como** cliente lendo `/como-usar`,
**eu quero** ver pelo menos 6 exemplos reais (2 por bloco DECIDA) mostrando o tipo de post e como os 3 campos editoriais seriam preenchidos,
**para que** eu enxergue o método aplicado e não fique no abstrato.

## Acceptance Criteria

1. Bloco "Exemplos" adicionado em `como-usar.html`, antes do bloco de "Links".
2. 6+ exemplos divididos em 3 grupos (D+E, C+I+D, A), 2+ por grupo.
3. Cada exemplo contém:
   - tipo de post (Reels / Carrossel / Foto / etc.)
   - etapa DECIDA com badge visual
   - descrição curta do conteúdo (sem screenshot — usar texto)
   - exemplo de preenchimento dos 3 campos editoriais (quando_usar / por_que_funciona / como_adaptar)
4. Conteúdo dos exemplos baseado em itens **reais** já no banco — texto estático extraído manualmente (não fetch dinâmico).
5. Revisão e aprovação da Queila documentada em rodapé do bloco ou no commit.
6. Mobile 375px: cards de exemplo legíveis, sem overflow.

## Tasks

- [ ] Extrair 6+ itens reais do banco (`SELECT id, etapa_funil, caption, titulo FROM v_referencias_promovidas WHERE etapa_funil IN ('DESCOBERTA','CONFIANCA','ACAO') LIMIT 10`) (AC 4)
- [ ] Para cada exemplo, redigir os 3 campos editoriais — usar entradas reais quando existirem, ou redigir alinhado com a voz da Queila (AC 3)
- [ ] Inserir markup em `como-usar.html` (AC 1, 2, 3)
- [ ] Submeter à Queila e registrar OK (AC 5)
- [ ] Smoke mobile (AC 6)

## Dev Notes

- Conteúdo estático (HTML inline) — fácil de manter, sem risco de desatualizar com banco. Se algum item for removido do banco, o exemplo na página não quebra.
- Mantemos referência ao ID do item no banco como comentário HTML (`<!-- ref-id: 42 -->`) para rastreio.
- Anti-pattern: NÃO inserir anglicismos nos campos exemplo. Auto-grep `framework|pipeline|onboarding`.

## Testing

- Aprovação Queila (humano gate).
- Auto-grep anti-jargão.
- Mobile 375px.

## Definition of Done

- [ ] AC 1-6 verificados
- [ ] Aprovação Queila registrada
- [ ] Commit `feat(content-system): exemplos praticos em /como-usar`
