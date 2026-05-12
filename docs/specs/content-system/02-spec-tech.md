---
title: Content System CASE — Especificação Técnica
type: spec-tech
status: draft-v1
date: 2026-05-12
owner: Kaique Rodrigues
deciders: [Kaique, Queila, Felipe Gobbi]
related:
  - 00-context-and-handoff.md
  - 01-prd.md
  - adrs/0001-decida-taxonomy.md
  - adrs/0002-promotion-mandatory-fields.md
  - adrs/0003-agents-as-modules.md
  - adrs/0004-frontend-stays-static-with-dynamic-overlay.md
  - adrs/0005-keep-n8n-pipeline-extend-not-replace.md
---

# 02 — Especificação Técnica do Content System CASE

Este documento descreve a arquitetura técnica completa do **Content System CASE** — produto unificado que assume o handoff do Felipe Gobbi (BU-CASE), incorpora o método consolidado da Queila (DECIDA + 4 agentes editoriais) e expande o `refs.casein.com.br` pro escopo completo.

A spec é **prescritiva**: o que vai ser construído. Decisões com trade-offs ficam nos ADRs (`adrs/0001..0005`). Quando houver conflito, ADR vence; spec é atualizada.

---

## 1. Arquitetura de Alto Nível

### 1.1 Visão de Camadas

```
+--------------------------------------------------------------------+
|                          USUÁRIOS                                   |
|  - Curadores (Queila, Kaique, Felipe)                               |
|  - Mentoradas/clientes Case (consumo das trilhas)                   |
|  - Operadores dos agentes (Kaique inicialmente, depois Queila)      |
+----------------------------+----------------------------------------+
                             |
                             v
+--------------------------------------------------------------------+
|       FRONTEND ESTÁTICO + DYNAMIC OVERLAY (Vercel)                  |
|                                                                     |
|   /                  → landing 3 cards (Trilhas / Posts / Cadastro) |
|   /trilhas           → 75 itens estáticos + fetch promovidos        |
|   /posts             → posts fixados                                |
|   /live              → cadastros pendentes (badge ⏳)               |
|   /como-usar         → guia cliente (DECIDA + mix 70/30/0-10)       |
|   /dashboard         → curadoria (escondido da landing)             |
|                                                                     |
|   /agentes/                                                         |
|     ├── mapa-interesse        → Agente 00 (form + render)           |
|     ├── download-expert       → Agente 00.5 (form + render)         |
|     ├── plano-editorial       → Agente 01 (form + render)           |
|     └── modelador             → Agente 02 (form + render)           |
|                                                                     |
|   Stack: HTML estático + JS vanilla + fetch direto Supabase         |
|          (anon key) ou Edge Function (service_role)                 |
+----------------------------+----------------------------------------+
                             |
                             v
+--------------------------------------------------------------------+
|                    SUPABASE (Postgres + Edge)                       |
|                                                                     |
|   Schema agente:                                                    |
|     - referencias_conteudo  (extendido: 4 novas colunas)            |
|     - mapas_interesse       (novo)                                  |
|     - downloads_expert      (novo)                                  |
|     - planos_editoriais     (novo)                                  |
|     - roteiros_modelados    (novo)                                  |
|                                                                     |
|   Schema public:                                                    |
|     - v_referencias_publicas       (view existente, estendida)      |
|     - v_referencias_promovidas     (nova: só promoted_at NOT NULL)  |
|     - case_refs_promote(id, fields…)  (RPC estendida)               |
|     - case_refs_promote_v2(id, jsonb) (nova, com 3 campos obrig)    |
|     - case_agente_*  (RPCs novas dos 4 agentes)                     |
|                                                                     |
|   Edge Functions:                                                   |
|     - case-refs-mutate            (estendida: promote_with_fields)  |
|     - case-agente-mapa            (nova)                            |
|     - case-agente-download        (nova)                            |
|     - case-agente-estrategista    (nova, futuro V1.5)               |
|     - case-agente-modelador       (nova)                            |
+----------------------------+----------------------------------------+
                             |
                             v
+--------------------------------------------------------------------+
|              PIPELINE DE INGESTÃO (n8n self-host VPS)               |
|                                                                     |
|   Ingest atual (mantido):                                           |
|   webhook /ingest → Apify(instagram-scraper) → AssemblyAI →         |
|   POST agente.referencias_conteudo (badge ⏳)                       |
|                                                                     |
|   Patches V1:                                                       |
|     - retry+fallback Apify restricted_page (ADR-0005)               |
|     - dedup por shortcode antes de inserir                          |
|     - tag origem={instagram_apify, manual, …}                       |
|                                                                     |
|   Workflows novos pra agentes:                                      |
|     - wf_agente_00_mapa            (cron diário + on-demand)        |
|     - wf_agente_00_5_download      (on-demand)                      |
|     - wf_agente_02_modelador       (on-demand, recebe URL ref)      |
|                                                                     |
|   LLMs: Claude (Anthropic) ou Qwen local via Mac mini Tailscale     |
+--------------------------------------------------------------------+
```

### 1.2 Princípios Arquiteturais

