---
title: Content System CASE — Changelog
type: changelog
status: active
date: 2026-05-12
owner: Kaique Rodrigues
---

# Changelog — Content System CASE

Histórico de releases do `refs.casein.com.br` em conjunto com o backend no Supabase do Case.

## [1.0.0] — 2026-05-12 — V1 Release

V1 fecha o handoff do Felipe Gobbi e absorve a taxonomia DECIDA da Queila como vocabulário oficial. Entregue numa sessão.

### Adicionado

**E01 — Foundations DECIDA** (5/5 stories Done)
- Constante `window.DECIDA_MAP` em `_decida.js` — single source of truth para os 3 grupos (D+E, C+I+D, A) + helpers (`decidaLabel`, `decidaLabelLong`, `decidaBadge`).
- Relabel em `/trilhas`, `/live`, `/dashboard`: "Confiança" → "C+I+D".
- Tooltip `label_long` em todos os badges/options de etapa.
- `guia-decida.md` cliente-facing (PT-BR, 5 seções).
- ADR-0001 aceito + seção "Práticas obrigatórias" (lint guard).

**E02 — Curadoria Editorial** (6/6 stories Done — smoke PASS 2026-05-12)
- 4 colunas editoriais em `agente.referencias_conteudo`: `quando_usar`, `por_que_funciona`, `como_adaptar`, `objetivo`.
- CHECK constraint `chk_promoted_requires_editorial_fields` (NOT VALID — não retroativa).
- View `v_referencias_publicas` reescrita com whitelist explícita SEM coluna `notas` (campo interno do curador).
- View `v_referencias_promovidas` criada (atalho pro `/trilhas`).
- RPC `case_refs_promote_editorial(BIGINT, TEXT, TEXT, TEXT, TEXT)` com validação ≥ 20 chars + RAISE EXCEPTION semântico.
- Edge Function `case-refs-mutate` aceita `op: 'promote_editorial'` com 422 estruturado.
- Modal de promoção em `/live` com 3 textareas obrigatórias + contador "X/3 campos" + link Guia DECIDA.
- Card expandido em `/trilhas` exibe seção "Guia de uso" condicional.

**E03 — Onboarding Cliente** (4/4 stories Done)
- Página `/como-usar.html` (7 seções: o que é DECIDA, os 3 grupos com pills coloridas, regra do mix, navegação do banco, campos do Guia de uso, erros comuns, atalhos).
- Tour de primeira visita em `/trilhas` (`_tour.js`) com flag em localStorage + override via `?tour=1`.
- Nav link "Como usar" em `index.html`, `trilhas.html`, `live.html`, `posts.html`, `dashboard.html`.
- 4º card "Como usar" na landing.

### Corrigido

- `v_referencias_publicas` parou de expor `notas` (campo interno do curador) — risco de vazamento eliminado antes que E01/E02 entrassem em uso.
- Edge Function: spread de array `...r.data` causava `{0:{...}}` no response → trocado por `data: r.data`.
- RPC `case_refs_promote_editorial`: tipagem `id INT` corrigida pra `BIGINT` (tabela é BIGSERIAL).
- Edge Function: branch `op: 'promote'` legacy removida (constraint `chk_promoted_requires_editorial_fields` impedia uso).

### Documentação

- PRD V1 (`01-prd.md`).
- Spec técnica (`02-spec-tech.md`).
- 4 ADRs (taxonomia DECIDA, campos obrigatórios, frontend estático, pipeline n8n preservado).
- 4 epics (E01, E02, E03, E08) + stories.
- Test-run de E02 com PASS 6/6 (`test-runs/E02-smoke-2026-05-12.md`).

### Removido durante o desenvolvimento

- **4 agentes editoriais (Mapa de Interesse / Download do Expert / Estrategista / Modelador)** que foram enxertados por erro de interpretação do briefing e depois extraídos. Não estavam no handoff Felipe Gobbi — o material em `~/Downloads/copia projeto agentes/` era referência do método interno da Queila, não escopo de produto. Detalhes do erro e da reversão em commit `revert(content-system): remove agentes fora do escopo do handoff`.

### Pendente

- `fase-2-monitoramento-apis.md` — documento explícito do handoff (não escrito ainda).
- Migração dos dados do Sheets ativo da Queila pro banco.
- Validação com cliente real (uso da Queila/cliente piloto, não smoke automatizado).
- Mecanismo de coleta de feedback dos clientes sobre o produto.

### Não comprometido (V2+)

- Pipeline editorial assistido por LLM (sugestão automática dos 3 campos editoriais).
- Página de relatório consolidado por cliente.
- Autenticação por role (curador vs cliente vs admin).
- Integração com o calendário de publicação real.
