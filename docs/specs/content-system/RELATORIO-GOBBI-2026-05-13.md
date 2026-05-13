---
title: Sistema de Conteúdo CASE V1 — Status Final
type: status-report
date: 2026-05-13
audience: Felipe Gobbi
task_clickup: https://app.clickup.com/t/868j7ych3
produto: https://refs.casein.com.br
repo: https://github.com/case-company/case-refs
---

# Sistema de Conteúdo CASE — V1 entregue

> **Resumo de uma frase:** a central que você pediu no card 868j7ych3 está no ar em `refs.casein.com.br`, com 76 referências curadas pela Queila — cada uma com etapa DECIDA, linha de conteúdo, capa, transcrição e um Guia de uso editorial completo (quando usar / por que funciona / como adaptar).

---

## O que era pra ser feito (6 subtasks do card)

| # | Subtask | Status |
|---|---|---|
| 1 | Definir taxonomia oficial | ✅ Concluída |
| 2 | Estruturar a central (Notion descartado) | ✅ Concluída em site próprio |
| 3 | Curar primeira leva de referências | ✅ 76 refs no ar |
| 4 | Escrever guia de uso pro cliente | ✅ `/como-usar` publicado |
| 5 | Validar com uso real | 🟡 Protocolo pronto, sessões pendentes |
| 6 | Planejar fase 2 (APIs/automação) | ✅ Documento publicado |

---

## 1. Taxonomia oficial — DECIDA

A Queila consolidou os 4 pilares antigos (DESEJAR / DESCOBRIR / IDENTIFICAR / CONFIAR) em **3 grupos do método DECIDA**:

- **D+E** — Descoberta + Entendimento (60% do mix)
- **C+I+D** — Confiança + Identificação + Desejo (30%)
- **A** — Ação (10%, sobe em fase de vendas)

Cada referência também é classificada por **uma das 10 linhas de conteúdo** do método dela: Prova/Case, Contrassenso, História, Ganho, Análise, CIS/Identificação, Mecanismo, Objeção, Alerta, Comparação.

A regra do mix está documentada em `refs.casein.com.br/como-usar`.

---

## 2. A "casa" onde as referências moram

