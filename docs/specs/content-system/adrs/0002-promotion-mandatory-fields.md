---
title: ADR-0002 — Promoção exige preenchimento de quando_usar / por_que_funciona / como_adaptar
status: accepted
date: 2026-05-12
deciders: [Kaique, Queila]
supersedes: null
related:
  - 02-spec-tech.md#2.1
  - 02-spec-tech.md#3.1
  - 02-spec-tech.md#4.1
  - 00-context-and-handoff.md#5
---

# ADR-0002 — Campos editoriais obrigatórios na promoção

## Context

Hoje, o fluxo de curadoria do `refs.casein.com.br` é:

1. Item entra via webhook n8n com `promoted_at = NULL` (badge ⏳).
2. Curador abre `/live`, clica "Promover ao Banco de Trilhas".
3. Edge Fn `case-refs-mutate op=promote` faz `UPDATE refs SET promoted_at = NOW()`.
4. Item aparece em `/trilhas` no fim da categoria.

O problema: o card promovido só carrega `caption + transcrição + etapa_funil + tipo_estrategico`. Quando uma mentorada (consumidora final) abre o card pra usar como referência, **ela não sabe**:

- **Quando** usar essa referência (em que momento da estratégia dela)
- **Por que** essa referência funciona (qual gatilho/mecânica está em jogo)
- **Como** adaptar pra realidade dela (sem copiar conteúdo)

O handoff Felipe + briefing Queila pediram explicitamente esses 3 campos. Sem eles, o `/trilhas` vira "biblioteca de prints" — bonita mas inutilizável sem o curador presente.

## Decision

**Tornar `quando_usar`, `por_que_funciona` e `como_adaptar` obrigatórios na promoção, com gatekeeper triplo:**

1. **Schema-level (banco)**: CHECK constraint na tabela:
   ```sql
   CHECK (
     promoted_at IS NULL
     OR (
       char_length(coalesce(quando_usar, '')) >= 20
       AND char_length(coalesce(por_que_funciona, '')) >= 20
       AND char_length(coalesce(como_adaptar, '')) >= 20
     )
   )
   ```
2. **API-level (Edge Function)**: nova op `promote_with_fields` que recebe os 3 campos no payload e valida tamanho mínimo antes de chamar a RPC. Op antiga `promote` passa a retornar `400 use_promote_with_fields` se algum campo estiver NULL.
3. **UX-level (frontend)**: modal de promoção em `/live` mostra 3 textareas obrigatórias + dropdown `objetivo` (5 opções). Botão "Promover" só habilita quando todos preenchidos com ≥20 chars.

Adicionalmente:
- Campo `objetivo TEXT` (separado de `etapa_funil`) é incluído mas **não obrigatório** em V1 — vai com hint dos 5 valores canônicos (Atrair / Identificar / Desejo / Confiar / Vender).
- Itens já promovidos antes desta migration ficam "legacy promoted" — CHECK constraint não os invalida porque foram promovidos com a regra antiga. Backfill manual é decisão futura.

## Consequences

### Positivas

- **Cliente-facing utility real**: cada card promovido carrega o "manual de uso" embutido. `/trilhas` deixa de ser print e vira recurso editorial.
- **Disciplina editorial forçada**: curador não consegue "promover por inércia". Cada promoção é uma decisão consciente.
- **Defesa em profundidade**: se o front escapar, a Edge Fn segura. Se a Edge Fn for bypassada, o banco segura. Triple lock.
- **Rastreabilidade**: campos textuais podem ser usados depois pra treinar o Agente 01 (Estrategista) — virar dataset.

### Negativas / Trade-offs

- **Fricção de promoção sobe** — vai de 1 clique pra ~2min de redação. Pode reduzir taxa de promoção no início.
  - Mitigação: `dashboard.html` aba "Editorial" pra preenchimento em batch.
  - Mitigação V1.5: "Sugerir 3 campos via LLM" botão no modal (Claude Haiku, $0.001/item).
- **Itens legacy ficam visualmente desiguais**: promovidos antigos não têm os 3 campos. Tooltip "Sem manual de uso (legado)" + botão "Adicionar manual" no dashboard.
- **Limite mínimo de 20 chars é arbitrário**: pode gerar texto preguiçoso ("usar quando precisar"). Mitigação V1.5: validador semântico (rejeita "n/a", "tbd", "ver depois").

### Neutras

- `objetivo` ficar opcional em V1 evita travar tudo numa decisão de taxonomia paralela. Pode virar obrigatório em V1.5 sem breaking change.

## Alternatives Considered

### Alt A — Tornar campos opcionais, contar com disciplina do curador
- **Por que rejeitada**: a história do produto mostra que sem gatekeeper, o curador prioriza volume. Felipe Gobbi tentou em planilha — não funcionou.

### Alt B — Validar só na UI (sem CHECK constraint)
- **Por que rejeitada**: deixa porta aberta pra script ou Edge Fn nova promover sem campos. Defesa em profundidade vale o custo trivial do CHECK.

### Alt C — Mínimo de chars maior (≥80) pra forçar qualidade
- **Por que rejeitada**: 80 chars é threshold arbitrário ainda mais alto e bloqueia casos legítimos curtos ("Use no story 3 do funil de aula" tem 31 chars). 20 chars é o piso "não-vazio sério"; qualidade vira validação semântica em V1.5.

### Alt D — Substituir 3 campos por um único campo `manual_uso TEXT` (markdown livre)
- **Por que rejeitada**: pesquisa de uso (handoff Felipe + dossiês Queila) mostrou que quem consome quer **3 perguntas separadas** pra escanear rápido. Markdown livre vira muro de texto. 3 campos = 3 perguntas = 3 respostas estruturadas.

### Alt E — Promover automaticamente via LLM gerando os 3 campos
- **Por que rejeitada (em V1)**: tira o curador editorial do loop, e a Queila explicitamente quer revisão humana antes de virar canônico. Vira feature de V1.5 (botão "sugerir → revisar → aceitar").

## Implementation Hooks

- Migration: `20260513000000_referencias_conteudo_editorial_fields.sql` (4 colunas + CHECK).
- Edge Fn: `case-refs-mutate` ganha `op=promote_with_fields` e `op=update_editorial_fields`.
- Frontend: `live.html` ganha modal nova com 3 textareas + dropdown.
- Spec: `02-spec-tech.md` §3.1.1 e §4.1.

## Related ADRs

- ADR-0001 (taxonomia DECIDA) — define o vocabulário de `objetivo` e `etapa_funil` no card.
- ADR-0003 (agentes como módulos) — Agente 01 vai eventualmente sugerir os 3 campos.
