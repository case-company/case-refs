---
title: Content System CASE — PRD V1
type: prd
status: draft-v0
date: 2026-05-12
owner: Kaique Rodrigues
sponsor: Queila Trizotti
version: 1.0.0
---

# 01 — Product Requirements Document (PRD V1)

> **Documento-fonte primário**: `00-context-and-handoff.md`
> **Princípio editorial**: nada aqui foi inventado. Tudo deriva do handoff Felipe Gobbi → Kaique, do estado atual do `refs.casein.com.br` e do método consolidado da Queila.

---

## 1. Visão e Missão

### Visão

Transformar o `refs.casein.com.br` no **sistema editorial canônico da CASE** — um repositório curado de referências de conteúdo, organizado pela taxonomia DECIDA da Queila, no qual cada referência carrega não só o link, mas a **inteligência editorial** (quando usar, por que funciona, como adaptar) que permite a um cliente CASE produzir conteúdo melhor sem depender da intuição de um estrategista sênior.

### Missão (V1)

Consolidar o handoff do projeto paralelo de "Sistema/Central de Conteúdo CASE" no `refs.casein.com.br`, adotar a taxonomia DECIDA da Queila como vocabulário oficial e entregar uma experiência de uso que sirva tanto ao curador interno quanto ao cliente CASE final.

---

## 2. Problema

O problema do Content System CASE não é único — são **dois problemas distintos** que compartilham o mesmo produto. Misturar os dois leva a soluções genéricas que não resolvem nenhum.

### 2.1 Problema do cliente final (dono de negócio mentorado pela CASE)

O dono de negócio que entra na mentoria CASE recebe a seguinte herança operacional:

- **Recebe um banco de referências** (Sheets, Notion, ou link bruto) com dezenas/centenas de posts, reels, carrosséis.
- **Não sabe quando usar cada um**. A taxonomia, quando existe, é por formato (Reels, Carrossel) — não por intenção editorial.
- **Não sabe por que aquele conteúdo funciona**. Vê o número (likes, views) mas não decompõe a alavanca (gancho? prova? identificação? autoridade?).
- **Não sabe como adaptar pro próprio nicho**. Copia conteúdo, não copia estrutura — e o resultado parece "café requentado".
- **Resultado**: o banco de referências vira biblioteca morta. O cliente continua dependente do estrategista CASE pra cada nova produção.

### 2.2 Problema operacional do time CASE

Em paralelo, o time interno CASE — Queila como autoridade editorial, Felipe Gobbi como tocador de projeto, Kaique como engenheiro — enfrenta:

- **Curadoria fragmentada**: referências boas vivem em Sheets, prints de WhatsApp, Notion abandonado, posts salvos no Insta de cada um.
- **Não escala**: cada novo cliente CASE recria a roda. Não existe "biblioteca canônica" de referências com inteligência editorial agregada.
- **Método não-empacotado**: a Queila tem o método DECIDA pronto no papel, mas ele não vive em UX nenhuma. O curador interno depende dela operar.
- **Tentativa anterior travou**: o projeto paralelo do Felipe Gobbi tentou Notion, recuou pra planilha, e fez handoff pro Kaique consolidar.

### 2.3 Síntese

Os dois problemas se resolvem com **a mesma intervenção**: um banco de referências curado com **campos editoriais obrigatórios** (quando usar / por que funciona / como adaptar) + a taxonomia DECIDA visível na UX + onboarding cliente-facing. O cliente final ganha autonomia. O time CASE ganha escala.

---

## 3. Personas

### 3.1 Persona A — Curador Interno CASE

| Atributo | Descrição |
|---|---|
| Quem é | Membro do time CASE (Queila como autoridade final, ou um curador delegado por ela) |
| Objetivo | Manter o banco de referências limpo, curado e útil. Promover só o que tem inteligência editorial associada |
| Contexto de uso | Abre o `/live` 1-3x por semana, revisa o que entrou via scraper, decide o que vira referência canônica |
| Fricção atual | Modal de promoção atualmente não exige campos editoriais. Promove sem contexto, polui o banco |
| Sucesso pra ele | Promoção rápida (≤2 min por item), com gatekeeper que força preenchimento mínimo |
| Não é | Um operador 100% interno fazendo curadoria 8h/dia. É um trabalho intermitente, alto critério |

### 3.2 Persona B — Cliente CASE (Dono de Negócio Mentorado)

