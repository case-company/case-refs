---
title: "E07 — Agente 02: Modelador de Referências"
type: epic
status: Done (1/1 story, smoke PASS 2026-05-12)
priority: P2
depends_on: [E02, E06]
estimated_stories: 5
date: 2026-05-12
owner: Kaique Rodrigues
---

# E07 — Agente 02: Modelador de Referências

## Objetivo

Implementar o Agente 02 (Modelador de Referências) como módulo que aceita uma referência externa (post, carrossel ou vídeo já no banco de `/trilhas`) e uma ideia do Banco de Ideias, e gera um roteiro modelado — preservando a estrutura de alto desempenho da referência e adaptando o conteúdo para a voz e contexto do cliente.

## Por que esse epic

O Agente 02 fecha o ciclo de produção de conteúdo: o banco de referências curado no E02 deixa de ser apenas uma biblioteca passiva e se torna um ativo gerador de roteiros. O princípio documentado pela Queila é explícito — copia ESTRUTURA, não copia CONTEÚDO. Isso diferencia o Agente 02 de simples paráfrase e torna o output legalmente seguro e estrategicamente distinto. A integração com o banco existente de `/trilhas` cria um loop de valor: quanto mais referências curadas, mais rico o repertório de estruturas disponíveis.

## Escopo

- Página `/agente-02.html` com seletor de: referência do banco de trilhas (por filtro de etapa/formato), ideia do Banco de Ideias do Agente 01 (opcional — pode ser input livre), formato de output (carrossel, reels, post estático)
- Pipeline: prompt canônico do Agente 02 que decompõe a estrutura da referência e remonta com o conteúdo da ideia selecionada
- Output: roteiro modelado estruturado por cenas/slides/blocos, com instruções de visual para cada parte
- Storage: tabela `agente.roteiros` com referência de origem, ideia usada, roteiro gerado, status
- UI: exibição do roteiro com edição inline básica e opção de download

## Fora de escopo

- Geração de imagens ou assets visuais
- Integração com ferramentas de design (Canva, Adobe)
- Agente 03 (Roteirista aprofundado) — planejado como fase futura
- Análise de performance do roteiro após publicação

## Stories propostas

| ID | Título | Descrição |
|----|--------|-----------|
| S7.1-migration-roteiros | Migration: tabela roteiros | Criar tabela `agente.roteiros` com: `id, cliente_nome, referencia_id (FK agente.referencias_conteudo), ideia_descricao TEXT, formato, roteiro JSONB, instrucoes_visual TEXT, status, created_at`. |
| S7.2-edge-fn-agente02 | Edge Function: processar Agente 02 | Edge Function `agente-02-processar` que recebe referência (busca transcrição + caption do banco) + ideia, monta prompt canônico de modelagem, parseia output em roteiro por blocos/cenas. |
| S7.3-form-agente02 | Página /agente-02.html: seletor de input | Seletor de referência do banco (filtro por etapa DECIDA, formato, trilha), campo de ideia (dropdown do Banco de Ideias do Agente 01 ou textarea livre), seletor de formato de output, botão "Modelar". |
| S7.4-ui-roteiro-output | UI: exibição e edição do roteiro modelado | Renderizar roteiro por blocos/cenas com: número do bloco, conteúdo textual, instrução visual. Cada bloco editável inline. Botão "Salvar edição" por bloco. |
| S7.5-exportar-roteiro | Exportação do roteiro | Botão "Exportar roteiro" gera texto formatado pronto para usar em tool de criação de conteúdo. Inclui: referência de origem, formato, cliente, data, roteiro por blocos. |

## Critérios de aceite do Epic

1. Seletor de referência exibe ao menos os campos: título (ou shortcode), formato, etapa DECIDA — suficiente para o usuário escolher.
2. Roteiro gerado contém ao menos tantos blocos quanto slides/cenas da referência original (estrutura preservada).
3. Nenhuma frase do caption ou transcrição da referência original aparece literalmente no roteiro gerado (conteúdo não copiado).
4. Edição inline de bloco salva sem reprocessar o roteiro inteiro.
5. Exportação gera arquivo de texto com roteiro completo e metadados (referência de origem, cliente, data).
6. Smoke com referência real do banco + ideia real do Agente 01 documentado com PASS.

## Dependências técnicas

- E02 concluído (banco de referências com campos editoriais — `quando_usar` e `como_adaptar` são insumo do prompt do Agente 02)
- E06 concluído (Banco de Ideias do Agente 01 como fonte de ideias selecionáveis)
- Tabela `agente.referencias_conteudo` com `transcricao`, `caption`, `formato`, `etapa_funil` populados
- Tabela nova `agente.roteiros` (migration S7.1)
- Edge Function nova `agente-02-processar`
- Prompt canônico do Agente 02 (`fluxo_02_modelador_de_referencias.md`)

## Riscos

1. **Referências sem transcrição**: se a referência não tem `transcricao`, o Agente 02 trabalha apenas com `caption` — estrutura pode ser pobre. Mitigação: UI indica quando transcrição está ausente; usuário decide se continua.
2. **Roteiro com conteúdo copiado**: LLM pode parafrasear muito próximo do original. Mitigação: instrução explícita no prompt + AC de verificação manual no smoke.
3. **Dependência de E06 para ideias**: sem Banco de Ideias pronto, o Agente 02 fica em modo "ideia livre" (textarea). Isso é válido para V1 mas reduz o valor integrado.

## Métrica de sucesso

Ao menos 5 roteiros gerados em uso real com feedback "utilizável" da Queila ou do cliente piloto; tempo médio de geração inferior a 45 segundos por roteiro.