1. **Frontend estático + overlay dinâmico** (ADR-0004): nada de SPA/Next/React. HTML+JS vanilla servido pelo Vercel; dados promovidos via fetch direto na view pública.
2. **Cada agente = módulo independente** (ADR-0003): tabela própria, Edge Function própria, página própria. Zero coupling entre agentes — Agente 02 funciona sem Agente 00.
3. **Promoção é gatekeeper editorial** (ADR-0002): item só vira referência canônica se preencher 3 campos qualitativos.
4. **Pipeline existente é preservado** (ADR-0005): n8n + Apify + AssemblyAI continuam. Defesa contra `restricted_page` é patch, não rewrite.
5. **Taxonomia DECIDA é label, não migration** (ADR-0001): `etapa_funil` no banco continua `DESCOBERTA|CONFIANCA|ACAO`. UX renomeia.

---

## 2. Modelo de Dados

### 2.1 Extensão da `referencias_conteudo`

Migration: `20260513000000_referencias_conteudo_editorial_fields.sql`

```sql
-- Campos editoriais obrigatórios na promoção (ADR-0002)
ALTER TABLE agente.referencias_conteudo
  ADD COLUMN IF NOT EXISTS quando_usar       TEXT,
  ADD COLUMN IF NOT EXISTS por_que_funciona  TEXT,
  ADD COLUMN IF NOT EXISTS como_adaptar      TEXT,
  ADD COLUMN IF NOT EXISTS objetivo          TEXT;

-- Constraint: se promovido, os 3 campos críticos têm que estar preenchidos
ALTER TABLE agente.referencias_conteudo
  ADD CONSTRAINT chk_promoted_requires_editorial_fields
  CHECK (
    promoted_at IS NULL
    OR (
      char_length(coalesce(quando_usar, '')) >= 20
      AND char_length(coalesce(por_que_funciona, '')) >= 20
      AND char_length(coalesce(como_adaptar, '')) >= 20
    )
  );

-- objetivo pode ser livre por enquanto, mas com hint dos valores canônicos
COMMENT ON COLUMN agente.referencias_conteudo.objetivo IS
  'Atrair | Identificar | Desejo | Confiar | Vender (separado de etapa_funil)';

-- Índices novos
CREATE INDEX IF NOT EXISTS idx_refs_objetivo
  ON agente.referencias_conteudo (objetivo)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_refs_etapa_promoted
  ON agente.referencias_conteudo (etapa_funil, promoted_at)
  WHERE deleted_at IS NULL AND promoted_at IS NOT NULL;

-- View pública estendida — whitelist explícita SEM `notas` (campo interno do curador).
-- Migration 20260512200000_safe_view_no_notas.sql já trocou SELECT * por whitelist;
-- aqui a gente só ESTENDE com os campos editoriais novos (sem reintroduzir `notas`).
CREATE OR REPLACE VIEW public.v_referencias_publicas AS
  SELECT
    id, perfil, trilha, tipo_artefato, posicao, url, shortcode, formato,
    caption, display_url, video_url, cover_url, titulo,
    likes, comments, views, timestamp_post,
    transcricao, language_code, audio_duration_ms,
    tipo_estrategico, etapa_funil, objetivo,
    quando_usar, por_que_funciona, como_adaptar,
    tags, promoted_at, created_at, updated_at
  FROM agente.referencias_conteudo
  WHERE deleted_at IS NULL;

-- View especializada de promovidos (atalho pro front) — também SEM `notas`.
CREATE OR REPLACE VIEW public.v_referencias_promovidas AS
  SELECT
    id, perfil, trilha, tipo_artefato, posicao, url, shortcode, formato,
    caption, display_url, video_url, cover_url, titulo,
    likes, comments, views, timestamp_post,
    transcricao, language_code, audio_duration_ms,
    tipo_estrategico, etapa_funil, objetivo,
    quando_usar, por_que_funciona, como_adaptar,
    tags, promoted_at
  FROM agente.referencias_conteudo
  WHERE deleted_at IS NULL AND promoted_at IS NOT NULL
  ORDER BY promoted_at DESC;

GRANT SELECT ON public.v_referencias_promovidas TO anon, authenticated;
```

### 2.2 Tabela `mapas_interesse` (Agente 00)

Migration: `20260513001000_mapas_interesse.sql`