| Atributo | Descrição |
|---|---|
| Quem é | Empreendedor mentorado pela CASE (clínica, consultoria, infoproduto, serviço — vertical CLINIC ou SCALE) |
| Objetivo | Produzir conteúdo que vende sem virar especialista em copy/marketing |
| Contexto de uso | Acessa quando vai planejar conteúdo (1-2x/semana). Quer "uma referência boa pra essa semana" |
| Fricção atual | `refs.casein.com.br` mostra 75 itens curados sem instrução de uso. Cliente não sabe por onde começar |
| Sucesso pra ele | Em ≤5 min: entender a taxonomia DECIDA, achar 2-3 referências aplicáveis ao próprio negócio nessa semana |
| Não é | Um estrategista de marketing experiente. Termos como "funil", "ICP", "moat" perdem ele |

### 3.3 Persona C — Estrategista de Conteúdo Terceirizado

| Atributo | Descrição |
|---|---|
| Quem é | Profissional contratado pelo cliente CASE pra tocar a operação editorial (social media, copy, gestor de tráfego com viés editorial) |
| Objetivo | Reduzir tempo de pesquisa. Bater referência → entender método → produzir |
| Contexto de uso | Acessa diariamente. Cruza referências com o briefing/diagnóstico do cliente que atende |
| Fricção atual | Não tem onde puxar "referência + método + insumo do expert" no mesmo lugar |
| Sucesso pra ele | Banco filtrável por DECIDA + Vertical, com cada referência trazendo guia de uso completo |
| Não é | Membro do time CASE. Não tem acesso aos manuais internos da Queila. Aprende pelo produto |

---

## 4. Princípios de Produto

Invariantes editoriais e técnicas. Cada princípio tem **razão**. Decisões de roadmap, escopo e UX referenciam esses princípios.

### P1 — Valor está no link COM explicação, nunca no link puro

**Razão**: link puro é commodity (qualquer um faz print). O valor que a CASE adiciona é a inteligência editorial agregada — quando usar, por que funciona, como adaptar. Sem isso, o produto é uma pasta de favoritos.

**Implicação**: campos editoriais são **obrigatórios na promoção** (gatekeeper). Não-negociável.

### P2 — Manual antes de automático

**Razão**: o método DECIDA da Queila só foi validado em operação manual. Automatizar antes de validar o manual = automatizar erro.

**Implicação**: V1 entrega o banco curado + workflow editorial com gatekeeper humano (3 campos obrigatórios). Automação adicional (coleta via APIs, geração assistida de campos) é planejada como fase 2 (ver §8 Roadmap e doc `fase-2-monitoramento-apis.md`).

### P3 — DECIDA é a única taxonomia editorial

**Razão**: o schema atual já tem `etapa_funil ∈ {DESCOBERTA, CONFIANCA, ACAO}`. O método DECIDA da Queila bate quase 1:1 (D+E / C+I+D / A). Manter duas taxonomias paralelas (formato + funil + DECIDA) confunde curador e cliente.

**Implicação**: relabel `CONFIANCA` → "C+I+D" no front. Documentar regra de mix (70/30/0-10) no guia de uso. Nada de criar coluna nova.

### P4 — O cliente CASE é o público primário do front, não o curador interno

**Razão**: a Persona B (cliente) usa o produto 10x mais que a Persona A (curador). Decisões de UX precisam priorizar quem mais usa.

**Implicação**: `/dashboard` fica escondido (já está). Página `/como-usar` é obrigatória pra V1. Linguagem do front é pra dono de negócio, não pra estrategista.

### P5 — Estrutura se copia, conteúdo não

**Razão**: defesa do produto contra "isso é só um banco de prints". Quem usa precisa saber que a estrutura/forma da referência é o que se copia, e o conteúdo se adapta ao próprio contexto.

**Implicação**: campo "como adaptar" guia a copia de estrutura, não de conteúdo. Deixa explícito que copiar literal é uso errado.

### P6 — Cliente nunca consome link puro

**Razão**: link sem explicação editorial não tem o diferencial CASE. Se for só link, qualquer screenshot serve.

**Implicação**: nenhum item entra no `/trilhas` sem os 3 campos preenchidos. A view pública (`v_referencias_publicas`) só expõe links que passaram pelo gatekeeper editorial.

