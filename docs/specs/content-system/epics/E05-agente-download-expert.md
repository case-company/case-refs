---
title: "E05 — Agente 00.5: Download do Expert"
type: epic
status: Done (1/1 story, smoke PASS 2026-05-12)
priority: P1
depends_on: [E04]
estimated_stories: 5
date: 2026-05-12
owner: Kaique Rodrigues
---

# E05 — Agente 00.5: Download do Expert

## Objetivo

Implementar o Agente 00.5 (Download do Expert) como módulo de coleta estruturada das perspectivas únicas do cliente expert: perguntas cirúrgicas guiadas por prompt canônico, e storage do repositório de crenças, teses, provas, histórias, storytelling, método e linguagem — que alimentará o Agente 01 como insumo "expert" obrigatório.

## Por que esse epic

O Agente 01 tem um critério crítico: toda ideia de conteúdo precisa ter insumo do público (saída do Agente 00) E insumo do expert (saída do Agente 00.5). Sem esse repositório, o Agente 01 gera conteúdo genérico que poderia ter sido escrito por qualquer pessoa — matando a diferenciação do cliente. O material da Queila marca o Agente 00.5 como "aprovado e finalizado", indicando que o prompt e as categorias já estão validados; o esforço aqui é product engineering.

## Escopo

- Página `/agente-005.html` com formulário guiado: apresentação das categorias de coleta e campos por categoria
- Prompt canônico do Agente 00.5: perguntas cirúrgicas sobre opiniões, valores, provas, cases, histórias, método, frases próprias
- Dois modos de input: (a) formulário direto pelo cliente; (b) processamento de transcrição colada (entrevista gravada)
- Storage: tabela Supabase `agente.repositorio_expert` com campos por categoria (JSONB) vinculados ao cliente
- UI de visualização do repositório por cliente, com edição pontual (o repositório cresce ao longo do tempo)
- Exportação do repositório como texto estruturado (para cola no Agente 01 manual)

## Fora de escopo

- Integração direta com ferramenta de gravação/transcrição (usuário cola transcrição manualmente)
- Geração automática de conteúdo a partir do repositório (responsabilidade do E06)
- Versionamento de histórico de edições do repositório

## Stories propostas

| ID | Título | Descrição |
|----|--------|-----------|
| S5.1-migration-repositorio-expert | Migration: tabela repositorio_expert | Criar tabela `agente.repositorio_expert` com campos: `id, cliente_nome, crenças JSONB, teses JSONB, provas JSONB, historias JSONB, storytelling JSONB, metodo JSONB, linguagem JSONB, frases_proprias TEXT[], created_at, updated_at`. |
| S5.2-edge-fn-agente005 | Edge Function: processar Agente 00.5 | Edge Function `agente-005-processar` que recebe texto livre (formulário ou transcrição), aplica prompt canônico para extrair e estruturar as categorias, armazena na tabela e retorna resultado estruturado. |
| S5.3-form-agente005 | Página /agente-005.html: formulário guiado | Interface com duas abas: (1) "Formulário direto" — campos por categoria com perguntas cirúrgicas como placeholder; (2) "Transcrição" — textarea para colar transcrição + botão processar. |
| S5.4-ui-repositorio-visualizacao | UI: visualização e edição do repositório | Exibir repositório por cliente em cards por categoria. Cada item editável inline (textarea com botão salvar). Botão "+ Adicionar item" por categoria. |
| S5.5-exportar-repositorio | Exportar repositório como texto estruturado | Botão "Exportar para Agente 01" que gera texto formatado com todas as categorias preenchidas, pronto para copiar. Formato alinhado com o que o prompt do Agente 01 espera como "insumo expert". |

## Critérios de aceite do Epic

1. Formulário guiado exibe ao menos 2 perguntas cirúrgicas por categoria como placeholder/orientação.
2. Modo "Transcrição" extrai e estrutura as categorias a partir de texto livre de ao menos 500 palavras.
3. Repositório persistido na tabela e recuperável na UI de visualização.
4. Edição inline salva corretamente (sem reload de página).
5. Exportação gera texto coerente com o formato esperado pelo Agente 01.
6. Repositório de um cliente não vaza na visualização de outro cliente (isolamento por `cliente_nome`).

## Dependências técnicas

- E04 concluído (Agente 00 estabelece padrão de arquitetura que E05 replica)
- Tabela nova `agente.repositorio_expert` (migration S5.1)
- Edge Function nova `agente-005-processar`
- Prompt canônico do Agente 00.5 (material Queila aprovado)
- LLM key já configurada no Supabase (herdada do E04)

## Riscos

1. **Extração de transcrição imprecisa**: LLM pode misturar categorias ao processar transcrição longa. Mitigação: chunking por categoria no prompt — processar uma categoria por vez se transcrição > 2000 tokens.
2. **Repositório fragmentado por cliente_nome string**: se o nome do cliente mudar, os registros ficam órfãos. Mitigação: incluir campo `cliente_id` (mesmo que seja UUID gerado pelo front) para lookups futuros.
3. **Exportação desalinhada com Agente 01**: formato exportado pode mudar quando E06 for implementado. Mitigação: exportação como feature independente; versionamento do formato via comentário no arquivo exportado.

## Métrica de sucesso

Repositório de ao menos 2 clientes piloto preenchido com mínimo de 5 itens por categoria principal (crenças, provas, método) — verificável via query na tabela — antes do início do E06.
