---
title: Content System CASE — Especificação Técnica
type: spec-tech
status: v1
date: 2026-05-12
owner: Kaique Rodrigues
deciders: [Kaique, Queila, Felipe Gobbi]
related:
  - 00-context-and-handoff.md
  - 01-prd.md
  - adrs/0001-decida-taxonomy.md
  - adrs/0002-promotion-mandatory-fields.md
  - adrs/0004-frontend-stays-static-with-dynamic-overlay.md
  - adrs/0005-keep-n8n-pipeline-extend-not-replace.md
  - fase-2-monitoramento-apis.md
---

# 02 — Especificação Técnica do Content System CASE

Descrição técnica do que o `refs.casein.com.br` precisa para entregar o V1 conforme handoff Felipe Gobbi + método DECIDA da Queila.

A spec é **prescritiva**: o que vai ser construído. Decisões com trade-offs ficam nos ADRs. Quando houver conflito, ADR vence; spec é atualizada.

---

## 1. Arquitetura de Alto Nível

### 1.1 Visão de Camadas

```
+--------------------------------------------------------------------+
|                          USUÁRIOS                                   |
|  - Curadores (Queila, Kaique, Felipe)                               |
|  - Mentoradas/clientes Case (consumo das trilhas)                   |
+----------------------------+----------------------------------------+
                             |
                             v
+--------------------------------------------------------------------+
|       FRONTEND ESTÁTICO + DYNAMIC OVERLAY (Vercel)                  |
|                                                                     |
|   /                  → landing 4 cards                              |
|   /trilhas           → 75+ itens curados (estáticos + promovidos)   |
|   /posts             → posts fixados + destaques                    |
|   /live              → cadastros pendentes (badge ⏳)               |
|   /como-usar         → guia cliente (DECIDA + mix 60/30/10)         |
|   /dashboard         → curadoria (escondido da landing)             |
|                                                                     |
|   Stack: HTML estático + JS vanilla + fetch direto Supabase         |
+----------------------------+----------------------------------------+
                             |
                             v
+--------------------------------------------------------------------+
|                    SUPABASE (Postgres + Edge)                       |
|                                                                     |
|   Schema agente:                                                    |
|     - referencias_conteudo (extendida: 4 novas colunas editoriais)  |
|                                                                     |
|   Schema public:                                                    |
|     - v_referencias_publicas  (whitelist sem `notas`)               |
|     - v_referencias_promovidas (atalho de promovidos)               |
|     - case_refs_promote_editorial(id, 3 campos) RPC                 |
|     - case_refs_update_note / update_tags / soft_delete RPCs        |
|     - case_refs_unpromote RPC                                       |
|                                                                     |
|   Edge Functions:                                                   |
|     - case-refs-mutate (existente, estendida com promote_editorial) |
+----------------------------+----------------------------------------+
                             |
                             v
+--------------------------------------------------------------------+
|              PIPELINE DE INGEST (n8n + Apify + AssemblyAI)          |
|                                                                     |
|   n8n: webhook + classify + write                                   |
|   Apify: instagram-scraper / restricted_page detection              |
|   AssemblyAI: transcription                                         |
+--------------------------------------------------------------------+
```

### 1.2 Princípios Arquiteturais

1. **Frontend estático + overlay dinâmico** (ADR-0004): nada de SPA/Next/React. HTML+JS vanilla servido pelo Vercel; dados promovidos via fetch direto na view pública.
2. **Promoção é gatekeeper editorial** (ADR-0002): item só vira referência canônica se preencher 3 campos qualitativos (`quando_usar`, `por_que_funciona`, `como_adaptar`) com ≥ 20 caracteres cada.
3. **Pipeline existente é preservado** (ADR-0005): n8n + Apify + AssemblyAI continuam. Defesa contra `restricted_page` é patch, não rewrite.
4. **Taxonomia DECIDA é label, não migration** (ADR-0001): `etapa_funil` no banco continua `DESCOBERTA|CONFIANCA|ACAO`. UX renomeia.

---

## 2. Modelo de Dados