### P7 — Notion está fora. Repo + Supabase é a fonte canônica

**Razão**: o time CASE tentou Notion, recuou pra planilha, e fez handoff pra reconsolidar. Voltar pra Notion é regredir 6 meses.

**Implicação**: tudo (refs, agentes, docs) vive no repo `case-company/case-refs` + Supabase. Sheets só como input/export pontual quando o handoff exigir.

---

## 5. Escopo V1

V1 = entregar o banco de referências curado + workflow editorial com gatekeeper humano + onboarding cliente, exatamente o que o handoff Felipe Gobbi pediu.

### 5.1 Banco de referências curado (extensão do que já existe)

**Já existe**:
- Schema `agente.referencias_conteudo` com campos básicos
- View `public.v_referencias_publicas`
- Edge Function `case-refs-mutate` com ops `update_note`, `update_tags`, `soft_delete`, `promote`, `unpromote`
- Pipeline ingest: n8n + Apify + AssemblyAI
- Páginas `/`, `/trilhas`, `/posts`, `/live`

**V1 adiciona**:
- 3 colunas editoriais obrigatórias na promoção:
  - `quando_usar TEXT` — em qual cenário/momento o cliente deve aplicar essa referência
  - `por_que_funciona TEXT` — qual alavanca editorial está em jogo (gancho, prova, identificação, autoridade, novidade, etc.)
  - `como_adaptar TEXT` — como copiar estrutura sem copiar conteúdo
- 1 coluna editorial complementar (P1 prioridade):
  - `objetivo_editorial TEXT CHECK IN ('Atrair', 'Identificar', 'Desejar', 'Confiar', 'Vender')` — separa o objetivo da etapa de funil
- Relabel UI: `etapa_funil.CONFIANCA` aparece como **"C+I+D"** no front (sem migration)
- Relabel UI: `trilha.clinic` aparece como **"Clínica"**, `trilha.scale` aparece como **"Mentoria/Consultoria"** (sem migration)
- Modal de promoção do `/live` exige os 3 campos `quando_usar`/`por_que_funciona`/`como_adaptar`. Sem eles, o botão "Promover" fica desabilitado
- Filtros nas páginas `/trilhas` e `/posts` por DECIDA (D+E / C+I+D / A) e Vertical (Clínica / Mentoria)

### 5.2 Planejamento da fase 2 — monitoramento e APIs

Documento separado: `fase-2-monitoramento-apis.md`. Captura o que pode entrar **depois** do V1 validado:

- Lista do que faz sentido automatizar (coleta de fontes, classificação, sugestão de campos editoriais).
- Campos mínimos que a automação teria que preencher.
- Critérios para escolher fonte/API (RapidAPI etc.).
- Riscos e cuidados (decisão editorial nunca delegada à API).

Regra principal do handoff: **API entra para acelerar a operação. Não para decidir a lógica editorial.**

### 5.3 Onboarding cliente — página "Como usar"

- Rota: `/como-usar.html`
- Acessível na landing (card próprio ou link no header)
- Conteúdo:
  - O que é o `refs.casein.com.br` (1 parágrafo, sem jargão)
  - Como funciona a taxonomia DECIDA (D+E / C+I+D / A) com exemplos visuais
  - Regra de mix 70/30/0-10 explicada
  - Como ler uma referência (quando usar / por que funciona / como adaptar)
  - Como rodar os 4 agentes (sequência + dependências)
  - FAQ (5-10 perguntas)
- Linguagem: pra dono de negócio (Persona B), não pra estrategista
- Princípio: P4 (cliente CASE é público primário)

### 5.4 Workflow de promoção com gatekeeper editorial

- Modal de promoção (`/live`) reescrito:
  - 3 campos editoriais obrigatórios visíveis (quando usar / por que funciona / como adaptar)
  - 1 campo objetivo editorial (dropdown com 5 opções)
  - Validação client-side + server-side (Edge Function rejeita promote sem os campos)
- Edge Function `case-refs-mutate` op `promote` atualizada:
  - Schema de input exige os 4 campos novos
  - Retorna erro 400 com mensagem clara se faltar campo
- Logging: cada promoção registra `promoted_by`, `promoted_at`, e snapshot dos campos editoriais

### 5.5 Documentação técnica e editorial

