---
title: "E02 — Curadoria Editorial"
type: epic
status: code-complete (5/6 stories prontas, smoke E2E pendente)
priority: P0
depends_on: [E01]
estimated_stories: 6
date: 2026-05-12
owner: Kaique Rodrigues
---

# E02 — Curadoria Editorial

## Objetivo

Transformar o fluxo de promoção de referências em um workflow editorial completo, exigindo 3 campos obrigatórios (quando_usar, por_que_funciona, como_adaptar) antes de promover qualquer item ao banco — e disponibilizando esses campos no modal expandido e via Edge Function.

## Por que esse epic

O fluxo atual permite promover um item com apenas um clique, sem qualquer anotação editorial. Isso cria um banco de referências que armazena "o quê" (o post) sem explicar "como usar" para outra pessoa. O handoff Gobbi e o método da Queila são explícitos: a curadoria só tem valor quando o curador documenta a inteligência por trás da escolha. Sem esses 3 campos, o banco de referências não é treinável nem consultável por clientes ou pelo Agente 01.

## Escopo

- Migration Supabase: adicionar colunas `quando_usar TEXT`, `por_que_funciona TEXT`, `como_adaptar TEXT` à tabela `agente.referencias_conteudo`
- Edge Function `case-refs-mutate`: adicionar op `promote_editorial` que valida presença dos 3 campos antes de setar `promoted_at`
- Modal de promoção expandido: 3 campos textarea obrigatórios + validação client-side que bloqueia botão "Promover" até todos preenchidos
- View `public.v_referencias_publicas`: expor os 3 novos campos
- Página `/trilhas`: exibir campos editoriais no card expandido do item promovido
- Script de migration sem downtime para linhas já promovidas (campos ficam NULL até reedição manual)

## Fora de escopo

- Preenchimento automatizado dos 3 campos via IA (roadmap futuro)
- Obrigatoriedade retroativa para itens já promovidos (NULL permitido em dados legados)
- Alteração no pipeline de ingest (n8n/Apify) — itens entram sem os campos, curador preenche na promoção

## Stories propostas

| ID | Título | Descrição |
|----|--------|-----------|
| S2.1-migration-add-editorial-columns | Migration: adicionar 3 colunas editoriais | Criar migration Supabase com `quando_usar TEXT, por_que_funciona TEXT, como_adaptar TEXT` na tabela `agente.referencias_conteudo`. Campos nullable (itens antigos mantêm NULL). |
| S2.2-edge-fn-promote-editorial | Edge Function: op promote_editorial | Adicionar operação `promote_editorial` à Edge Function `case-refs-mutate`. Valida que os 3 campos são não-nulos e não-vazios antes de setar `promoted_at = now()`. Retorna erro 422 se algum campo ausente. |
| S2.3-view-expose-fields | View: expor campos editoriais | Atualizar `public.v_referencias_publicas` para incluir `quando_usar`, `por_que_funciona`, `como_adaptar`. |
| S2.4-modal-campos-editoriais | Modal de promoção: 3 campos obrigatórios | Expandir modal em `/live.html` com 3 textareas (labels em PT-BR, placeholders orientativos). Botão "Promover" desabilitado até todos os campos preenchidos. Chamar `promote_editorial` em vez de `promote`. |
| S2.5-trilhas-exibir-editorial | /trilhas: exibir campos no card expandido | Adicionar seção "Guia de uso" no card expandido de `/trilhas.html` com os 3 campos (quando não NULL). Ocultar seção se todos NULL (itens legados). |
| S2.6-smoke-e2e-curadoria | Smoke E2E: fluxo curadoria completo | Teste manual documentado: ingerir item → abrir modal → tentar promover sem campos (deve bloquear) → preencher campos → promover → verificar exibição em /trilhas. Registrar resultado em `docs/specs/content-system/test-runs/`. |

## Critérios de aceite do Epic

1. Migration aplicada em staging e produção sem downtime.
2. Tentativa de promoção sem os 3 campos retorna erro 422 da Edge Function e o modal exibe mensagem de validação ao usuário.
3. Item promovido com os 3 campos aparece em `/trilhas` com seção "Guia de uso" visível.
4. Itens legados (campos NULL) aparecem em `/trilhas` sem a seção "Guia de uso" — sem erro de renderização.
5. View `v_referencias_publicas` retorna os 3 novos campos na resposta JSON.
6. Smoke E2E documentado com resultado PASS.

## Dependências técnicas

- E01 concluído (vocabulário DECIDA alinhado antes de expandir o modal)
- Tabela `agente.referencias_conteudo` — migration
- Edge Function `case-refs-mutate` — nova operação
- View `public.v_referencias_publicas` — atualização
- `live.html` — modal expandido
- `trilhas.html` — card expandido

## Riscos

1. **Migration em produção com dados vivos**: migration ADD COLUMN nullable é safe, mas qualquer rollback exigiria DROP. Mitigação: testar em staging primeiro, manter backup antes de aplicar.
2. **Edge Function versionamento**: Supabase Edge Functions não têm rollback automático. Mitigação: manter a operação `promote` original funcional durante o período de transição, deprecar só após smoke passar.
3. **UX de validação client-side ignorada**: curador pode fazer POST direto para a Edge Function bypassando o modal. Mitigação: validação server-side na Edge Function é o gatekeeper real.

## Métrica de sucesso

100% dos itens promovidos após o rollout do E02 possuem os 3 campos preenchidos (verificável via query `SELECT COUNT(*) FROM agente.referencias_conteudo WHERE promoted_at > [data_rollout] AND quando_usar IS NULL`).