```sql
CREATE TABLE IF NOT EXISTS agente.mapas_interesse (
  id              BIGSERIAL PRIMARY KEY,
  cliente_slug    TEXT NOT NULL,                         -- 'queila', 'jordanna' etc.
  versao          INT NOT NULL DEFAULT 1,                -- versionamento livre
  titulo          TEXT NOT NULL,
  -- Inputs
  publico         JSONB NOT NULL,                        -- { quem, nivel, contexto, faixa_etaria, ... }
  oferta          JSONB NOT NULL,                        -- { promessa, ticket, formato, ... }
  sinais_externos JSONB,                                 -- { youtube:[…], tiktok:[…], comentarios:[…] }
  -- Output (12 gavetas)
  gavetas         JSONB NOT NULL,                        -- {dores:[…], desejos:[…], medos:[…], duvidas:[…], erros:[…], crencas:[…], valores:[…], comparacoes:[…], cenas:[…], identidades:[…], inimigos:[…], referencias:[…]}
  top_assuntos    JSONB,                                 -- top N priorizados
  -- Provenance
  modelo_llm      TEXT,                                  -- 'claude-opus-4', 'qwen-2.5-72b-local'
  prompt_versao   TEXT,                                  -- 'agente_00_v3'
  custo_usd       NUMERIC(8,4),
  duracao_ms      INT,
  -- Lifecycle
  status          TEXT NOT NULL DEFAULT 'draft'
                  CHECK (status IN ('draft','aprovado','arquivado')),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  approved_at     TIMESTAMPTZ,
  deleted_at      TIMESTAMPTZ,
  UNIQUE (cliente_slug, versao)
);

CREATE INDEX idx_mapas_cliente ON agente.mapas_interesse (cliente_slug)
  WHERE deleted_at IS NULL;
CREATE INDEX idx_mapas_status ON agente.mapas_interesse (status)
  WHERE deleted_at IS NULL;
```

### 2.3 Tabela `downloads_expert` (Agente 00.5)

Migration: `20260513002000_downloads_expert.sql`

```sql
CREATE TABLE IF NOT EXISTS agente.downloads_expert (
  id              BIGSERIAL PRIMARY KEY,
  cliente_slug    TEXT NOT NULL,
  mapa_id         BIGINT REFERENCES agente.mapas_interesse(id) ON DELETE SET NULL,
  versao          INT NOT NULL DEFAULT 1,
  titulo          TEXT NOT NULL,
  -- Repositório
  crencas         JSONB,                                 -- [{tese, contexto, prova}]
  teses           JSONB,
  provas          JSONB,                                 -- cases, métricas, depoimentos
  historias       JSONB,                                 -- storytelling pessoal/profissional
  metodo          JSONB,                                 -- pilares, etapas, princípios
  linguagem       JSONB,                                 -- frases próprias, jargões, bordões
  fontes          JSONB,                                 -- entrevistas, áudios, calls
  -- Provenance
  modelo_llm      TEXT,
  prompt_versao   TEXT,
  custo_usd       NUMERIC(8,4),
  duracao_ms      INT,
  status          TEXT NOT NULL DEFAULT 'draft'
                  CHECK (status IN ('draft','aprovado','arquivado')),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  approved_at     TIMESTAMPTZ,
  deleted_at      TIMESTAMPTZ,
  UNIQUE (cliente_slug, versao)
);

CREATE INDEX idx_downloads_cliente ON agente.downloads_expert (cliente_slug)
  WHERE deleted_at IS NULL;
CREATE INDEX idx_downloads_mapa ON agente.downloads_expert (mapa_id);
```

### 2.4 Tabela `planos_editoriais` (Agente 01)

Migration: `20260513003000_planos_editoriais.sql`

```sql
CREATE TABLE IF NOT EXISTS agente.planos_editoriais (
  id              BIGSERIAL PRIMARY KEY,
  cliente_slug    TEXT NOT NULL,
  mapa_id         BIGINT REFERENCES agente.mapas_interesse(id) ON DELETE SET NULL,
  download_id     BIGINT REFERENCES agente.downloads_expert(id) ON DELETE SET NULL,
  versao          INT NOT NULL DEFAULT 1,
  titulo          TEXT NOT NULL,
  -- Inputs
  fase            TEXT NOT NULL CHECK (fase IN ('D+E','VENDAS','MISTO')),
  capacidade      JSONB NOT NULL,                        -- { posts_dia, stories_dia, reels_semana }
  historico       JSONB,                                 -- snapshot do que já saiu
  mix_alvo        JSONB NOT NULL,                        -- { D_E:0.7, C_I_D:0.3, A:0.0 } default
  -- Output
  banco_ideias    JSONB NOT NULL,                        -- [{linha, objetivo, insumo_publico, insumo_expert, tensao_captura, gancho}]
  cronograma      JSONB,                                 -- [{data, ideia_id, formato, canal}]
  -- Validação interna (Agente 01 critério crítico)
  valido          BOOLEAN GENERATED ALWAYS AS (
    jsonb_typeof(banco_ideias) = 'array'
    AND jsonb_array_length(banco_ideias) > 0
  ) STORED,
  -- Provenance
  modelo_llm      TEXT,
  prompt_versao   TEXT,
  custo_usd       NUMERIC(8,4),
  duracao_ms      INT,
  status          TEXT NOT NULL DEFAULT 'draft'
                  CHECK (status IN ('draft','aprovado','arquivado')),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  approved_at     TIMESTAMPTZ,
  deleted_at      TIMESTAMPTZ,
  UNIQUE (cliente_slug, versao)
);

CREATE INDEX idx_planos_cliente ON agente.planos_editoriais (cliente_slug)
  WHERE deleted_at IS NULL;
```

### 2.5 Tabela `roteiros_modelados` (Agente 02)

Migration: `20260513004000_roteiros_modelados.sql`