- ADRs:
  - `0001-decida-taxonomy.md` — adoção do DECIDA como taxonomia oficial
  - `0002-promotion-mandatory-fields.md` — campos editoriais obrigatórios na promoção
  - `0003-agentes-como-modulos-manual-first.md` — V1 = módulos manuais, não pipeline auto
  - `0004-supabase-canonical-storage.md` — Supabase é a fonte. Notion descartado
- Guia interno do curador (`docs/guides/curator-guide.md`)
- Guia editorial pra cliente (já está no `/como-usar.html`)

---

## 6. Fora de Escopo V1

Itens conscientemente excluídos. Cada exclusão tem razão.

| Item fora de V1 | Razão | Quando entra |
|---|---|---|
| Pipeline LLM gerando campos editoriais automaticamente | P2 (manual antes de automático). Validar gatekeeper humano primeiro | V1.5 ou V2 |
| Multi-fonte de ingest (RapidAPI, TikTok, YouTube além do Apify Insta) | n8n + Apify Insta cobre o uso atual. Adicionar fontes sem demanda = complexidade prematura. Doc `fase-2-monitoramento-apis.md` lista candidatos | V1.5 ou V2 (quando curador pedir) |
| Sistema de comentários/colaboração entre clientes | Não foi pedido no handoff | V3 ou nunca |
| App mobile dedicado | Web responsivo cobre 95% do uso real. App nativo é overkill pra V1 | Não previsto |
| Módulos de "agentes editoriais" como rotas no produto | Não foi pedido no handoff Felipe Gobbi. Material da Queila sobre o método dela vive em pasta separada | Não previsto |
| Login/auth pra cliente CASE | Hoje o produto é público. Acesso restrito muda o modelo. Validar uso primeiro | V2 (se houver demanda real de gating) |
| Migração de dados Notion/Sheets antigos | Handoff Felipe não tem volume crítico de dados pra migrar. Começar do zero é mais limpo | Nunca (descartado por D5 do handoff) |
| Integração com ClickUp/Asana | Time CASE já tem fluxo próprio. Forçar integração = atrito | V2+ se demandado |
| Métricas avançadas (heatmap, scroll depth, A/B test interno) | Volume de uso ainda não justifica. Métricas básicas (visitas, promoções) bastam pra V1 | V2 |
| API pública pra terceiros consumirem o banco | Risco de virar produto-de-API antes de validar produto-pra-humano | V2+ |

---

## 7. Métricas de Sucesso

Métricas pareadas: cada quantitativa tem uma qualitativa de contexto.

### 7.1 Quantitativas

| Métrica | Alvo V1 (mês 1 pós-launch) | Por quê |
|---|---|---|
| % refs promovidas com 3 campos editoriais preenchidos | ≥ 80% | Mede aderência ao gatekeeper (P1). Abaixo disso = curador burlou ou UX falhou |
| Tempo médio de promoção por item | ≤ 3 min | Curador não vai usar se for friccional. Acima de 5 min = modal precisa redesign |
| Refs ativas em `/trilhas` no fim do mês 1 | ≥ 100 (75 atuais + 25 novas curadas) | Banco precisa crescer de forma controlada. Crescimento zero = curadoria parada |
| Visitas únicas mês 1 ao `/como-usar` | ≥ 60% das visitas únicas à landing | Se cliente não acessa o onboarding, a UX da landing falhou em direcioná-lo |

### 7.2 Qualitativas

| Métrica | Como medir |
|---|---|
| Queila valida o sistema como "pronto pra entregar a um cliente novo da mentoria" sem ela operar manualmente | Conversa direta. Sim/não com justificativa |
| Cliente CASE piloto (1-2 mentorados) consegue achar 2 referências aplicáveis em ≤5 min sem ajuda | Teste de uso gravado, com 1-2 mentorados reais |
| Curador interno (Persona A) prefere usar o `refs.casein.com.br` ao Sheets antigo | Comparação direta após 2 semanas de uso |
| Estrategista terceirizado (Persona C) entende a taxonomia DECIDA sem precisar do manual interno | Onboarding cego: dar acesso e ver se opera sozinho em 30 min |

### 7.3 Anti-métricas (não otimizar)

- **Volume bruto de refs no banco**: maximizar volume contra qualidade quebra P1. Banco com 1000 refs sem campos editoriais é pior que banco com 100 refs com campos.
- **Tempo médio de sessão**: longo tempo de sessão pode significar UX confusa. Não é métrica de sucesso.
- **Número de agentes rodados**: rodar agente sem usar output é desperdício. Mede uso, não rodadas.

