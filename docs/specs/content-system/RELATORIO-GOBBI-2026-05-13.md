---
title: Relatório para Felipe Gobbi — Sistema de Conteúdo V1
type: status-report
date: 2026-05-13
audience: Felipe Gobbi
status: ready-to-share
task_clickup: https://app.clickup.com/t/868j7ych3
produto: https://refs.casein.com.br
repo: https://github.com/case-company/case-refs
---

# Sistema de Conteúdo V1 — Status para Felipe Gobbi

## TL;DR

O **handoff do card 868j7ych3 está executado**, com **uma diferença de ferramenta acordada no caminho**: em vez de Notion, virou um site próprio (`refs.casein.com.br`) com Supabase + n8n + Apify. As 6 subtasks foram cobertas em código + dados reais. Os 76 itens da planilha V2 da Queila estão importados, classificados pelo método DECIDA, promovidos e visíveis em `/trilhas`.

**O que falta**:
1. Curadoria editorial dos 3 campos (`quando_usar` / `por_que_funciona` / `como_adaptar`) — Queila escreve ou geramos via LLM
2. Transcrição via Whisper local (Mac mini) — rodando em seguida
3. Validação com cliente real — protocolo pronto, falta agendar

---

## 1. Bate-bate do handoff (6 subtasks)

### Subtask 1 — Definir taxonomia oficial · ✅ Entregue

| Pedido handoff | Entregue |
|---|---|
| 4 pilares: DESEJAR/DESCOBRIR/IDENTIFICAR/CONFIAR | **Consolidados em DECIDA pela própria Queila** (3 grupos: D+E, C+I+D, A) — material canônico em `~/Downloads/copia projeto agentes/Manuais dos agentes/05_Base_Metodologica/metodologia_referencia_agentes.md` |
| Tipos de conteúdo | **10 linhas oficiais da Queila** como `tipo_estrategico` (Prova/Case/Autoridade, Contrassenso, História/Curiosidade, Ganho/Solução, CIS/Identificação, Mecanismo/Método, Análise, Comparação, Alerta, Objeção/Decisão) |
| Formatos | `tipo_artefato` enum: `reel / carrossel / story / publicacao_avulsa / destaque / post_fixado` |
| Regra de mix | **60% D+E · 30% C+I+D · 10% A** documentado em `/como-usar` |

**Onde isso vive**: `_decida.js` (single source of truth no frontend) + `etapa_funil` enum no banco + ADR-0001 + `guia-decida.md`.

### Subtask 2 — Estruturar a central no Notion · ✅ Entregue (em formato diferente)

> Felipe, lembra que no comentário #2 do card você escreveu "Notion foi descartado, primeira versão pode ser planilha"? Subimos um nível: virou **site próprio** com infra real.

| Pedido handoff | Entregue em `refs.casein.com.br` |
|---|---|
| Base de dados | `agente.referencias_conteudo` no Supabase, 85 itens em produção |
| Views (DESEJAR/DESCOBRIR/IDENTIFICAR/CONFIAR/Reels/Carrossel/Clínica/Mentoria) | Filtros em `/trilhas` por etapa DECIDA + trilha (Mentoria/Clínica) + formato |
| Página "Como usar" | `/como-usar` com 7 seções (DECIDA, mix, navegação, campos editoriais, erros comuns) |
| Campos da base | Todos os 13 campos do handoff cobertos + 4 campos editoriais novos |

### Subtask 3 — Curar a primeira leva · ✅ Entregue (76 refs importadas)

**Curadoria foi feita offline pela Queila no XLSX V2**:
- `~/Downloads/Chrome Rodrigues/[Case] Planilha de Referências de Conteúdo.xlsx`
- 80 linhas (40 Mentoria + 40 Clínica) já classificadas pela Queila
- Cada uma com: etapa DECIDA + linha de conteúdo + estrutura da abertura + formato + link

**Estado em produção** (`refs.casein.com.br/trilhas`):

| Métrica | Valor |
|---|---|
| Total importado | 76 (4 já existiam → dedup automático) |
| Por trilha | 40 scale (Mentoria) + 36 clinic (Clínica) |
| Por etapa DECIDA | 33 D+E + 41 C+I+D + 2 A |
| Por linha de conteúdo | 25 Prova / 10 Contrassenso / 8 História / 8 Ganho / 8 Análise / 7 Objeção / 6 CIS / 5 Mecanismo / 2 Alerta / 1 Comparação |
| Origem | `import_queila_xlsx_2026-05-12` (rastreável) |
| Promovidas em `/trilhas` | 76/76 (não estão no `/live` aguardando, já estão públicas) |

**Pendente**: preencher os 3 campos editoriais (`quando_usar` / `por_que_funciona` / `como_adaptar`) por ref. Não bloqueamos a publicação pra não atrasar — itens estão visíveis com a curadoria do XLSX já chega.

### Subtask 4 — Escrever guia de uso · ✅ Entregue

`refs.casein.com.br/como-usar` com 7 seções, linguagem cliente-friendly conforme handoff.

### Subtask 5 — Validar com uso real · 🟡 Protocolo pronto, sessões pendentes

`docs/specs/content-system/roadmap-validacao-piloto.md` define 3 sessões de 45 min (Queila + 2 clientes piloto) com 5 tarefas concretas e critérios PASS/FAIL. Aguardando agendamento.

### Subtask 6 — Planejar fase 2 (APIs/automação) · ✅ Entregue

`docs/specs/content-system/fase-2-monitoramento-apis.md` com:
- 8 tarefas repetitivas mapeadas
- O que vale automatizar priorizado (V1.5 vs V2)
- Critérios pra escolher fonte/API
- Matriz de risco
- Regra principal preservada: **"API entra para acelerar a operação. Não para decidir a lógica editorial."**

