---
title: Fase 2 — Backlog de Monitoramento e APIs
type: backlog
status: draft-v1
date: 2026-05-12
owner: Kaique Rodrigues
related:
  - 00-context-and-handoff.md
  - 01-prd.md
---

# Fase 2 — Backlog de Monitoramento e APIs

> Pedido explícito do handoff Felipe Gobbi: "Mini briefing — Planejar a fase 2 de monitoramento e APIs". Esta subtarefa **não é para construir automação agora**. É para deixar claro o que pode entrar **depois**, quando o V1 já estiver validado em uso real (3-4 ciclos de curadoria com a Queila + 1-2 clientes piloto).

---

## 1. Contexto

V1 entregou:
- Banco de referências curado com 3 campos editoriais obrigatórios.
- Workflow manual de promoção `/live → /trilhas`.
- Onboarding cliente em `/como-usar`.

V1 deixou propositalmente fora:
- Automação de coleta multi-fonte (só Apify Instagram via n8n).
- Sugestão automatizada dos campos editoriais.
- Classificação automática de etapa DECIDA (curador escolhe manualmente hoje).

**Regra principal do handoff (não-negociável):**
> API entra para **acelerar a operação**. **Não para decidir a lógica editorial.** Decisão de etapa, escolha de campos editoriais e gating de promoção continuam humanos.

---

## 2. Tarefas repetitivas da operação manual hoje (candidatas a automação)

| # | Tarefa hoje | Frequência | Tempo médio estimado |
|---|---|---|---|
| T1 | Encontrar perfis novos para monitorar (Instagram, TikTok, YouTube) | semanal | ~30 min |
| T2 | Coletar postagens novas dos perfis monitorados | diária | 0 min (já é Apify automatizado, mas só Instagram) |
| T3 | Transcrever vídeos novos (AssemblyAI) | por item | 0 min (já automatizado) |
| T4 | Classificar etapa DECIDA inicial (D+E / C+I+D / A) | por item | ~15 s |
| T5 | Sugerir tipo estratégico (Educar / Conectar / Vender etc.) | por item | ~15 s |
| T6 | Identificar perfil **influente** em um nicho (ex: clínicas de estética em SP) | sob demanda | ~1 h por busca |
| T7 | Coletar métricas externas (curtidas, comentários, views) para priorizar | já automatizado | — |
| T8 | Filtrar duplicatas de URL antes de ingerir | já automatizado via n8n | — |

---

## 3. O que vale automatizar (priorizado)

### 3.1 Alta prioridade (V1.5)

**A. Coleta multi-fonte**
- Adicionar TikTok e YouTube ao pipeline Apify/n8n existente.
- Critério: começar com perfis que a Queila já segue, não com busca aberta.
- Risco: explosão de volume → curador fica sem mãos pra promover.
- Mitigação: filtro `min_followers` + `min_engagement_rate` antes de ingerir.

**B. Sugestão automática de etapa DECIDA (não-bloqueante)**
- Classifier LLM lê `caption` + `transcricao` e propõe `etapa_funil` no momento da ingestão.
- Curador vê a sugestão como **preenchimento default** no modal, mas pode trocar.
- Implementação: chamada para Qwen local (Mac mini Tailscale) com prompt curto + few-shot examples.
- **Não atualiza coluna no banco sem revisão humana.** Sugestão fica em metadado JSONB `_sugestoes`.

**C. Pré-rascunho dos 3 campos editoriais (não-bloqueante)**
- LLM gera draft inicial dos 3 campos a partir de `caption + transcricao`.
- Curador edita/aprova no modal — botão Promover ainda exige edição humana (validação de timestamp de edição vs criação).

### 3.2 Média prioridade (V2)

**D. Busca semântica reversa**
- Cliente cola um briefing/Mapa do próprio negócio em `/agentes-sugestao` (se existir) → sistema retorna top-N referências relevantes do banco baseado em embeddings.

**E. Detecção de drift de método**
- Alerta quando muitos itens promovidos não conseguem ser classificados em D+E / C+I+D / A — indica que o método precisa de revisão.

### 3.3 Baixa prioridade (V2+)

**F. Auto-curadoria assistida por padrões**
- Sistema sugere promover automaticamente itens que batem padrões já validados (ex: "todo Reel de Instagram com >50k views de perfil >100k seguidores e transcrição contendo palavra-chave X passa a ser candidato 'fast track'").
- **Sempre passa por revisão humana.**

---

## 4. Campos mínimos que a automação teria que preencher (sem decidir)

Pra qualquer item ingerido automaticamente, o sistema precisa garantir antes de inserir em `agente.referencias_conteudo`:

