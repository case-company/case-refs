---
title: "E04 — Agente 00: Mapa de Interesse"
type: epic
status: Done (1/1 story, smoke PASS 2026-05-12)
priority: P1
depends_on: [E01, E02]
estimated_stories: 6
date: 2026-05-12
owner: Kaique Rodrigues
---

# E04 — Agente 00: Mapa de Interesse

## Objetivo

Implementar o Agente 00 (Mapa de Interesse) como módulo funcional no site: formulário de input público, processamento via prompt canônico da Queila, output estruturado em 12 gavetas e interface de consulta — permitindo que qualquer membro da CASE gere um mapa de interesse em minutos sem depender de sessão manual com a Queila.

## Por que esse epic

O Agente 00 é o ponto de entrada de toda a produção de conteúdo estratégico. Sem o mapa de interesse, o Agente 01 não tem insumo de público e o Agente 02 não sabe qual tensão capturar. O material da Queila (`fluxo_00_mapa_de_interesse.md`) define o prompt e as 12 gavetas com precisão — o esforço aqui é de engenharia de produto (form, pipeline, storage, UI) e não de metodologia.

## Escopo

- Página `/agente-00.html` com formulário de input: quem é o público (nível, contexto), qual a oferta/promessa, sinais externos (opcional: URL YouTube, comentários copiados, concorrentes)
- Pipeline de processamento: chamada ao LLM com prompt canônico do Agente 00, parsing do output em 12 gavetas
- Storage: tabela Supabase `agente.mapas_interesse` com resultado estruturado (JSONB por gaveta + metadados)
- UI de resultado: exibição das 12 gavetas com top assuntos priorizados, opção de copiar gaveta isolada
- UI de consulta: listagem de mapas gerados com busca por cliente/data

## Fora de escopo

- Integração automática do mapa gerado no Agente 01 (conexão manual por enquanto — roadmap E06)
- Edição pós-geração das gavetas (V1 é read-only)
- Autenticação de usuário (acesso livre dentro do domínio `casein.com.br`)
- Sinais externos via scraping automático (usuário cola manualmente no V1)

## Stories propostas

| ID | Título | Descrição |
|----|--------|-----------|
| S4.1-migration-mapas-interesse | Migration: tabela mapas_interesse | Criar tabela `agente.mapas_interesse` com campos: `id, cliente_nome, publico_descricao, oferta_descricao, sinais_externos TEXT, gavetas JSONB, top_assuntos JSONB, created_at, status`. |
| S4.2-edge-fn-agente00 | Edge Function: processar Agente 00 | Edge Function `agente-00-processar` que recebe input do form, monta prompt canônico, chama LLM (OpenAI/Anthropic via env var), parseia resposta em 12 gavetas, armazena na tabela e retorna o resultado. |
| S4.3-form-agente00 | Página /agente-00.html: formulário de input | Formulário com campos: cliente (texto), público/nível/contexto (textarea), oferta/promessa (textarea), sinais externos (textarea, opcional). Botão "Gerar Mapa" com estado de loading. |
| S4.4-ui-resultado-gavetas | UI: exibição das 12 gavetas | Componente que renderiza o resultado do Agente 00 em 12 cards (dores, desejos, medos, dúvidas, erros, crenças, valores, comparações, cenas, identidades, inimigos, referências). Botão "Copiar gaveta" em cada card. |
| S4.5-ui-listagem-mapas | UI: listagem de mapas gerados | Seção ou página `/agente-00.html#historico` listando mapas anteriores com: nome cliente, data, preview de top_assuntos. Clicar expande resultado completo. |
| S4.6-smoke-agente00 | Smoke: gerar mapa real com cliente exemplo | Executar fluxo completo com dados de cliente real (anonimizado no teste). Validar: 12 gavetas preenchidas, top_assuntos coerentes, storage OK, exibição legível. Documentar em test-runs/. |

## Critérios de aceite do Epic

1. Formulário aceita input e retorna as 12 gavetas em menos de 60 segundos (LLM call incluído).
2. Todas as 12 gavetas do output canônico estão presentes na UI, mesmo que alguma retorne vazia do LLM.
3. Resultado armazenado na tabela Supabase e recuperável na listagem.
4. Botão "Copiar gaveta" copia o texto da gaveta para o clipboard.
5. Estado de loading visível durante o processamento (sem tela em branco).
6. Smoke com dados reais documentado com PASS.

## Dependências técnicas

- E01 concluído (vocabulário DECIDA para contexto do prompt)
- E02 concluído (schema db estável antes de adicionar nova tabela)
- Tabela nova `agente.mapas_interesse` (migration S4.1)
- Edge Function nova `agente-00-processar`
- Variável de ambiente LLM key no Supabase (Anthropic ou OpenAI — definir na S4.2)
- Prompt canônico em `~/Downloads/copia projeto agentes/Manuais dos agentes/05_Base_Metodologica/fluxo_00_mapa_de_interesse.md`

## Riscos

1. **Qualidade do parsing do LLM**: LLM pode retornar as 12 gavetas em formato diferente do esperado. Mitigação: prompt inclui instrução de formato JSON estrito + fallback de parsing com regex por gaveta.
2. **Custo de LLM por chamada**: Agente 00 é prompt longo. Mitigação: medir custo no smoke e documentar; definir limite de chamadas por dia se necessário.
3. **Prompt desatualizado**: o prompt canônico pode ser revisado pela Queila. Mitigação: prompt vive como arquivo versionado (`supabase/functions/agente-00-processar/prompt.md`) e não hardcoded.

## Métrica de sucesso

Ao menos 3 mapas de interesse gerados por membros diferentes da CASE dentro de 2 semanas do rollout, com feedback positivo sobre a coerência das gavetas (coleta via formulário simples de 1 pergunta pós-geração).
