---
title: Content System CASE — Changelog
type: changelog
status: active
date: 2026-05-12
owner: Kaique Rodrigues
---

# Changelog — Content System CASE

Histórico de releases do `refs.casein.com.br` em conjunto com o backend `agente.*` no Supabase do Case.

## [1.0.0] — 2026-05-12 — V1 Release

V1 fecha o handoff do Felipe Gobbi e absorve o método DECIDA da Queila no produto unificado `refs.casein.com.br`. Todo o escopo P0/P1/P2 do PRD foi implementado em código no mesmo dia (~8h de sessão autônoma).

### Adicionado

**E01 — Foundations DECIDA** (5/5 stories Done)
- Constante `window.DECIDA_MAP` em `_decida.js` — single source of truth pros 3 grupos (D+E, C+I+D, A).
- Relabel em `/trilhas`, `/live`, `/dashboard`: "Confiança" → "C+I+D".
- Tooltip `label_long` em todos os badges/options de etapa.
- `guia-decida.md` cliente-facing (PT-BR, 5 seções, 0 anglicismos).
- ADR-0001 aceito + seção "Práticas obrigatórias" (lint guard).

**E02 — Curadoria Editorial** (6/6 stories Done — smoke PASS 2026-05-12)
- 4 colunas editoriais em `agente.referencias_conteudo`: `quando_usar`, `por_que_funciona`, `como_adaptar`, `objetivo`.
- CHECK constraint `chk_promoted_requires_editorial_fields` (NOT VALID — não retroativa).
- View `v_referencias_publicas` reescrita com whitelist explícita SEM coluna `notas` (campo interno do curador).
- View `v_referencias_promovidas` criada (atalho pro `/trilhas`).
- RPC `case_refs_promote_editorial(BIGINT, TEXT, TEXT, TEXT, TEXT)` com validação >= 20 chars + RAISE EXCEPTION semântico.
- Edge Function `case-refs-mutate` aceita `op: 'promote_editorial'` com 422 estruturado em campos faltantes.
- Modal de promoção em `/live` com 3 textareas obrigatórias + contador "X/3 campos" + link "Guia DECIDA".
- Card expandido em `/trilhas` exibe seção "Guia de uso" condicional aos campos preenchidos.

**E03 — Onboarding Cliente** (4/4 stories Done)
- Página `/como-usar.html` (7 seções: o que é DECIDA, os 3 grupos com pills coloridas, regra do mix, navegação do banco, campos do Guia de uso, erros comuns, atalhos).
- Tour de primeira visita em `/trilhas` (`_tour.js`) com flag em localStorage + override via `?tour=1`.
- Nav link "Como usar" em `index.html`, `trilhas.html`, `live.html`, `posts.html`, `dashboard.html`.
- 4º card "Como usar" na landing.

**E04 — Agente 00: Mapa de Interesse**
- Tabela `agente.mapas_interesse` com 12 gavetas + provenance LLM + versionamento por `cliente_slug`.
- RPC `case_agente_mapa_save`.
- Página `/agentes/mapa-interesse` com form JSON estruturado + listagem.

**E05 — Agente 00.5: Download do Expert**
- Tabela `agente.downloads_expert` com FK opcional pra `mapas_interesse`.
- RPC `case_agente_download_save`.
- Página `/agentes/download-expert` com 7 blocos (crenças, teses, provas, histórias, método, linguagem, fontes).

**E06 — Agente 01: Estrategista Editorial**
- Tabela `agente.planos_editoriais` com coluna `valido BOOLEAN GENERATED ALWAYS AS (banco_ideias é array não-vazio) STORED`.
- CHECK fase ∈ {D+E, VENDAS, MISTO}.
- Default `mix_alvo = {D_E:0.7, C_I_D:0.3, A:0.0}`.
- RPC `case_agente_plano_save` retorna `out_id/out_versao/out_valido`.
- Página `/agentes/estrategista` com dropdown de fase + UI sinaliza inválido se Banco de Ideias vazio.

**E07 — Agente 02: Modelador de Referências**
- Tabela `agente.roteiros_modelados` com FK opcional pra `referencias_conteudo` + `planos_editoriais`.
- CHECK `formato_visual ∈ {reel, carrossel, story, live, post_estatico, video_longo}`.
- CHECK `referencia_id IS NOT NULL OR referencia_url IS NOT NULL`.
- RPC `case_agente_roteiro_save`.
- Página `/agentes/modelador` carrega referências de `v_referencias_promovidas` em dropdown + fallback URL externa.

**Compartilhado**
- `_agente-styles.css` — CSS base das 4 páginas de agente.
- `_agente-shared.js` — utilitários (`callRpc`, `fetchView`, `parseJsonField`, `toast`).
- `/agentes/index.html` — landing com 4 cards dos agentes.

### Corrigido

- `v_referencias_publicas` parou de expor `notas` (campo interno do curador) — risco de vazamento eliminado antes que E01/E02 entrassem em uso.
- Edge Function: spread de array `...r.data` causava `{0:{...}}` no response → trocado por `data: r.data`.
- RPC `case_refs_promote_editorial`: tipagem `id INT` corrigida pra `BIGINT` (tabela é BIGSERIAL).
- Edge Function: branch `op: 'promote'` legacy removida (constraint `chk_promoted_requires_editorial_fields` impedia uso).

### Documentação

- PRD V1 completo (`01-prd.md` — 458 linhas).
- Spec técnica (`02-spec-tech.md` — 875 linhas com diagramas ER, sequence diagrams, RLS, observabilidade).
- 5 ADRs (taxonomia DECIDA, campos obrigatórios, agentes como módulos, frontend estático, pipeline n8n preservado).
- 8 epics + 20 stories.
- Test-run de E02 com PASS 6/6 (`test-runs/E02-smoke-2026-05-12.md`).

### Pendente (V1.5)

- Plugar LLM nos 4 agentes (hoje 100% manual conforme P2 do PRD).
- Validação semântica do `insumo_publico` E `insumo_expert` em cada item do `banco_ideias` (hoje só checa array não-vazio).
- Smoke E2E real dos 4 agentes (curl) — aguardando aplicação do SQL no Supabase.
- Métricas de adoção: contagem de mapas/downloads/planos/roteiros criados.

### Não comprometido (V2+)

- Pipeline editorial automático com LLM real (Claude / Qwen local).
- Página de relatório consolidado por cliente_slug (timeline de mapa → download → plano → roteiros).
- Autenticação por role (curador vs cliente vs admin).
- Integração com o calendário de publicação real.