| Campo | Origem |
|---|---|
| `url` | scraper |
| `shortcode` ou `external_id` | scraper |
| `perfil` | scraper |
| `caption` | scraper |
| `cover_url` / `display_url` | scraper |
| `transcricao` | AssemblyAI quando aplicável |
| `language_code` | AssemblyAI |
| `audio_duration_ms` | AssemblyAI |
| `tipo_artefato` | scraper (post/reel/story/carousel) |
| `created_at` | now() |
| `deleted_at` | NULL |
| `promoted_at` | **NULL** (sempre. Promoção é humana) |
| `quando_usar` / `por_que_funciona` / `como_adaptar` | NULL ou sugestão em metadado, nunca direto na coluna |

---

## 5. Critérios para escolher fonte / API

Ordem de avaliação ao considerar uma nova fonte de coleta:

1. **Está em uso pelo time hoje?** Se a Queila/Kaique não consultam essa fonte hoje, não tem demanda real.
2. **Quanto custa em USD/mês no volume esperado?** Apify hoje custa ~$30/mês pra Instagram. Acima de $200/mês cumulativo o time precisa decidir.
3. **Tem rate limit que comprometa o pipeline?** Fontes que exigem captcha humano frequente não entram.
4. **A API entrega dados estruturados ou só HTML cru?** HTML cru triplica custo de manutenção.
5. **Existe redundância pública?** Se a info está em RSS/sitemap público, prefere isso a API paga.

**Candidatas avaliadas no handoff (sem decisão tomada):**
- RapidAPI Instagram Scraper (alternativa ao Apify) — não justificado enquanto Apify cobrir.
- RapidAPI TikTok — vale entrar quando o time começar a curar TikTok regularmente.
- YouTube Data API (oficial Google) — gratuita até cota, vale entrar quando virar fonte recorrente.
- TikTok Research API (oficial) — exige cadastro institucional, pode demorar.

---

## 6. Riscos e cuidados

### 6.1 Risco editorial
**Automação que decide.** Se o classifier LLM virar fonte de verdade pra etapa DECIDA sem revisão, em 6 meses o banco fica enviesado pelo modelo, não pelo método. **Mitigação**: sugestão sempre vive em coluna de metadado (`_sugestoes JSONB`), nunca sobrescreve campo canônico antes de revisão humana com timestamp.

### 6.2 Risco operacional
**Volume sem capacidade**. Adicionar TikTok pode 3x a fila de `/live`. **Mitigação**: filtro de qualidade na entrada (`min_followers`, `min_engagement`) + limite diário máximo de ingestão.

### 6.3 Risco de custo
**API silenciosamente cara**. Apify cobra por execução. **Mitigação**: alerta automático quando custo acumulado mensal > X (configurável). Dashboard de custos por fonte.

### 6.4 Risco de privacidade
**Dados pessoais sensíveis em transcrição**. Vídeos pessoais podem mencionar terceiros. **Mitigação**: revisão manual antes de promover. View pública nunca expõe `notas` (interno).

### 6.5 Risco de bloqueio de fonte
**Apify/Instagram pode mudar política a qualquer hora**. **Mitigação**: manter ao menos 2 fontes em produção quando V1.5 ampliar; ter pipeline manual de "cole link aqui" como fallback (já existe via `/live`).

---

## 7. O que continua humano mesmo na fase 2

- Decisão de **promover ou não** um item.
- Preenchimento final dos 3 campos editoriais.
- Escolha de etapa DECIDA (D+E / C+I+D / A) em caso de ambiguidade.
- Decisão de **arquivar** ou **deletar** uma referência.
- Aprovação de cada nova fonte (não automatizada pelo próprio sistema).

---

## 8. Critério de pronto deste documento

Este backlog está pronto quando:
- O time tem clareza do que pode entrar na fase 2 sem contaminar o foco do V1.
- Cada item tem responsável e quando vale entrar.
- Há matriz de risco/custo associada.
- Há linha clara entre "API que acelera" e "API que decide" — a segunda nunca entra.

---

## 9. Próximos passos imediatos

- [ ] V1 entrar em uso real por 3-4 ciclos de curadoria (mínimo 4 semanas).
- [ ] Capturar feedback do curador: quanto tempo gasta em cada step, qual fricção sente.
- [ ] Decidir T1 + T6 com base nesse feedback (encontrar perfis e busca por nicho).
- [ ] Só então abrir story de implementação 3.1.A ou 3.1.B.

Não há roadmap fechado de V1.5 ainda — propositalmente. **O time decide quando vale automatizar baseado em uso real, não em projeção.**