---

## 2. O que foi construído em `refs.casein.com.br`

### Frontend (Vercel, HTML estático + JS vanilla)

| Rota | Função |
|---|---|
| `/` | Landing com 4 cards (Trilhas, Posts, Cadastre, Como usar) |
| `/trilhas` | Banco curado — 76 refs filtráveis por trilha + etapa DECIDA + formato |
| `/posts` | Posts fixados + destaques |
| `/live` | Workflow editorial — admin onde curador promove novas refs |
| `/como-usar` | Guia DECIDA cliente-facing (7 seções + tour de primeira visita) |
| `/dashboard` | Métricas curadoria (escondido da landing) |
| `/feedback-admin` | Lista feedbacks recebidos via widget |

### Backend (Supabase Postgres + Edge Functions)

| Componente | O que faz |
|---|---|
| Schema `agente` | Tabelas privadas (refs + feedback) |
| View `v_referencias_publicas` | Whitelist explícita (sem `notas` interno) — fonte de `/trilhas` |
| View `v_referencias_promovidas` | Atalho para itens curados (deletadas/pendentes ficam de fora) |
| Edge Function `case-refs-mutate` | Endpoints REST pra ops do curador (update_note, soft_delete, etc.) |
| RPC `case_refs_promote_now` | Promove ref (campos editoriais opcionais) |
| RPC `case_refs_promote_batch` | Promove em massa (usado no import) |
| RPC `case_refs_import_batch` | Importa via JSONB com dedup por shortcode/URL |
| RPC `case_refs_enrich_batch` | Atualiza metadados Apify preservando campos editoriais |
| RPC `case_refs_feedback_submit` | Widget de feedback do cliente |

### Pipeline de ingest

- **n8n** webhook `webhook.manager01.feynmanproject.com/webhook/fila-referencias-novos` recebe novos cadastros
- **Apify** (`apify/instagram-scraper`) baixa metadados + cover + audio
- **AssemblyAI / Whisper local** transcreve áudio
- Insere em `agente.referencias_conteudo`

### Decisões arquiteturais (ADRs registrados)

1. **DECIDA é taxonomia oficial** (sem migration — relabel UX-only)
2. **Campos editoriais opcionais na promoção** (curadoria offline da Queila no XLSX já chega)
3. **Frontend permanece estático** com overlay dinâmico (sem SPA / React)
4. **Pipeline n8n existente é estendido**, não substituído

---

## 3. Como funciona o fluxo hoje (E2E)

```
Queila identifica ref no Instagram
      ↓
(opção A) cadastra no /live → n8n → Apify+AssemblyAI → /live
(opção B) importa em batch via XLSX (atalho da curadoria V2)
      ↓
Curador abre modal → opcionalmente preenche 3 campos editoriais
      ↓
Clica "Promover" → ref vai pro /trilhas (banco público)
      ↓
Cliente CASE acessa /trilhas → filtra por etapa DECIDA + trilha
      ↓
Cliente vê: thumb + caption + transcrição + Guia de uso editorial
      ↓
Cliente envia feedback via widget (canto inferior direito)
      ↓
Curador lê em /feedback-admin, ajusta
```

---

## 4. Decisões tomadas no caminho (alguma com seu visto necessário)

### ✅ Acordadas com Kaique

| Decisão | Por quê |
|---|---|
| Site próprio em vez de Notion | Você cancelou Notion no comment #2 do card. Site dá controle total + escala. |
| `etapa_funil` no DB sem migration | Métodos editoriais podem mudar; mudar o enum no banco custa downtime e risco |
| Frontend HTML+JS vanilla sem framework | Manutenibilidade > sofisticação. Vercel deploy de 30s |
| Curadoria via XLSX é suficiente pra promover | Os 3 campos editoriais ficam opcionais — Queila preenche se quiser, sem bloquear publicação |

### 🟡 Reverso no caminho (transparência)

- Inicialmente tinha enxertado **4 "agentes editoriais" como módulos no site** (Mapa de Interesse / Download do Expert / Estrategista / Modelador) baseado no material `~/Downloads/copia projeto agentes/`. **Não estava no handoff.** Removido em commit dedicado.
- Inicialmente o gatekeeper de promoção exigia 3 campos com >= 20 chars. **Bloqueou demais.** Relaxado pra opcionais.
- Mix DECIDA estava 70/30/0-10 com "Engajamento" e "Ação/Decisão". **Erros meus.** Corrigido pra 60/30/10 com "Entendimento" e "Ação" conforme material da Queila.

---

## 5. Dívidas conhecidas (pra fechar depois)

| Item | Status | Quando |
|---|---|---|
| Preencher 3 campos editoriais nas 76 refs | 🟡 Pendente Queila ou LLM | V1.5 |
| Transcrição via Whisper local das 76 refs | 🟡 Apify trouxe áudio, falta rodar Whisper no Mac mini | Esta semana |
| Sessões piloto de validação | 🟡 Roadmap pronto, falta agendar | Q3 |
| Implementar fase 2 APIs | 🔵 Doc pronto, sem prazo | V1.5+ |
| Subtarefa de feedback contínuo | ✅ Widget ativo + admin pronto | Já em uso |

---

## 6. Referências técnicas

- Repo: <https://github.com/case-company/case-refs>
- Docs completos: `docs/specs/content-system/` (PRD, spec técnica, ADRs, epics, stories)
- Test runs: `docs/specs/content-system/test-runs/` (smoke E2E PASS dos 2 fluxos críticos)
- Changelog: `docs/specs/content-system/CHANGELOG.md`
- 1.0.0 released em 2026-05-12

---

**Pronto pra qualquer ajuste de escopo ou prioridade — me fala o que destrava você.**