```sql
CREATE TABLE IF NOT EXISTS agente.roteiros_modelados (
  id              BIGSERIAL PRIMARY KEY,
  cliente_slug    TEXT NOT NULL,
  -- Input: referência externa (pode estar no banco ou ser URL solta)
  referencia_id   BIGINT REFERENCES agente.referencias_conteudo(id) ON DELETE SET NULL,
  referencia_url  TEXT,                                  -- fallback se não está no banco
  formato_visual  TEXT NOT NULL CHECK (formato_visual IN
                    ('reel','carrossel','story','live','post_estatico','video_longo')),
  ideia_alvo      TEXT NOT NULL,                         -- ideia do plano editorial sendo encaixada
  plano_id        BIGINT REFERENCES agente.planos_editoriais(id) ON DELETE SET NULL,
  -- Output
  estrutura       JSONB NOT NULL,                        -- esqueleto preservado (cenas, ganchos, transições)
  roteiro         JSONB NOT NULL,                        -- conteúdo adaptado (texto, fala, CTAs)
  observacoes     TEXT,                                  -- "estrutura preserva, conteúdo adapta — não copiar X"
  -- Provenance
  modelo_llm      TEXT,
  prompt_versao   TEXT,
  custo_usd       NUMERIC(8,4),
  duracao_ms      INT,
  status          TEXT NOT NULL DEFAULT 'draft'
                  CHECK (status IN ('draft','aprovado','arquivado','publicado')),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  approved_at     TIMESTAMPTZ,
  published_at    TIMESTAMPTZ,
  deleted_at      TIMESTAMPTZ,
  CHECK (referencia_id IS NOT NULL OR referencia_url IS NOT NULL)
);

CREATE INDEX idx_roteiros_cliente ON agente.roteiros_modelados (cliente_slug)
  WHERE deleted_at IS NULL;
CREATE INDEX idx_roteiros_referencia ON agente.roteiros_modelados (referencia_id);
CREATE INDEX idx_roteiros_plano ON agente.roteiros_modelados (plano_id);
```

### 2.6 Diagrama ER (resumido)

```
+------------------------+        +---------------------+
| referencias_conteudo   |        | mapas_interesse     |
|------------------------|        |---------------------|
| id (PK)                |        | id (PK)             |
| ... (campos atuais)    |        | cliente_slug        |
| quando_usar      [NEW] |        | gavetas (JSONB)     |
| por_que_funciona [NEW] |        | top_assuntos        |
| como_adaptar     [NEW] |        +----------+----------+
| objetivo         [NEW] |                   |
| promoted_at            |                   v
+-----------+------------+        +---------------------+
            ^                     | downloads_expert    |
            |                     |---------------------|
            |                     | id (PK)             |
            |                     | mapa_id (FK)        |
            |                     | crencas/teses/...   |
            |                     +----------+----------+
            |                                |
            |                                v
            |                     +---------------------+
            |                     | planos_editoriais   |
            |                     |---------------------|
            |                     | id (PK)             |
            |                     | mapa_id (FK)        |
            |                     | download_id (FK)    |
            |                     | banco_ideias (JSONB)|
            |                     +----------+----------+
            |                                |
            +-------+                        |
                    |                        v
            +-------+----------------+ +------------+
            | roteiros_modelados                    |
            |---------------------------------------|
            | id (PK)                               |
            | referencia_id (FK referencias_conteudo)|
            | plano_id (FK planos_editoriais)       |
            | estrutura/roteiro (JSONB)             |
            +---------------------------------------+
```

---

## 3. APIs e Contratos

### 3.1 Edge Function `case-refs-mutate` — operações estendidas

**Endpoint**: `POST {SUPABASE_URL}/functions/v1/case-refs-mutate`

#### 3.1.1 `op: promote_with_fields` (NOVO — substitui `promote` em V1)

**Request**:
```json
{
  "op": "promote_with_fields",
  "id": 4521,
  "quando_usar":      "Quando o público está em fase fria...",
  "por_que_funciona": "Ativa gatilho de novidade + identificação...",
  "como_adaptar":     "Trocar contexto de odonto pra clínica X...",
  "objetivo":         "Identificar"
}
```

**Validação no servidor**:
- Cada campo string com `length >= 20`.
- `objetivo ∈ {Atrair, Identificar, Desejo, Confiar, Vender}` (warning se fora; aceita).

**Response 200**:
```json
{ "ok": true, "op": "promote_with_fields", "id": 4521, "promoted_at": "2026-05-12T19:42:00Z" }
```

**Response 400** (`missing_editorial_fields`):
```json
{ "ok": false, "error": "missing_editorial_fields",
  "fields": ["quando_usar", "como_adaptar"] }
```

#### 3.1.2 `op: promote` (mantido por compat — passa a falhar se faltar campo)

Mantido pra compatibilidade do dashboard antigo. Se 3 campos já estão preenchidos no banco, promove. Senão retorna `400` com `error: "use_promote_with_fields"`.

#### 3.1.3 `op: update_editorial_fields` (NOVO)

```json
{ "op": "update_editorial_fields", "id": 4521,
  "quando_usar": "...", "por_que_funciona": "...",
  "como_adaptar": "...", "objetivo": "Atrair" }
```