---

## 8. Roadmap Macro

Sem datas. Cada fase depende da anterior. Critério de avanço de fase = métricas de sucesso da fase atual atingidas.

### V1 — Fundação editorial (este PRD)

Entregáveis:
- Schema com 4 colunas editoriais novas + relabel UI
- Modal de promoção com gatekeeper editorial
- Página `/como-usar`
- 4 agentes editoriais como módulos manuais com UI dedicada
- Filtros DECIDA + Vertical no front
- ADRs 0001-0004 + guia do curador

Critério de avanço: métricas quantitativas V1 atingidas + Queila valida qualitativamente.

### V1.5 — Validação e refinamento

Entregáveis:
- Telemetria de uso (quem usa o quê, com que frequência)
- Coleta estruturada de feedback de cliente piloto
- Refinamento dos 4 agentes baseado em uso real
- Possível adição de fontes de ingest (se curador pedir)
- Templates pré-preenchidos pra acelerar promoção (sugestão de campos editoriais via LLM)

Critério de avanço: 30+ ciclos completos de uso real (Mapa → Download → Plano → Modelador) registrados, com taxa de "output utilizado" ≥ 60%.

### V2 — Automação editorial assistida

Entregáveis:
- Implementação da fase 2 conforme `fase-2-monitoramento-apis.md` (coleta multi-fonte + sugestão automática de campos editoriais com revisão humana)
- Sugestão automática de "ref relevante" baseada no perfil do cliente
- Possível auth/gating de acesso por cliente

Critério de avanço: pipeline V2 entrega resultado igual ou melhor que operação 100% manual em teste cego.

### V3 — Escala (não comprometido)

Entregáveis hipotéticos (sujeitos a demanda):
- API pública
- Multi-tenancy completo
- Relatórios automatizados pra cliente CASE
- Eventual oferta como produto SaaS standalone (decisão da Queila)

---

## 9. Riscos e Mitigações

Top 5 riscos que podem matar o V1.

### R1 — Curador burla o gatekeeper preenchendo campos editoriais com lixo

**Probabilidade**: alta (humanos buscam atalho)
**Impacto**: alto (princípio P1 cai, banco vira biblioteca morta de novo)
**Mitigação**:
- UI exige campos com mínimo de caracteres (ex.: 30 chars)
- Review semanal da Queila amostra 10% das promoções e marca as ruins
- Métrica pública (no `/dashboard` interno) de "taxa de campos válidos" por curador
- Treinamento do curador antes do go-live

### R2 — Cliente CASE não entende DECIDA mesmo com `/como-usar`

**Probabilidade**: média
**Impacto**: alto (Persona B é o público primário, P4)
**Mitigação**:
- Teste de uso com 2-3 clientes reais antes de empurrar pra mentoria toda
- Iterar copy do `/como-usar` baseado em onde travam
- Tooltip inline em cada referência explicando "esse é D+E porque..."
- Exemplos visuais (não só texto) na página de onboarding

### R3 — Os 4 agentes ficam complicados demais pra usar manualmente

**Probabilidade**: média (cada agente tem input rico)
**Impacto**: médio-alto (P2 cai, e o sistema vira "tem mas ninguém usa")
**Mitigação**:
- UI guiada passo-a-passo (não formulário gigante de uma vez)
- Possibilidade de salvar rascunho e voltar depois
- Templates pré-preenchidos pros agentes (ex.: Mapa de Interesse com exemplos por vertical)
- Instrumentação de drop-off: ver onde o usuário abandona

### R4 — Schema novo (4 colunas editoriais) quebra integrações existentes

**Probabilidade**: baixa (colunas são aditivas)
**Impacto**: médio
**Mitigação**:
- Migrations não-destrutivas (ADD COLUMN, nunca DROP)
- View `v_referencias_publicas` mantém retrocompatibilidade
- Edge Function valida no schema novo mas aceita refs antigas com campos vazios (legacy mode)
- Backfill incremental dos 75 itens já curados (curadoria humana, não automática)

### R5 — Queila não tem bandwidth pra validar os 4 agentes em V1

