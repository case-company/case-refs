---
name: content-system-epics-2026-05-12
description: 8 epics do Content System CASE criados em 2026-05-12 — estrutura completa, 31 stories, grafo de dependências
metadata:
  type: project
---

Epics do Content System CASE criados em `/Users/kaiquerodrigues/Downloads/case-references/docs/specs/content-system/epics/`.

**Por que:** handoff do Felipe Gobbi + método DECIDA da Queila consolidados em spec executável para o site `refs.casein.com.br`.

**How to apply:** ao criar stories individuais, referenciar o epic correspondente para manter coerência de escopo e dependências.

Stack do projeto: Vercel (HTML estático) + Supabase (Postgres + Edge Functions) + n8n + Apify + AssemblyAI. Schema principal: `agente.referencias_conteudo`.

Prioridades fixadas:
- P0 (V1 mínimo): E01, E02, E03
- P1 (core agents + validação): E04, E05, E08
- P2 (agentes avançados): E06, E07