A tabela `agente.referencias_conteudo` é a única tabela de produto neste V1. Schema agente já existe e contém dados do ingest. As migrations V1 só **estendem** essa tabela (adicionam colunas + constraint) e reescrevem as views públicas.

### 2.1 Extensão da `agente.referencias_conteudo`

Migration: `20260513000000_referencias_conteudo_editorial_fields.sql`

```sql
-- 4 campos editoriais (todos TEXT, nullable em itens legados)
ALTER TABLE agente.referencias_conteudo
  ADD COLUMN IF NOT EXISTS quando_usar       TEXT,
  ADD COLUMN IF NOT EXISTS por_que_funciona  TEXT,
  ADD COLUMN IF NOT EXISTS como_adaptar      TEXT,
  ADD COLUMN IF NOT EXISTS objetivo          TEXT;

-- Constraint: linha promovida exige os 3 campos com >= 20 chars.
-- NOT VALID = não revalida itens já promovidos antes do release.
ALTER TABLE agente.referencias_conteudo
  ADD CONSTRAINT chk_promoted_requires_editorial_fields
  CHECK (
    promoted_at IS NULL
    OR (
      char_length(coalesce(quando_usar, '')) >= 20
      AND char_length(coalesce(por_que_funciona, '')) >= 20
      AND char_length(coalesce(como_adaptar, '')) >= 20
    )
  ) NOT VALID;

CREATE INDEX IF NOT EXISTS idx_refs_objetivo
  ON agente.referencias_conteudo (objetivo)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_refs_etapa_promoted
  ON agente.referencias_conteudo (etapa_funil, promoted_at)
  WHERE deleted_at IS NULL AND promoted_at IS NOT NULL;
```

### 2.2 Views públicas (whitelist sem `notas`)

Migrations: `20260512200000_safe_view_no_notas.sql` (safe-view inicial) e `20260513000100_views_expose_editorial.sql` (extensão com campos editoriais).

`v_referencias_publicas` (todos os itens não-deletados) e `v_referencias_promovidas` (atalho de promovidos) usam **whitelist explícita** de colunas, com derivações via `COALESCE`/`CASE` que existiam na view original:

- `resumo = COALESCE(titulo, "left"(caption, 80))`
- `thumb_url = COALESCE(cover_url, display_url)`
- `tem_transcricao = CASE WHEN length(transcricao) > 0 THEN true ELSE false END`

**INVARIANTE: `notas` (campo interno do curador) NUNCA aparece nessas views.** Antes de adicionar coluna nova aqui, conferir se ela pode ser exposta ao anon.

### 2.3 RPC `case_refs_promote_editorial`

Migration: `20260513000200_rpc_promote_editorial.sql`

```sql
CREATE OR REPLACE FUNCTION public.case_refs_promote_editorial(
  p_id              BIGINT,
  p_quando_usar     TEXT,
  p_por_que_funciona TEXT,
  p_como_adaptar    TEXT,
  p_objetivo        TEXT DEFAULT NULL
)
RETURNS TABLE(out_id BIGINT, out_promoted_at TIMESTAMPTZ)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, agente
...
```

Valida `>= 20` chars em cada campo + RAISE EXCEPTION semântico (`missing_editorial_fields: campo1,campo2`) com `ERRCODE = 'check_violation'`. Update inclui `promoted_at = NOW()`.

### 2.4 Tipagem

- `id` da tabela é `BIGSERIAL` (BIGINT). RPCs declaram BIGINT no input/output.
- OUT params dos RPCs nomeados com prefixo `out_` para evitar ambiguidade com colunas da tabela no `RETURNING`.

---

## 3. Edge Function `case-refs-mutate`

Path: `supabase/functions/case-refs-mutate/index.ts`

POST body com discriminador `op`:

| op | Body adicional | Resposta |
|---|---|---|
| `update_note` | `id`, `notas` | `{ok, op, data}` |
| `update_tags` | `id`, `tags: string[]` | `{ok, op, data}` |
| `soft_delete` | `id` | `{ok, op, data}` |
| `promote_editorial` | `id`, `quando_usar`, `por_que_funciona`, `como_adaptar`, `objetivo?` | `{ok, op, data}` ou `422 {ok:false, error, fields:[...]}` |
| `unpromote` | `id` | `{ok, op, data}` |