Usado pra editar item já promovido sem despromover.

#### 3.1.4 Operações existentes (mantidas)

`update_note`, `update_tags`, `soft_delete`, `unpromote` — sem mudança de contrato.

### 3.2 Edge Function `case-agente-mapa` (Agente 00)

**Endpoint**: `POST /functions/v1/case-agente-mapa`

**Request — `op: create`**:
```json
{
  "op": "create",
  "cliente_slug": "queila",
  "titulo": "Mapa Mentoria CASE — Mai/26",
  "publico": { "quem": "...", "nivel": "...", "contexto": "..." },
  "oferta":  { "promessa": "...", "ticket": "R$5k", "formato": "online" },
  "sinais_externos": {
    "youtube": ["url1","url2"],
    "tiktok":  [],
    "comentarios": ["texto..."]
  }
}
```

**Response 200**:
```json
{
  "ok": true,
  "op": "create",
  "id": 17,
  "status": "draft",
  "duracao_ms": 41200,
  "custo_usd": 0.18,
  "preview": { "top_assuntos": ["...", "..."] }
}
```

**Op adicionais**: `get(id)`, `list(cliente_slug)`, `approve(id)`, `archive(id)`, `regenerate(id, novos_inputs)`.

### 3.3 Edge Function `case-agente-download` (Agente 00.5)

**Endpoint**: `POST /functions/v1/case-agente-download`

**Request — `op: create`**:
```json
{
  "op": "create",
  "cliente_slug": "queila",
  "mapa_id": 17,
  "perguntas_extras": ["..."]
}
```

Output igual estrutura: `{ ok, id, status, duracao_ms, custo_usd, preview }`.

### 3.4 Edge Function `case-agente-modelador` (Agente 02)

**Endpoint**: `POST /functions/v1/case-agente-modelador`

**Request — `op: create`**:
```json
{
  "op": "create",
  "cliente_slug": "queila",
  "referencia_id": 4521,
  "formato_visual": "reel",
  "ideia_alvo": "Identificação com mãe que opera sozinha"
}
```

Ou via URL solta:
```json
{
  "op": "create",
  "cliente_slug": "queila",
  "referencia_url": "https://instagram.com/p/ABC...",
  "formato_visual": "carrossel",
  "ideia_alvo": "..."
}
```

**Response 200**:
```json
{
  "ok": true,
  "id": 8,
  "estrutura": { "cenas": [...] },
  "roteiro":   { "fala": "...", "cta": "..." },
  "duracao_ms": 23100,
  "custo_usd": 0.09
}
```

### 3.5 Edge Function `case-agente-estrategista` (Agente 01) — V1.5

Adiada pro V1.5 (depende de Mapa+Download maduros). Contrato draft:

```json
{
  "op": "create",
  "cliente_slug": "queila",
  "mapa_id": 17,
  "download_id": 9,
  "fase": "D+E",
  "capacidade": { "posts_dia": 1, "stories_dia": 6, "reels_semana": 3 },
  "mix_alvo": { "D_E": 0.7, "C_I_D": 0.3, "A": 0.0 }
}
```

### 3.6 Convenções gerais de API

- Todas as Edge Functions retornam `{ ok: bool, ... }` com `ok: false → error: <slug>`.
- `corsHeaders` permissivo (mesmo padrão da `case-refs-mutate`).
- `service_role_key` consumido só do `Deno.env`, nunca do payload.
- Erros LLM: 502 `{ok:false, error:"llm_error", retryable:true}`.
- Custo > $0.50 por chamada → 402 `{ok:false, error:"cost_cap_exceeded"}` (cap configurável).

---

## 4. Fluxos Críticos

### 4.1 Cadastro novo → Curadoria editorial → Promoção

```
Curador          Frontend (/live)        Edge Fn               Postgres
-------          ----------------        -------               --------
   |                    |                   |                      |
   | abre /live         |                   |                      |
   |------------------->|                   |                      |
   |                    | GET v_referencias_publicas (anon)        |
   |                    |---------------------------------------> |
   |                    |<--- itens promoted_at IS NULL ---------- |
   |                    | renderiza com badge ⏳                   |
   |                    |                   |                      |
   | clica "Promover"   |                   |                      |
   |------------------->|                   |                      |
   |                    | abre modal: pede 3 campos + objetivo     |
   |                    |                   |                      |
   | preenche+confirma  |                   |                      |
   |------------------->|                   |                      |
   |                    | POST case-refs-mutate                    |
   |                    | op=promote_with_fields                   |
   |                    |------------------>|                      |
   |                    |                   | UPDATE refs SET ...  |
   |                    |                   |    quando_usar=...   |
   |                    |                   |    promoted_at=NOW() |
   |                    |                   |--------------------->|
   |                    |                   |  (CHECK constraint   |
   |                    |                   |   valida 3 campos)   |
   |                    |                   |<---------------------|
   |                    |<-- 200 {ok,id,promoted_at} -------------|
   |                    | remove do /live, mostra toast            |
   |                    |                   |                      |
   |                    | (eventual) próxima visita /trilhas       |
   |                    |    fetch v_referencias_promovidas        |
   |                    | item aparece no fim da categoria         |
```

