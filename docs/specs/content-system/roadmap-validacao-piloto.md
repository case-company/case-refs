---
title: Roadmap de Validação com Cliente Real (Piloto V1)
type: roadmap
status: pronto-para-executar
date: 2026-05-12
owner: Kaique Rodrigues
---

# Roadmap de Validação — Piloto V1

> Pedido do handoff Felipe Gobbi: "Validação com uso real + onboarding". Esta peça **não foi entregue em V1.0.0** — fechei o release com smoke automatizado meu (curl), não com humano testando. Este documento define o protocolo pra fechar a dívida.

---

## 1. Quem participa

| Papel | Pessoa | Por que |
|---|---|---|
| Curador interno | Queila | Conhece o método. Vai testar o gatekeeper editorial e a fluência da promoção. |
| Cliente piloto 1 | A escolher (sugestão: alguém da turma atual, recém-onboardada) | Caso de uso real de "primeira visita". |
| Cliente piloto 2 | A escolher (sugestão: alguém da turma há ≥ 6 meses) | Caso de uso "consulta recorrente". |
| Observador | Kaique | Não interfere durante a sessão. Anota fricções. |

**Total**: 3 sessões de 30-45 min cada. Spread em 1 semana.

---

## 2. O que cada um testa (5 tarefas representativas)

Ordem importa: as tarefas vão da mais simples à mais complexa. Cada tarefa tem objetivo claro e critério PASS/FAIL.

### Tarefa 1 — Entrar no banco e entender o que é

- **Pra quem**: Mariza.
- **Setup**: abrir `refs.casein.com.br` direto, sem briefing prévio.
- **Critério PASS**: em ≤ 60 segundos a pessoa consegue dizer "isso aqui é um banco de referências de conteúdo organizado pelo método da Queila".
- **Critério FAIL**: precisa de explicação verbal ou desiste por confusão.
- **Sinal de fricção**: tempo > 30s pra entender o card "Como usar".

### Tarefa 2 — Ler o guia DECIDA

- **Pra quem**: Mariza.
- **Setup**: abrir `/como-usar`.
- **Critério PASS**: ao fim da leitura (~5 min), conseguir explicar com palavras próprias o que é cada um dos 3 grupos (D+E / C+I+D / A) e qual a regra de mix.
- **Critério FAIL**: não consegue diferenciar D+E de C+I+D ou esquece A.
- **Sinal de fricção**: pula seções sem ler. Pede pra eu explicar.

### Tarefa 3 — Filtrar e encontrar uma referência útil

- **Pra quem**: Mariza.
- **Setup**: instrução: "Você precisa postar conteúdo na fase C+I+D essa semana. Use o banco pra escolher uma referência."
- **Critério PASS**: encontra ≥ 2 candidatas em ≤ 3 min usando o filtro de etapa.
- **Critério FAIL**: clica em qualquer card aleatório sem usar o filtro.
- **Sinal de fricção**: não percebe o `<select>` de etapa. Reclama do label "C+I+D".

### Tarefa 4 — (Não se aplica neste piloto)

Pular — Mariza não vai promover refs (Queila já fez via XLSX). Avaliar separadamente com Queila se quiser testar o fluxo `/live` em produção real.
- **Critério PASS**: preenche os 3 campos editoriais com texto significativo (>= 20 chars cada), promove sem erro, item aparece em `/trilhas` com o "Guia de uso" visível.
- **Critério FAIL**: deixa um dos campos genérico ("post legal"), reclama do modal, ou desiste.
- **Sinal de fricção**: tempo > 5 min pra preencher. Cola placeholder sem editar.

### Tarefa 5 — Enviar feedback

- **Pra quem**: Mariza.
- **Setup**: ao fim da sessão, pedir: "Diga 1 coisa que você melhoraria no site."
- **Critério PASS**: encontra o botão "Feedback" no canto inferior direito e envia categorizado.
- **Critério FAIL**: precisa do meu apontamento pra ver o botão.

---

## 3. Como capturar feedback durante a sessão

### 3.1 Estrutura da sessão (45 min)

```
0:00–0:05  Setup + permissão pra observar (sem julgamento)
0:05–0:35  Execução das 5 tarefas (think-aloud — pede pra pessoa narrar o que está vendo)
0:35–0:45  Entrevista curta:
            - O que ficou confuso?
            - O que você usaria de novo?
            - Você indicaria pra um amigo? Por quê?
```

### 3.2 Notas do observador (template)

Pra cada sessão, criar `test-runs/piloto-<nome>-<data>.md` com:

```
- Participante: ___
- Data/hora: ___
- Browser/device: ___

## Tarefa 1
- Resultado: PASS / FAIL / PASS-COM-FRICCAO
- Tempo: __s
- Frase notável que a pessoa falou: "..."
- Frição observada: ...

[repetir pras tarefas 2-5]

## Entrevista
- Confuso: ...
- Voltaria: ...
- Indicaria: ...

## Veredito da sessão
- PASS / FAIL / ITERAR
- Top 3 mudanças pra iterar (em ordem):
  1. ...
  2. ...
  3. ...
```

### 3.3 Feedback estruturado dos próprios clientes

Independente da entrevista, o widget de feedback (E09-S1) está vivo em todas as páginas. Capturas via widget vão pra `agente.feedback_clientes` e ficam visíveis em `/feedback-admin`.

---

## 4. Critérios de PASS/FAIL do piloto inteiro

O V1 passa na validação se:

- ≥ 4 de 5 tarefas com PASS em pelo menos 2 das 3 sessões.
- 0 sessões de FAIL na tarefa 4 (gatekeeper editorial) — se Queila não consegue usar, não tem produto.
- ≥ 1 feedback espontâneo positivo registrado via widget durante o piloto.
- ≤ 3 itens distintos de fricção (não 3 ocorrências — 3 tipos diferentes de problema).

Se reprovar:
- FAIL na tarefa 4 → reabrir E02 (modal de curadoria).
- FAIL na tarefa 2 → reabrir E03 (onboarding `/como-usar` precisa reescrita).
- FAIL na tarefa 3 → reabrir E01 (label C+I+D / filtro UX).
- FAIL na tarefa 1 → reabrir landing (index.html).
- FAIL na tarefa 5 → reabrir E09-S1 (widget posição/visibilidade).

---

## 5. Plano de iteração pós-validação

1. **Cada FAIL** vira issue/story nomeada `piloto-fix-<area>-<n>`.
2. **Cada feedback** capturado via widget é triado em ≤ 72h e:
   - se for confuso ou erro → vira issue.
   - se for sugestão → entra no backlog de V1.5.
   - se for elogio → registra como sinal positivo (não vira nada acionável).
3. Re-rodar **a tarefa que falhou** com a mesma pessoa após o fix. Sem segunda sessão completa.

---

## 6. Como o handoff fica fechado

Esta dívida do handoff fecha quando:

- [ ] 3 sessões piloto executadas (Queila + 2 clientes).
- [ ] 3 `test-runs/piloto-*.md` salvos no repo.
- [ ] Veredito agregado registrado em `test-runs/piloto-veredito-2026-XX-XX.md`.
- [ ] Issues abertas pros FAILs identificados.
- [ ] V1.0.1 (ou V1.1.0) released com os fixes do piloto, se houver.

---

## 7. Bloqueios atuais

- **Não posso conduzir sessão sozinho** — depende da disponibilidade da Queila + 2 clientes piloto.
- **Roadmap pode entrar sem dependências** assim que houver agenda definida.

Próximo passo: Kaique agendar 3 slots com os participantes (sugestão: spread em 5 dias úteis).