**Removido em V1**: `op: 'promote'` legacy — bloqueado pela constraint pós-E02.

Cliente Supabase usa `SUPABASE_SERVICE_ROLE_KEY` no header da chamada interna ao PostgREST.

---

## 4. Fluxos Críticos

### 4.1 Cadastro novo → Curadoria editorial → Promoção

```
n8n webhook ──► Apify scraper ──► AssemblyAI ──► INSERT agente.referencias_conteudo
                                                      │
                                                      v
                                                /live (badge ⏳)
                                                      │
                                          curador abre modal expandido
                                                      │
                                    ┌─────────────────┼────────────────┐
                                    │                 │                │
                              quando_usar      por_que_funciona  como_adaptar
                                   (≥ 20 chars cada)
                                                      │
                                  POST case-refs-mutate { op:'promote_editorial', ... }
                                                      │
                                       422 ◄──┤      ▼      ├──► 200
                                              │             │
                                              │   PostgreSQL constraint check
                                              │             │
                                          UI realça    promoted_at = NOW()
                                          campos                │
                                                                v
                                                          aparece em /trilhas
                                                          com seção "Guia de uso"
```

### 4.2 Onboarding do cliente novo

```
landing /  ──► clica card "Como usar"  ──► /como-usar
                                                │
                                                │ leitura do guia DECIDA
                                                ▼
                                          clica "Abrir /trilhas"
                                                │
                                                │ primeira visita:
                                                ▼
                                       _tour.js mostra 3 tooltips
                                                │
                                                │ fim do tour:
                                                ▼
                                       localStorage.caso-ref-toured=v1
                                                │
                                                ▼
                                           uso normal
```

---

## 5. Migrations Plan (ordem)

| # | Arquivo | Conteúdo |
|---|---|---|
| 1 | `20260512200000_safe_view_no_notas.sql` | DROP+CREATE `v_referencias_publicas` com whitelist (remove `notas`) |
| 2 | `20260513000000_referencias_conteudo_editorial_fields.sql` | 4 ALTER TABLE + CHECK NOT VALID + 2 índices |
| 3 | `20260513000100_views_expose_editorial.sql` | DROP+CREATE 2 views com whitelist + 4 campos editoriais |
| 4 | `20260513000200_rpc_promote_editorial.sql` | DROP+CREATE RPC + GRANT |

Aplicadas em prod via Dashboard SQL Editor (não via `supabase db push` devido ao histórico de migrations de outros repos no mesmo projeto).

---

## 6. Frontend — Mudanças

### 6.1 HTMLs existentes

| Arquivo | Mudança |
|---|---|
| `index.html` | 4 cards (Trilhas, Posts, Cadastre, Como usar). DECIDA labels na descrição |
| `trilhas.html` | Label "C+I+D" via `_decida.js`; modal expandido com seção "Guia de uso" condicional |
| `live.html` | Modal expandido com 3 textareas obrigatórias + contador "X/3 ≥ 20 chars" + link Guia DECIDA |
| `posts.html` | Apenas nav link "Como usar" |
| `dashboard.html` | Apenas nav link "Como usar" + labels DECIDA |

### 6.2 HTMLs novos

| Arquivo | Conteúdo |
|---|---|
| `como-usar.html` | Página pública DECIDA — 7 seções (o que é, 3 grupos, mix 60/30/10, navegação, campos editoriais, erros comuns, atalhos) |

### 6.3 Componentes JS reutilizáveis (vanilla, sem build)

| Arquivo | Função |
|---|---|
| `_auth.js` | Gate cliente-side simples (existente). PWA bootstrap |
| `_decida.js` | `window.DECIDA_MAP` — labels D+E/C+I+D/A + helpers (decidaLabel, decidaLabelLong, decidaBadge) |
| `_tour.js` | Tour de primeira visita em `/trilhas` — flag em localStorage, override via `?tour=1` |

### 6.4 Tabela de cores DECIDA (UX)

```
D+E   → azul    (#3b82f6) — recall do topo do funil
C+I+D → roxo    (#8b5cf6) — meio do funil
A     → vermelho (#ef4444) — convite à ação
```