**Edge case — campo faltando**:
- Server retorna `400 {error:"missing_editorial_fields", fields:[…]}`
- Modal destaca campos vermelhos, NÃO fecha.

**Edge case — promoção sem campos via op antiga**:
- `op:promote` sem campos preenchidos → `400 use_promote_with_fields`.
- Dashboard antigo precisa atualizar pra modal nova.

### 4.2 Agente 00 — Mapa de Interesse

```
Operador         /agentes/mapa-interesse        Edge Fn              n8n              LLM
--------         ----------------------         -------              ---              ---
   |                    |                          |                  |                 |
   | preenche form:     |                          |                  |                 |
   | publico/oferta     |                          |                  |                 |
   | sinais_externos    |                          |                  |                 |
   |------------------->|                          |                  |                 |
   |                    | POST case-agente-mapa op=create             |                 |
   |                    |------------------------->|                  |                 |
   |                    |                          | INSERT mapas_interesse status=draft|
   |                    |                          |                  |                 |
   |                    |                          | trigger n8n      |                 |
   |                    |                          |  POST /webhook/agente_00           |
   |                    |                          |----------------->|                 |
   |                    |<-- 202 {id, status:processing} -------------|                 |
   |                    | mostra spinner + polling /get(id)           |                 |
   |                    |                          |                  | prompt v3       |
   |                    |                          |                  |---------------->|
   |                    |                          |                  |<-- 12 gavetas --|
   |                    |                          |                  | UPDATE mapa     |
   |                    |                          |                  |   gavetas=…     |
   |                    |                          |                  |   status=draft  |
   |                    |                          |                  |   duracao_ms=…  |
   |                    |                          |                  |   custo_usd=…   |
   |                    | poll → ok                                   |                 |
   |                    | renderiza 12 gavetas + top_assuntos         |                 |
   | revisa e clica     |                          |                  |                 |
   | "Aprovar"          |                          |                  |                 |
   |------------------->| POST op=approve(id) → status=aprovado       |                 |
```

**Custo target**: ≤ $0.20 por mapa (Claude Sonnet) ou $0 (Qwen local).
**Latência target**: ≤ 60s p95.

### 4.3 Agente 02 — Modelador

```
Operador         /agentes/modelador        Edge Fn               LLM
--------         ------------------        -------               ---
   |                    |                     |                    |
   | escolhe referência |                     |                    |
   | (do banco OU URL)  |                     |                    |
   | escolhe formato    |                     |                    |
   | descreve ideia     |                     |                    |
   |------------------->|                     |                    |
   |                    | POST case-agente-modelador op=create     |
   |                    |-------------------->|                    |
   |                    |                     | SELECT ref + transcrição
   |                    |                     |                    |
   |                    |                     | prompt: "preserve estrutura,
   |                    |                     |          adapte conteúdo"
   |                    |                     |------------------->|
   |                    |                     |<-- {estrutura, roteiro} |
   |                    |                     | INSERT roteiros_modelados
   |                    |<-- 200 {id, estrutura, roteiro} ---------|
   |                    | renderiza side-by-side                   |
   |                    | (referência | roteiro)                   |
   | edita inline       |                     |                    |
   |------------------->| PATCH op=update                          |
   | aprova             |                     |                    |
   |------------------->| op=approve(id)                           |
```

---

## 5. Migrations Plan (ordem)

| # | Arquivo                                                          | O que faz                                                |
|---|------------------------------------------------------------------|----------------------------------------------------------|
| 1 | `20260513000000_referencias_conteudo_editorial_fields.sql`       | +4 colunas, CHECK constraint, view promovidas, índices   |
| 2 | `20260513000500_promote_with_fields_rpc.sql`                     | RPC `case_refs_promote_v2(p_id, p_fields jsonb)`         |
| 3 | `20260513001000_mapas_interesse.sql`                             | Tabela + índices                                         |
| 4 | `20260513002000_downloads_expert.sql`                            | Tabela + índices                                         |
| 5 | `20260513003000_planos_editoriais.sql`                           | Tabela + índices                                         |
| 6 | `20260513004000_roteiros_modelados.sql`                          | Tabela + índices                                         |
| 7 | `20260513005000_rls_policies_agentes.sql`                        | RLS em todas as tabelas novas (ver §8)                   |
| 8 | `20260513006000_rpc_agentes.sql`                                 | RPCs `case_agente_*_create/get/list/approve/archive`     |
| 9 | `20260513007000_rename_etapa_funil_label_view.sql`               | View `v_etapa_label` → mapeia DESCOBERTA→D+E etc         |

**Ordem de deploy**:
1. Migrations 1–2 → smoke test promoção antiga ainda funciona.
2. Migration 9 → frontend já pode usar labels novos.
3. Migrations 3–6 → tabelas vazias, zero impacto.
4. Migration 7 → RLS ativada.
5. Migration 8 → RPCs disponíveis pras Edge Fns.

**Rollback**: cada migration tem `DOWN` correspondente em `migrations/down/`.

