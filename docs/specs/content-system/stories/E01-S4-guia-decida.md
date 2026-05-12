---
id: E01-S4
title: "Redigir guia-decida.md cliente-facing"
type: story
epic: E01
status: Review (draft pronto, pendente aprovação Queila)
priority: P0
estimated_effort: M
date: 2026-05-12
owner: Kaique Rodrigues
---

# Story E01-S4 — Redigir guia-decida.md cliente-facing

## Story

**Como** cliente novo da CASE acessando o banco de referências pela primeira vez,
**eu quero** um documento curto e claro explicando o método DECIDA, a regra de mix 70/30/0-10 e o que cada bloco quer dizer,
**para que** eu consiga consumir o banco de referências sem precisar de call de onboarding com a Queila.

## Acceptance Criteria

1. Arquivo `docs/specs/content-system/guia-decida.md` criado com 5 seções: (1) O que é DECIDA, (2) Os 3 blocos (D+E, C+I+D, A), (3) Regra de mix 70/30/0-10, (4) Erros comuns, (5) Como aplicar no calendário editorial.
2. Para cada bloco, ao menos 1 exemplo concreto de post (descrição, não screenshot).
3. Texto em PT-BR, tom consultivo (não tutorial-passo-a-passo).
4. Frontmatter YAML com `title`, `type: guide`, `audience: cliente`, `status`, `date`, `owner`.
5. Linkado a partir do README do `content-system/` para descoberta.
6. Conteúdo aprovado pela Queila (registrado em changelog ou comment no arquivo).

## Tasks

- [ ] Triangular conteúdo do guia com: (a) material da Queila em `~/Downloads/copia projeto agentes`, (b) ADR-0001, (c) handoff Felipe Gobbi em `00-context-and-handoff.md` (AC 1)
- [ ] Redigir as 5 seções no documento (AC 1, 2, 3)
- [ ] Adicionar frontmatter YAML (AC 4)
- [ ] Atualizar `docs/specs/content-system/README.md` (criar se não existir) listando o guia (AC 5)
- [ ] Submeter à Queila para revisão; registrar aprovação no rodapé do arquivo (AC 6)

## Dev Notes

- Este documento será linkado pela página `/como-usar.html` da E03 — o link estará em produção para clientes, então o texto precisa ser **público-friendly**, não jargão interno.
- Anti-pattern: NÃO criar acrônimo expandido confuso. DECIDA já é familiar para a Queila — explicar como ela explica.
- Anti-pattern: NÃO usar anglicismo ("framework", "pipeline", "onboarding") — auto-grep antes de marcar Done.
- Anti-pattern: NÃO inserir "ROI/semanas/garantia" — feedback recorrente para conteúdo CASE.
- Fonte canônica do método: o que está em `~/Downloads/copia projeto agentes` mais a leitura do agente Explore feita anteriormente (DECIDA já mapeia para os 3 enums atuais).

## Testing

- Revisão da Queila como gate humano (AC 6).
- Auto-grep antes de entregar: `grep -i 'framework\|pipeline\|onboarding\|ROI\|semana' guia-decida.md` deve retornar zero violações.

## Definition of Done

- [ ] AC 1-6 verificados
- [ ] Aprovação da Queila registrada
- [ ] Commit `docs(content-system): guia DECIDA cliente-facing`