Pills da `/como-usar` usam essas três cores. Badges em `/trilhas` e `/live` herdam as classes existentes do site (`badge-brand` / `badge-accent` / `badge-warning`).

---

## 7. Observabilidade

### 7.1 Logs

- Edge Function `case-refs-mutate`: log do `op` + `id` + status code em `console.log` (capturado pelo Supabase Functions logs).
- Promoções: registradas implicitamente pela coluna `promoted_at` (timestamp da operação).

### 7.2 Métricas básicas (V1)

| Métrica | Como medir |
|---|---|
| % itens promovidos com 3 campos preenchidos | `COUNT(promoted_at IS NOT NULL AND quando_usar IS NOT NULL) / COUNT(promoted_at IS NOT NULL)` — esperado: 100% após release |
| Itens promovidos por semana | `SELECT date_trunc('week', promoted_at), count(*) FROM agente.referencias_conteudo WHERE promoted_at IS NOT NULL GROUP BY 1` |
| 422 do `promote_editorial` | Contagem no log da Edge Function — proxy para fricção do gatekeeper |

### 7.3 Alertas (V1, low-fi)

Nenhum alerta automatizado em V1. Verificação manual semanal via `/dashboard`.

---

## 8. Segurança

### 8.1 RLS Policies

V1 mantém o modelo atual: `agente.referencias_conteudo` sem RLS pra escrita (RPCs SECURITY DEFINER bypassam). Views públicas são apenas leitura.

| Recurso | Anon | Authenticated | Service Role |
|---|---|---|---|
| View `v_referencias_publicas` | SELECT | SELECT | SELECT |
| View `v_referencias_promovidas` | SELECT | SELECT | SELECT |
| Tabela `agente.referencias_conteudo` | — | — | ALL (via service_role) |
| RPC `case_refs_*` | EXEC | EXEC | EXEC |

### 8.2 Secrets

- `SUPABASE_SERVICE_ROLE_KEY`, `APIFY_TOKEN`, `ASSEMBLYAI_KEY` → todos via Supabase Edge Fn env (nunca no front, nunca em git).

### 8.3 PII

- `notas` do curador é interna → fica em `agente.referencias_conteudo` mas **nunca** é exposta nas views públicas. Migration `20260512200000_safe_view_no_notas.sql` substituiu o `SELECT *` por whitelist explícita em `v_referencias_publicas` e `v_referencias_promovidas`. Regra: **antes de adicionar coluna nova a essas views, conferir se ela pode ser exposta ao anon.**

---

## 9. Critérios de Aceite Técnico (V1)

- [x] 4 colunas editoriais existem em `agente.referencias_conteudo`.
- [x] CHECK constraint `chk_promoted_requires_editorial_fields` em produção (NOT VALID — não retroativa).
- [x] Views públicas usam whitelist explícita, `notas` ausente.
- [x] RPC `case_refs_promote_editorial` retorna 422-equivalente (`check_violation`) com `missing_editorial_fields:campos` em falha.
- [x] Edge Function `case-refs-mutate` aceita `op: 'promote_editorial'` e devolve 422 estruturado.
- [x] Modal de `/live` bloqueia botão até 3 campos ≥ 20 chars.
- [x] `/trilhas` exibe seção "Guia de uso" condicional aos campos.
- [x] `/como-usar` acessível, conteúdo 100% estático.
- [x] Tour de primeira visita em `/trilhas` via `_tour.js`.

---

## 10. Fora de Escopo (V1)

- Pipeline LLM gerando os 3 campos editoriais (V1.5 / V2).
- Multi-fonte de ingest além do Apify Instagram (V1.5 — ver `fase-2-monitoramento-apis.md`).
- Sistema de comentários ou colaboração entre clientes (V3 ou nunca).
- App mobile dedicado (web responsivo cobre).
- Módulos "agentes editoriais" como rotas no produto — **não foi pedido no handoff**. Material do método interno da Queila (Mapa de Interesse / Download do Expert / Estrategista / Modelador) vive em pasta separada e é referência editorial, não escopo do produto.

---

**Fim da spec V1.**