---

## 6. Frontend — Mudanças e Novos HTMLs

### 6.1 HTMLs existentes que mudam

| Arquivo            | Mudança                                                                                  |
|--------------------|------------------------------------------------------------------------------------------|
| `index.html`       | + card "Como Usar" + card "Agentes Editoriais"                                           |
| `live.html`        | Modal de promoção com 3 textareas + dropdown objetivo (5 opções). Validação inline.      |
| `trilhas.html`     | Cards mostram `objetivo` como pill colorida + tooltip "Quando usar / Por que funciona"   |
| `dashboard.html`   | Nova aba "Editorial" pra editar `quando_usar/por_que_funciona/como_adaptar` em batch     |

### 6.2 HTMLs novos

| Arquivo                               | Função                                                                  |
|---------------------------------------|-------------------------------------------------------------------------|
| `como-usar.html`                      | Guia cliente: explica DECIDA, mix 70/30/0-10, como ler card, exemplos   |
| `agentes/index.html`                  | Listagem dos 4 agentes + status (Pronto / V1 / V1.5)                    |
| `agentes/mapa-interesse.html`         | Form Agente 00 + render gavetas                                          |
| `agentes/download-expert.html`        | Form Agente 00.5 + render repositório                                    |
| `agentes/plano-editorial.html`        | Form Agente 01 + tabela banco de ideias (V1.5)                          |
| `agentes/modelador.html`              | Form Agente 02 + render side-by-side referência vs roteiro              |

### 6.3 Componentes JS reutilizáveis (vanilla, sem build)

```
/_components/
  ├── supabase-client.js       (singleton, anon key)
  ├── edge-fn-client.js        (POST helper, retry/abort)
  ├── editorial-modal.js       (modal promoção V1)
  ├── agent-form-renderer.js   (renderiza form a partir de schema JSONB)
  ├── agent-output-renderer.js (renderiza output 12 gavetas, etc.)
  └── decida-pill.js           (renderiza pill DECIDA com cor por bloco)
```

Sem framework. Imports via `<script type="module">`.

### 6.4 Tabela de cores DECIDA (UX)

| Bloco       | Etapa banco | Label UX | Cor (hex) |
|-------------|-------------|----------|-----------|
| D + E       | DESCOBERTA  | D+E      | `#3b82f6` |
| C + I + D   | CONFIANCA   | C+I+D    | `#8b5cf6` |
| A           | ACAO        | A        | `#ef4444` |

---

## 7. Observabilidade

### 7.1 Logs

- **Edge Functions**: `console.log` estruturado JSON (Supabase coleta automático). Schema:
  ```json
  { "ts":"2026-05-12T...", "fn":"case-agente-mapa", "op":"create",
    "cliente_slug":"queila", "duracao_ms":41200, "custo_usd":0.18, "ok":true }
  ```
- **n8n**: workflow logs nativos + webhook /metrics opcional.
- **LLM calls**: contar tokens IN/OUT e custo direto na resposta da fn (já vai em `custo_usd`).

### 7.2 Métricas básicas (V1)

Dashboards simples no `/dashboard` (apenas curador):

| Métrica                          | Fonte                                            | Período |
|----------------------------------|--------------------------------------------------|---------|
| Cadastros novos (badge ⏳)/dia    | `count(*) where promoted_at IS NULL`             | 30d     |
| Promoções/dia                    | `count(*) where promoted_at::date = X`           | 30d     |
| Tempo médio cadastro→promoção    | `avg(promoted_at - created_at)`                  | 30d     |
| Itens promovidos por etapa       | `group by etapa_funil`                           | total   |
| Itens promovidos por objetivo    | `group by objetivo`                              | total   |
| Mapas/Downloads/Roteiros gerados | `count(*) from {mapas,downloads,roteiros}`       | 30d     |
| Custo LLM acumulado (USD)        | `sum(custo_usd) from agentes_*`                  | 30d     |

Implementação: SQL + render simples no `dashboard.html`. Sem Grafana/Datadog em V1.

### 7.3 Alertas (V1, low-fi)

- Edge Function falha 5xx > 3 em 10min → log no `console.error` (Supabase Slack opcional).
- Custo LLM diário > $5 → script cron compara `sum(custo_usd) where created_at::date = today` e dispara webhook.

---

## 8. Segurança

### 8.1 RLS Policies

Migration `20260513005000_rls_policies_agentes.sql`:

```sql
-- referencias_conteudo: já tem RLS via view pública. Reforçar:
ALTER TABLE agente.referencias_conteudo ENABLE ROW LEVEL SECURITY;

-- Anon NÃO acessa direto a tabela base (só via view)
REVOKE ALL ON agente.referencias_conteudo FROM anon, authenticated;

-- View pública é o único canal de leitura pra anon
GRANT SELECT ON public.v_referencias_publicas TO anon, authenticated;
GRANT SELECT ON public.v_referencias_promovidas TO anon, authenticated;

-- Tabelas dos agentes: acessadas SOMENTE via Edge Fn (service_role)
ALTER TABLE agente.mapas_interesse     ENABLE ROW LEVEL SECURITY;
ALTER TABLE agente.downloads_expert    ENABLE ROW LEVEL SECURITY;
ALTER TABLE agente.planos_editoriais   ENABLE ROW LEVEL SECURITY;
ALTER TABLE agente.roteiros_modelados  ENABLE ROW LEVEL SECURITY;

-- Nenhuma policy criada → anon/authenticated não conseguem nem SELECT
-- service_role bypassa RLS por default
```

