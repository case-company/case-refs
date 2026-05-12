---
title: "E08 — Validação e Rollout"
type: epic
status: not-started
priority: P1
depends_on: [E01, E02, E03]
estimated_stories: 5
date: 2026-05-12
owner: Kaique Rodrigues
---

# E08 — Validação e Rollout

## Objetivo

Conduzir a validação do Content System com a Queila e um cliente piloto real, coletar métricas de sucesso das funcionalidades entregues nos epics P0 e P1, e executar o rollout gradual — garantindo que o sistema vai ao ar com confiança e com aprendizados documentados para orientar os epics P2.

## Por que esse epic

Nenhum sistema de conteúdo sobrevive ao primeiro contato com uso real sem ajustes. O E08 não é um "epic de QA" — é um epic de aprendizado estruturado. A Queila precisa validar se o DECIDA está representado corretamente, se os campos editoriais fazem sentido na prática de curadoria, e se o onboarding é suficiente. Um cliente piloto precisa conseguir navegar o banco sem ajuda. Os aprendizados do E08 com os epics P0/P1 informam o escopo e a ordem de implementação dos epics P2 (E06, E07).

## Escopo

- Sessão de validação com a Queila: walkthrough guiado dos módulos E01, E02, E03 em staging — coleta de feedback estruturado por módulo
- Piloto com 1 cliente real: acesso ao site com os módulos P0 e P1 ativos, observação de uso e coleta de feedback
- Métricas de sucesso documentadas: taxa de promoção com campos preenchidos, tempo médio de onboarding, taxa de erros/confusão no fluxo de curadoria
- Plano de rollout: sequência de abertura de acesso (staging → Queila → 1 piloto → demais clientes)
- Registro de aprendizados: documento `docs/specs/content-system/retros/retro-piloto-01.md` com: o que funcionou, o que confundiu, o que falta
- Atualização de prioridade dos epics P2 com base nos aprendizados

## Fora de escopo

- Validação dos Agentes 01 e 02 (dependem de E06/E07 que são P2)
- Campanhas de comunicação ou anúncio formal do sistema
- Métricas de negócio de longo prazo (conversão, vendas) — fora do escopo de V1

## Stories propostas

| ID | Título | Descrição |
|----|--------|-----------|
| S8.1-sessao-validacao-queila | Sessão de validação com Queila | Preparar roteiro de walkthrough (20-30min) cobrindo E01 (labels DECIDA), E02 (fluxo de promoção com campos), E03 (página como-usar). Aplicar em staging. Documentar feedback por módulo em `test-runs/validacao-queila-01.md`. |
| S8.2-setup-cliente-piloto | Setup do cliente piloto | Selecionar 1 cliente CASE para piloto. Dar acesso ao site (URL de produção ou staging com acesso restrito). Preparar roteiro de observação: tarefas que o cliente deve executar sem ajuda (ex: "encontre 3 referências de C+I+D"). |
| S8.3-coleta-metricas-piloto | Coleta de métricas do piloto | Após 1 semana de acesso do piloto: (1) query no Supabase para itens promovidos com/sem campos editoriais, (2) feedback verbal do cliente, (3) registro de erros/bugs encontrados. Documentar em `test-runs/metricas-piloto-01.md`. |
| S8.4-retro-aprendizados | Retro e registro de aprendizados | Redigir `retros/retro-piloto-01.md` com: o que funcionou bem, o que confundiu os usuários, bugs críticos encontrados, gaps de funcionalidade não previstos. Propor ajustes de prioridade para E06/E07 com base nos aprendizados. |
| S8.5-plano-rollout-gradual | Documentar plano de rollout | Definir e documentar sequência de rollout: staging interno → Queila → 1 piloto → abertura gradual. Critérios de go/no-go para cada fase. Publicar em `docs/specs/content-system/rollout-plan.md`. |

## Critérios de aceite do Epic

1. Sessão de validação com Queila realizada e feedback documentado por módulo.
2. Ao menos 1 cliente piloto usou o site por ao menos 5 dias sem suporte direto da Queila ou Kaique.
3. Taxa de promoção com campos preenchidos >= 90% nos itens promovidos durante o piloto.
4. Documento `retro-piloto-01.md` presente com seções: funcionou / confundiu / falta / próximos passos.
5. Plano de rollout documentado com critérios de go/no-go explícitos.
6. Nenhum bug crítico (perda de dados, promoção sem campos, erro 500 na UI) aberto no final do piloto.

## Dependências técnicas

- E01 concluído (DECIDA alinhado)
- E02 concluído (campos editoriais operacionais)
- E03 concluído (página /como-usar.html disponível)
- E04 concluído ou em estágio avançado (Agente 00 disponível para validação de interesse)
- Ambiente de staging no Vercel e Supabase configurado (ou uso do ambiente de produção com dados controlados)
- Acesso da Queila ao staging para sessão de validação

## Riscos

1. **Disponibilidade da Queila para a sessão de validação**: agenda cheia pode atrasar o E08. Mitigação: agendar sessão com pelo menos 1 semana de antecedência após E03 estar concluído.
2. **Cliente piloto não engaja**: piloto usa o site superficialmente e não fornece feedback útil. Mitigação: roteiro de tarefas específicas (S8.2) garante que o piloto sabe o que fazer; check-in no meio da semana.
3. **Bugs encontrados no piloto atrasam rollout**: issues de UX ou lógica podem surgir. Mitigação: plano de rollout (S8.5) tem critérios explícitos de go/no-go — bugs críticos bloqueiam próxima fase até correção.

## Métrica de sucesso

Rollout concluído para ao menos 3 clientes CASE com: zero bugs críticos abertos, taxa de promoção com campos editoriais >= 90%, e ao menos 1 insight documentado na retro que impacta diretamente a priorização de E06 ou E07.