Em vez de Notion (você cancelou no comentário #2 do card), montei um **site próprio** com infra real:

- **Frontend** em `refs.casein.com.br`
- **Backend** em Supabase (Postgres + Edge Functions)
- **Pipeline de ingest** via n8n + Apify + transcrição local

O cliente entra direto no site, filtra por trilha (Mentoria/Clínica) + etapa DECIDA + formato, abre o card e tem tudo: o vídeo embutido, a transcrição completa e o Guia de uso editorial.

---

## 3. Primeira leva curada — 76 referências

A Queila entregou a curadoria V2 na planilha XLSX. Importei tudo pra dentro do banco e enriqueci com 3 passes:

| O quê | Onde veio | Resultado |
|---|---|---|
| Trilha, etapa DECIDA, linha de conteúdo, estrutura da abertura | Curadoria offline da Queila no XLSX | 76 / 76 |
| Capa, caption, perfil, likes, comentários, visualizações | Apify Instagram Scraper | 60 / 76 |
| Transcrição completa em pt-BR | Whisper rodando localmente | 51 / 76 |
| **Guia de uso editorial** (quando usar / por que funciona / como adaptar) | IA gerou com base em caption + transcrição + método DECIDA da Queila | **76 / 76** |

> Os 16 que ficaram sem capa/caption são posts privados ou removidos do Instagram.
> Os 25 sem transcrição são carrosséis sem áudio (já têm caption e Guia de uso).

**Exemplo concreto** — uma das 76 refs (linha "Análise / Decodificação", etapa C+I+D):

> **Quando usar:** Quando uma notícia grande do setor de saúde estoura e a audiência ainda não conectou o impacto com a rotina dela.
>
> **Por que funciona:** Ancora autoridade num fato verificável e entrega tese clara em 60s. O público descobre quem você é vendo você decifrar algo que ele já viu passar pela timeline.
>
> **Como adaptar:** Troque a notícia por uma mudança recente do seu nicho (nova resolução do conselho, estudo, tendência de procedimento) e mantenha a estrutura de fato + opinião técnica + 1 conclusão prática.

---

## 4. Guia de uso pro cliente

Página `refs.casein.com.br/como-usar` com 7 seções:

1. O que é DECIDA
2. Os 3 grupos (D+E, C+I+D, A) com cores e propósito de cada
3. A regra do mix 60/30/10
4. Como navegar o banco
5. O que cada campo do Guia de uso significa
6. Erros comuns ao consumir referências
7. Atalhos diretos

Cliente novo entra no site, lê a página em 5 minutos, sai sabendo usar.

---

## 5. Validação com uso real

**Status: protocolo pronto, sessões pendentes de agenda.**

Documento `docs/specs/content-system/roadmap-validacao-piloto.md` define:

- **3 sessões de 45 min** (Queila + 2 clientes piloto)
- **5 tarefas concretas** que o participante executa (entrar no site, ler o guia, encontrar uma referência, promover, mandar feedback)
- **Critérios PASS/FAIL** explícitos pra cada uma
- **Template de notas** padronizado pro observador

O que destrava: você ou Queila agendarem as 3 sessões.

---

## 6. Fase 2 — automação e APIs

Documento `docs/specs/content-system/fase-2-monitoramento-apis.md` com:

- 8 tarefas repetitivas mapeadas
- O que vale automatizar priorizado (V1.5 vs V2)
- Critérios pra escolher fonte/API (RapidAPI etc.)
- Matriz de riscos e custos
- Regra principal preservada do card: **"API entra para acelerar a operação. Não para decidir a lógica editorial."**

---

## Decisões tomadas no caminho

### Acordadas com Kaique

- **Site próprio em vez de Notion** — você já tinha pedido no card.
- **Curadoria offline da Queila (XLSX) é suficiente pra promover** — não precisa o curador preencher os 3 campos editoriais a mão. A IA preenche um rascunho a partir da caption + transcrição, e Queila ajusta o que quiser.
- **3 grupos DECIDA em vez dos 4 pilares antigos** — a Queila já tinha consolidado isso no método dela.

### Erros que eu cometi e corrigi no caminho (transparência)

- Inicialmente enxertei "4 agentes editoriais" no site (Mapa de Interesse, Download do Expert, Estrategista, Modelador) que não estavam no seu handoff. **Removido.**
- Inicialmente o mix DECIDA estava 70/30/10. **Corrigido pro 60/30/10** que está no material da Queila.
- Inicialmente o sistema bloqueava promoção sem os 3 campos editoriais preenchidos. **Relaxado** pra que a curadoria da Queila no XLSX já bastasse.

---

## O que tem de pendência conhecida

| Pendência | Quando entra |
|---|---|
| Queila revisar os 76 guias gerados pela IA | Quando ela tiver 1h pra spot-check |
| Sessões piloto de validação com 2 clientes reais | Quando você/Queila agendarem |
| Implementar a fase 2 de automação | V1.5 ou V2, sem prazo |
| Reprocessar os 16 posts privados/removidos | Quando aparecer alguém pra trocar a URL ou marcar como deletada |

---

## Links

- **Site público:** <https://refs.casein.com.br>
- **Banco de Trilhas:** <https://refs.casein.com.br/trilhas>
- **Guia DECIDA cliente-facing:** <https://refs.casein.com.br/como-usar>
- **Repo:** <https://github.com/case-company/case-refs>
- **Documentação completa:** [`docs/specs/content-system/`](https://github.com/case-company/case-refs/tree/main/docs/specs/content-system)
- **Changelog:** [`CHANGELOG.md`](https://github.com/case-company/case-refs/blob/main/docs/specs/content-system/CHANGELOG.md)

---

**Qualquer ajuste de escopo ou prioridade, me fala.**