**Probabilidade**: média (ela é o gargalo de validação editorial)
**Impacto**: alto (sem validação dela, agentes podem estar errados)
**Mitigação**:
- Sequenciar: Mapa de Interesse e Download do Expert primeiro (mais maduros segundo STATUS_DOS_AGENTES)
- Estrategista e Modelador validados por amostra (3-5 ciclos cada, não validação exaustiva)
- Documentar validação parcial como tal (ADR ou changelog), não fingir que foi 100%

---

## 10. Stakeholders e RACI

### Papéis

| Papel | Pessoa | Responsabilidade |
|---|---|---|
| Sponsor + Autoridade Editorial | Queila Trizotti | Decisão final sobre método, validação dos agentes, prioridade editorial |
| Owner Técnico | Kaique Rodrigues | Arquitetura, implementação, ADRs, decisões técnicas |
| Tocador histórico do projeto paralelo | Felipe Gobbi (BU-CASE) | Handoff completo já feito. Consultoria pontual se necessário |
| Validador Cliente | 1-2 mentorados Case (a definir com Queila) | Teste de uso de V1, feedback estruturado |
| Curador Interno | Definido pela Queila (pode ser ela mesma no V1) | Operar promoção, validar campos editoriais |

### Matriz RACI por entregável

| Entregável | Responsible | Accountable | Consulted | Informed |
|---|---|---|---|---|
| Schema (4 colunas editoriais) | Kaique | Kaique | Queila (nomes dos campos) | Time CASE |
| Modal promoção com gatekeeper | Kaique | Kaique | Queila (UX) | Curador |
| Página `/como-usar` | Kaique | Queila | Kaique (impl), Cliente piloto (validação) | Time CASE |
| Doc `fase-2-monitoramento-apis.md` | Kaique | Kaique | Time CASE | — |
| ADRs 0001-0002, 0004-0005 | Kaique | Kaique | Queila (0001 e 0002) | Time CASE |
| Guia do curador | Kaique | Queila | Curador piloto | Time CASE |
| Validação V1 com cliente piloto | Queila | Queila | Kaique (instrumentação) | Cliente |

### Cadência de sincronização

- **Decisões técnicas**: Kaique decide e registra ADR. Queila informada.
- **Decisões editoriais**: Queila decide. Kaique implementa.
- **Conflito**: Queila tem palavra final em qualquer item que envolva método/conteúdo. Kaique tem palavra final em arquitetura técnica.
- **Cadência**: review quinzenal Queila × Kaique enquanto V1 está em desenvolvimento. Pós-launch, mensal.

---

## Anexo A — Trade-offs explícitos

Trade-offs feitos conscientemente em V1. Documentados pra que futura-Queila/futuro-Kaique não desfaçam por engano.

| Trade-off | Decisão | Custo aceito |
|---|---|---|
| Manual vs. Automático nos agentes | Manual (P2) | Operação mais lenta no V1, mas valida antes de automatizar erro |
| Gatekeeper editorial obrigatório vs. promoção rápida | Gatekeeper obrigatório (P1) | Curador leva mais tempo por item, mas banco mantém qualidade |
| Auth pra cliente vs. acesso público | Acesso público | Sem analytics por cliente, mas zero atrito de adoção |
| App mobile vs. web responsivo | Web responsivo | Sem app store, mas zero esforço de manutenção dupla |
| Multi-fonte ingest vs. só Apify Insta | Só Apify | Cobertura menor, mas pipeline já validado |
| Notion abandonado vs. continuar Sheets parcial | Notion abandonado, repo+Supabase canônico (P7) | Time precisa migrar mental, mas converge fonte |

---

## Anexo B — Glossário

- **DECIDA**: método editorial da Queila organizado em 3 blocos (D+E / C+I+D / A). Não é acrônimo letra-por-letra.
- **D+E**: Descoberta + Entendimento (~70% do mix editorial padrão).
- **C+I+D**: Confiança + Identificação + Desejo (~30% do mix).
- **A**: Ação / Decisão (0-10%, ramp em fase de vendas).
- **Trilha**: separação por vertical de cliente CASE (CLINIC para clínicas; SCALE para mentorias/consultorias/infoprodutos). Aparece como "Clínica" / "Mentoria" no front.
- **Promover**: ação de mover uma referência do estado pendente (`/live`) pro banco curado (`/trilhas`).

---

**Fim do PRD V1.**
Próximos artefatos a produzir: ADRs (0001-0004), Epics (E01-E08), Stories AIOX-format.
