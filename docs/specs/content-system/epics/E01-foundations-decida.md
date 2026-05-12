---
title: "E01 — Foundations DECIDA"
type: epic
status: in-progress (4 stories done, 1 em review)
priority: P0
depends_on: []
estimated_stories: 5
date: 2026-05-12
owner: Kaique Rodrigues
---

# E01 — Foundations DECIDA

## Objetivo

Formalizar o método DECIDA como taxonomia editorial oficial do `refs.casein.com.br`, ajustando os labels de front-end, documentando a regra de mix 70/30/0-10 no guia de uso e alinhando o vocabulário em toda a codebase — sem alterar dados em produção.

## Por que esse epic

O handoff do Felipe Gobbi e o material canônico da Queila convergem para o DECIDA como estrutura de referência. O schema atual já possui `etapa_funil ∈ {DESCOBERTA, CONFIANCA, ACAO}` que mapeia diretamente para os blocos D+E / C+I+D / A — mas o label "CONFIANCA" não captura a tripla Confiança+Identificação+Desejo. Sem esse alinhamento de vocabulário, qualquer curador ou cliente fica confuso sobre o critério de escolha de etapa, tornando o banco de referências inconsistente desde o primeiro item promovido.

## Escopo

- Relabel do front-end: `CONFIANCA` exibe como "C+I+D" (Confiança · Identificação · Desejo) em todas as páginas (`/trilhas`, `/live`, modal de promoção, `/dashboard`)
- Documentação da regra de mix: arquivo `docs/specs/content-system/guia-decida.md` com definição dos 3 blocos, percentuais e exemplos
- Glossário de termos unificado referenciado em todo o código (constante TypeScript/JS exportada)
- Atualização do filtro na página `/trilhas` para exibir o novo label
- ADR `0001-decida-taxonomy.md` formalizado

## Fora de escopo

- Migration de dados (campo `etapa_funil` permanece com valores enum atuais)
- Alteração do schema Postgres — apenas camada de apresentação
- Implementação de qualquer agente editorial
- Criação de campos editoriais (coberto no E02)

## Stories propostas

| ID | Título | Descrição |
|----|--------|-----------|
| S1.1-constantes-decida | Criar constante DECIDA no front | Exportar objeto JS/TS com mapeamento `{DESCOBERTA, CONFIANCA, ACAO}` → labels e percentuais canônicos. Todos os usos hardcoded passam a referenciar essa constante. |
| S1.2-relabel-trilhas | Relabel etapa_funil em /trilhas | Substituir display "Confiança" por "C+I+D" na listagem, filtros e badges de `/trilhas.html`. Usar constante S1.1. |
| S1.3-relabel-live-modal | Relabel etapa_funil em /live e modal de promoção | Atualizar badge, select e qualquer texto literal nas páginas `/live.html` e no modal expandido. |
| S1.4-guia-decida | Redigir guia-decida.md | Documento cliente-facing (PT-BR) com: definição dos 3 blocos, regra de mix 70/30/0-10, exemplos de post por bloco, erros comuns. Deve ser referenciado pela página `/como-usar.html` do E03. |
| S1.5-adr-0001 | Formalizar ADR 0001 | Registrar decisão de adotar DECIDA como taxonomia oficial em `adrs/0001-decida-taxonomy.md`, incluindo contexto, alternativas descartadas e consequências. |

## Critérios de aceite do Epic

1. Em nenhuma página do site o texto "Confiança" aparece isolado como label de etapa — sempre "C+I+D" ou o label canônico definido na constante.
2. A constante DECIDA é a única fonte de verdade para labels e percentuais — sem string literal duplicada na codebase.
3. O arquivo `guia-decida.md` cobre os 3 blocos com definição, percentual e ao menos 1 exemplo de post cada.
4. O ADR `0001-decida-taxonomy.md` está presente e aprovado.
5. Os filtros de `/trilhas` funcionam corretamente com os novos labels (teste manual: filtrar cada etapa retorna apenas itens daquela etapa).

## Dependências técnicas

- `trilhas.html`, `live.html`, `dashboard.html` — páginas a atualizar
- Supabase Edge Function `case-refs-mutate` — sem alteração de lógica, apenas verificar se label vaza em responses
- View `public.v_referencias_publicas` — sem alteração
- `docs/specs/content-system/adrs/` — diretório de ADRs

## Riscos

1. **Inconsistência de labels**: se alguma página não for atualizada, curador vê labels diferentes em fluxos distintos. Mitigação: lint/grep por string hardcoded "Confiança" como parte do DoD da story S1.2/S1.3.
2. **Filtro quebrado**: relabel no front pode dessincronizar filtros que comparam string com valor do DB. Mitigação: constante mapeia exibição → valor enum DB sem alterar o enum.
3. **Adoção lenta do guia**: documento existe mas curadores não leem. Mitigação: linkar no modal de promoção (E02) e na página `/como-usar.html` (E03).

## Métrica de sucesso

Zero instâncias de label "Confiança" isolado nas páginas (verificável via grep no HTML renderizado) + guia-decida.md presente e linkado + ADR aprovado pelo Kaique.
