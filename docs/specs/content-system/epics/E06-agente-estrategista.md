---
title: "E06 — Agente 01: Estrategista de Conteúdo Editorial"
type: epic
status: not-started
priority: P2
depends_on: [E04, E05, E08]
estimated_stories: 6
date: 2026-05-12
owner: Kaique Rodrigues
---

# E06 — Agente 01: Estrategista de Conteúdo Editorial

## Objetivo

Implementar o Agente 01 (Estrategista de Conteúdo Editorial) como módulo que, a partir do Mapa de Interesse (Agente 00) e do Repositório do Expert (Agente 00.5), gera um Plano Editorial completo e um Banco de Ideias — onde cada ideia possui obrigatoriamente insumo do público E insumo do expert, tornando o conteúdo único e estratégico.

## Por que esse epic

O Agente 01 é o coração da produção de conteúdo estratégico. Sem ele, o planejamento editorial depende de intuição e memória da Queila ou dos mentorados. Com ele, qualquer membro da CASE gera um plano baseado em dados reais do público (gavetas do Agente 00) combinados com a voz única do cliente (repositório do Agente 00.5). O critério crítico documentado pela Queila — toda ideia precisa de insumo público + insumo expert, senão é inválida — está codificado como gating no próprio pipeline.

## Escopo

- Página `/agente-01.html` com seletor de: cliente existente, mapa de interesse (resultado do Agente 00), repositório do expert (resultado do Agente 00.5), fase DECIDA atual (D+E ou Vendas), capacidade de produção (posts/semana)
- Pipeline: prompt canônico do Agente 01 com injeção de ambos os insumos, output estruturado em Plano Editorial + Banco de Ideias
- Gating de qualidade: validação que todo item do Banco de Ideias referencia ao menos 1 gaveta do mapa E ao menos 1 item do repositório expert (se não, item marcado como "insumo incompleto" e não publicável)
- Storage: tabela `agente.planos_editoriais` com Plano Editorial + Banco de Ideias por cliente/ciclo
- UI: exibição do plano editorial + banco de ideias com filtros por linha e etapa DECIDA
- Exportação: formato pronto para colar em doc de planejamento

## Fora de escopo

- Integração com calendário editorial externo (Notion, ClickUp)
- Geração de roteiro a partir das ideias (responsabilidade do Agente 02, E07)
- Agendamento de posts
- Histórico com análise de performance

## Stories propostas

| ID | Título | Descrição |
|----|--------|-----------|
| S6.1-migration-planos-editoriais | Migration: tabela planos_editoriais | Criar tabela `agente.planos_editoriais` com: `id, cliente_nome, mapa_interesse_id, repositorio_expert_id, fase_decida, capacidade_producao INT, plano_editorial JSONB, banco_ideias JSONB, created_at`. |
| S6.2-edge-fn-agente01 | Edge Function: processar Agente 01 | Edge Function `agente-01-processar` que busca mapa e repositório por ID, monta prompt canônico injetando ambos os insumos, parseia output em Plano Editorial + Banco de Ideias com gating de validação. |
| S6.3-gating-insumo-completo | Gating: validar insumo público + expert | Lógica dentro da Edge Function que, para cada ideia gerada, verifica referência a gaveta do mapa E item do repositório. Ideias sem ambas as referências recebem status `insumo_incompleto`. |
| S6.4-form-agente01 | Página /agente-01.html: seletor de insumos | Interface com: dropdown "cliente" (carrega mapas e repositórios existentes do Supabase), seletor de fase DECIDA, campo capacidade de produção, botão "Gerar Plano". |
| S6.5-ui-plano-banco-ideias | UI: exibição do Plano Editorial e Banco de Ideias | Seção Plano Editorial (visão macro por semana/linha) + seção Banco de Ideias (cards por ideia com: objetivo, linha, insumo público, insumo expert, tensão de captura, gancho, status de insumo). Filtros por etapa DECIDA e linha editorial. |
| S6.6-exportar-plano | Exportação do Plano Editorial | Botão "Exportar" gera texto estruturado com Plano Editorial + ideias completas (sem as de status `insumo_incompleto`) em formato de doc de planejamento. |

## Critérios de aceite do Epic

1. Agente 01 só pode ser executado se há um Mapa de Interesse E um Repositório do Expert selecionados — sem eles, botão desabilitado com mensagem explicativa.
2. Banco de Ideias gerado contém ao menos 10 ideias por ciclo de 4 semanas.
3. Toda ideia marcada como `insumo_incompleto` está visualmente diferenciada (badge, cor) na UI.
4. Filtro por etapa DECIDA funciona corretamente no Banco de Ideias.
5. Exportação inclui apenas ideias com insumo completo.
6. Plano Editorial e Banco de Ideias persistidos na tabela e recuperáveis em sessões futuras.

## Dependências técnicas

- E04 concluído (Agente 00 — Mapa de Interesse operacional)
- E05 concluído (Agente 00.5 — Repositório do Expert operacional)
- E08 com ao menos 1 ciclo de validação com cliente piloto concluído (feedback sobre qualidade das ideias)
- Tabela nova `agente.planos_editoriais` (migration S6.1)
- Edge Functions de E04 e E05 (busca de insumos por ID)
- Prompt canônico do Agente 01 (`briefing_agente_01_estrategista_editorial.md`)

## Riscos

1. **Gating muito restritivo**: LLM pode não conseguir referenciar explicitamente gavetas e itens do repositório em todas as ideias. Mitigação: orientar o prompt a incluir a referência explicitamente; se não vier, o gating marca como incompleto (comportamento conservador intencional).
2. **Qualidade do Banco de Ideias depende da qualidade dos insumos**: mapa de interesse fraco ou repositório esparso geram ideias fracas. Mitigação: UI mostra "completude" dos insumos antes de executar o Agente 01.
3. **Custo de LLM elevado**: prompt é longo (mapa + repositório + instrução). Mitigação: medir tokens na S6.2 e implementar truncagem inteligente se necessário.

## Métrica de sucesso

Ao menos 80% das ideias geradas no Banco de Ideias recebem avaliação "utilizável" ou "ótima" da Queila ou do cliente piloto (coleta via feedback simples pós-exportação).
