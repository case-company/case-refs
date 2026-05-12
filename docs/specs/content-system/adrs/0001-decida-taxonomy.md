---
title: ADR-0001 — Adoção do método DECIDA (D+E / C+I+D / A) como taxonomia oficial
status: accepted
date: 2026-05-12
deciders: [Kaique, Queila]
supersedes: null
related:
  - 02-spec-tech.md#1.2
  - 02-spec-tech.md#6.4
  - 00-context-and-handoff.md#3
---

# ADR-0001 — Taxonomia DECIDA

## Context

A Queila consolidou o método dela em torno de **DECIDA**: uma estrutura de **objetivos editoriais** organizada em 3 blocos, NÃO um acrônimo letra-por-letra. Os 4 pilares antigos (DESEJAR/DESCOBRIR/IDENTIFICAR/CONFIAR) foram absorvidos.

Os 3 blocos:

| Bloco       | Significado                              | Mix padrão do ciclo |
|-------------|------------------------------------------|---------------------|
| **D + E**   | Descoberta + Entendimento                | 70%                 |
| **C + I + D** | Confiança + Identificação + Desejo     | 30%                 |
| **A**       | Ação / Decisão                           | 0–10% (fase vendas) |

O schema atual de `agente.referencias_conteudo` já tem a coluna `etapa_funil ∈ {DESCOBERTA, CONFIANCA, ACAO}`, definida quando o `refs.casein.com.br` foi montado. Os 3 valores **batem 1:1** com os 3 blocos do DECIDA:

- `DESCOBERTA` ↔ D+E
- `CONFIANCA`  ↔ C+I+D
- `ACAO`       ↔ A

O handoff do Felipe Gobbi (BU-CASE) pediu que a taxonomia oficial do produto consolidado fosse DECIDA. A Queila confirmou. Falta decidir **o que fazer no banco** vs **na UX**.

## Decision

**Adotar DECIDA como taxonomia oficial do produto, com mapeamento UX-only — sem migration de dados.**

Concretamente:

1. **Banco**: a coluna `etapa_funil` permanece com os 3 valores atuais (`DESCOBERTA`, `CONFIANCA`, `ACAO`). Zero migration.
2. **UX**: criar uma camada de label que renderiza:
   - `DESCOBERTA` → exibe "**D+E**" (cor azul `#3b82f6`)
   - `CONFIANCA`  → exibe "**C+I+D**" (cor roxa `#8b5cf6`)
   - `ACAO`       → exibe "**A**" (cor vermelha `#ef4444`)
3. **Documentação**: `/como-usar.html` explica o que cada bloco significa e a regra de mix 70/30/0-10 (em D+E padrão; em fase de vendas, A sobe pra 10%).
4. **View SQL utilitária** (`v_etapa_label`) pra ser consumida por relatórios e exports — mapeia `etapa_funil` → `etapa_label`. View, não generated column, pra evitar reescrever a tabela.

## Consequences

### Positivas

- **Zero risco de migration**: tabela tem milhares de linhas, índices, constraints. Renomear enum custa downtime e bug surface.
- **Rollback trivial**: se DECIDA for rebatizado de novo amanhã, só muda label.
- **Backwards compat**: scripts/n8n/Edge Fn antigos que escrevem `etapa_funil = 'CONFIANCA'` continuam funcionando.
- **UX consistente**: pill colorida + tooltip explicando o bloco em todo card de `/trilhas` e `/posts`.

### Negativas / Trade-offs

- **Vazamento conceitual**: quem ler SQL bruto vai ver `CONFIANCA` no banco mas `C+I+D` no front. Mitigado por COMMENT na coluna + view `v_etapa_label`.
- **Risco de desalinhamento futuro**: se Queila adicionar 4º bloco no método, banco pode ficar pequeno. Aceito — pivot vira nova migration nessa hora.
- **Ferramentas de BI externas precisam saber do mapping**: documentar em `/docs/specs/content-system/` e em comment do Postgres.

### Neutras

- A regra de mix 70/30/0-10 não vira constraint de banco — é diretriz editorial validada no Agente 01 (Estrategista) e renderizada como hint no `/dashboard`.

## Alternatives Considered

### Alt A — Migration completa: renomear enum no banco
- Renomear `DESCOBERTA → D_E`, `CONFIANCA → C_I_D`, `ACAO → A` (enums não aceitam `+`).
- **Por que rejeitada**: alto risco operacional (constraint break, rewrite de índices, downtime), zero ganho funcional, e o método pode mudar de novo (Queila já mudou de "4 pilares" pra "3 blocos" uma vez).

### Alt B — Adicionar nova coluna `bloco_decida TEXT` em paralelo
- Manter `etapa_funil` E adicionar `bloco_decida`.
- **Por que rejeitada**: dois campos pra mesma coisa convida divergência. Já escolhemos canonicidade no banco com 3 valores existentes.

### Alt C — Generated column `bloco_decida AS (CASE etapa_funil ...) STORED`
- Dispensaria a view, expondo o label direto na tabela.
- **Por que rejeitada**: força rewrite da tabela e perde flexibilidade de remap em runtime. View é zero-cost.

### Alt D — Não adotar DECIDA, manter etapas atuais como nomes oficiais
- **Por que rejeitada**: handoff explícito da Queila pra adotar. É decisão de produto, não técnica.

## Implementation Hooks

- Migration: `20260513007000_rename_etapa_funil_label_view.sql` cria `v_etapa_label`.
- Frontend: `/_components/decida-pill.js` renderiza pill com cor + tooltip.
- Doc: `/como-usar.html` (a ser criado em E01).