### 8.2 Autenticação

- **Frontend público** (`/`, `/trilhas`, `/posts`, `/como-usar`): só `anon key`, leitura via views.
- **Curadoria** (`/live`, `/dashboard`, `/agentes/*`): mantém padrão atual `_auth.js` (basic auth simples / token compartilhado). Roadmap V2: Supabase Auth com magic link pra curadores.
- **Edge Functions**: usam `SUPABASE_SERVICE_ROLE_KEY` do env Supabase. Frontend chama com `apikey: ANON_KEY` no header — Edge Fn aceita CORS qualquer origem mas valida payload.

### 8.3 Service role vs Anon

| Recurso                          | Anon | Authenticated | Service Role | Edge Fn |
|----------------------------------|------|---------------|--------------|---------|
| `v_referencias_publicas`         | R    | R             | R/W          | R/W     |
| `v_referencias_promovidas`       | R    | R             | R/W          | R/W     |
| `referencias_conteudo` (table)   | -    | -             | R/W          | R/W     |
| `mapas_interesse`                | -    | -             | R/W          | R/W     |
| `downloads_expert`               | -    | -             | R/W          | R/W     |
| `planos_editoriais`              | -    | -             | R/W          | R/W     |
| `roteiros_modelados`             | -    | -             | R/W          | R/W     |
| RPC `case_refs_*`                | EXEC | EXEC          | EXEC         | EXEC    |
| RPC `case_agente_*`              | -    | -             | EXEC         | EXEC    |

### 8.4 Rate Limiting

- Edge Functions: `Deno.serve` + middleware simples por IP (max 60 req/min em mutations).
- Agentes (caro em LLM): max 10 chamadas `op=create` por `cliente_slug` por dia (cap configurável).
- 429 com `Retry-After`.

### 8.5 Secrets

- `SUPABASE_SERVICE_ROLE_KEY`, `ANTHROPIC_API_KEY`, `APIFY_TOKEN`, `ASSEMBLYAI_KEY` → todos via Supabase Edge Fn env (nunca no front, nunca em git).
- Mac mini local (Qwen) acessado por Edge Fn via Tailscale interna — IP privado fixo.

### 8.6 PII

- Caption + transcrição podem conter nomes/handles. View pública expõe ambos — comportamento atual mantido (já é conteúdo público IG).
- `notas` do curador é interna → fica em `referencias_conteudo` mas **nunca** é exposta nas views públicas. Migration `20260512200000_safe_view_no_notas.sql` substituiu o `SELECT *` por whitelist explícita de colunas em `v_referencias_publicas` e `v_referencias_promovidas`. Regra: **antes de adicionar coluna nova a essas views, conferir se ela pode ser exposta ao anon.**

---

## 9. Critérios de Aceite Técnico (V1)

- [ ] Migration 1 aplicada em prod sem downtime (CHECK constraint não invalida promovidos antigos pq são todos NULL).
- [ ] Promoção via `op=promote_with_fields` cria item promovido com 3 campos.
- [ ] Promoção via `op=promote` legacy retorna 400 se campos vazios.
- [ ] `/como-usar.html` no ar com explicação DECIDA + mix 70/30/0-10.
- [ ] `/live` modal nova com 3 textareas + dropdown objetivo.
- [ ] `/trilhas` mostra pill DECIDA por card.
- [ ] Edge Fn `case-agente-mapa` op=create funciona end-to-end (form → INSERT → n8n → LLM → UPDATE → polling render).
- [ ] Edge Fn `case-agente-modelador` op=create funciona end-to-end.
- [ ] RLS bloqueia anon de SELECT direto em `mapas_interesse` (curl test).
- [ ] Dashboard mostra 7 métricas listadas em §7.2.
- [ ] Custo médio Agente 00 ≤ $0.20.
- [ ] Latência p95 Agente 00 ≤ 60s.

---

## 10. Fora de Escopo (V1)

- Agente 01 (Estrategista) — adiado V1.5 (depende de mapa+download maduros e ≥3 clientes pilotando).
- Agente 03 (Roteirista) — fora do roadmap V1.
- Multi-tenant (separação por cliente em RLS) — V2.
- Auth via magic link curador — V2.
- Migration de `etapa_funil` pra enum novo — não fazer (ADR-0001 explica).
- Substituir Apify por scraper próprio — não fazer (ADR-0005, só patch defensivo).
- Migrar pra SPA (Next/React) — não fazer (ADR-0004).

---

**Próximo doc**: `epics/E01-foundations-decida.md` quebra esta spec em stories AIOX-format (§5 vira E01, §3+4 viram E02, §3.2/3.3/3.4 viram E04/E05/E07).
