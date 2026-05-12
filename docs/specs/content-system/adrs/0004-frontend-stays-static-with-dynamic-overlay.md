---
title: ADR-0004 — Manter frontend HTML estático no Vercel + overlay dinâmico via fetch
status: accepted
date: 2026-05-12
deciders: [Kaique]
supersedes: null
related:
  - 02-spec-tech.md#1.1
  - 02-spec-tech.md#6
---

# ADR-0004 — Frontend estático com overlay dinâmico

## Context

O `refs.casein.com.br` hoje é **HTML estático** servido pelo Vercel:

- `index.html`, `trilhas.html`, `posts.html`, `live.html`, `dashboard.html`
- 75 itens curados estão **inline no HTML** (`trilhas.html` traz cards no markup)
- Itens promovidos via Supabase entram via **fetch JS** na hora do load (overlay)
- Sem framework, sem build step, sem bundler. JS vanilla, módulos via `<script type="module">`.

Com a expansão do Content System CASE (4 agentes editoriais + página /como-usar + páginas de output), surge a pergunta:

> "Não seria hora de migrar pra Next.js / SvelteKit / Astro?"

Argumentos pró-SPA frequentemente trazidos:
- Componentização real
- Roteamento client-side
- TypeScript
- SSR/ISR pra SEO
- "É o padrão moderno"

## Decision

**Manter frontend 100% estático no Vercel + overlay dinâmico via fetch direto Supabase. Não migrar pra SPA em V1 nem V1.5.**

Concretamente:

1. **Páginas continuam HTML puro**: cada rota é um `.html` físico no repo. Roteamento é o filesystem do Vercel.
2. **Conteúdo curado vive em 2 lugares por desenho**:
   - **Estático**: 75 itens canônicos em `trilhas.html` inline (zero fetch necessário pra LCP).
   - **Dinâmico**: itens novos promovidos via fetch `v_referencias_promovidas` no `DOMContentLoaded`.
3. **Componentes JS vanilla**: módulos ES em `/_components/` (importados via `<script type="module" src="/_components/x.js">`).
4. **Sem build step**: nada de Vite/webpack/esbuild. Vercel serve direto. CSS vanilla também.
5. **TypeScript opcional só nas Edge Functions** (Deno suporta nativo). Frontend fica em JS puro com JSDoc pra type hints.

## Consequences

### Positivas

- **LCP / TTFB excelentes**: HTML estático é o mais rápido possível na web. Vercel CDN serve em ~50ms p95.
- **SEO trivial**: conteúdo já está no HTML, crawler não precisa executar JS.
- **Build = `git push`**: sem CI build step pra quebrar. Sem `node_modules` no repo. Deploy em 10s.
- **Custo Vercel: free tier basta**: zero compute, só CDN. Edge Function quotas suficientes pra V1.
- **Onboarding pra Queila/Felipe**: editar `trilhas.html` é editar HTML — qualquer pessoa edita. Sem npm install, sem pnpm, sem "qual versão do node?".
- **Resiliente a "framework churn"**: React/Next/etc rotacionam APIs a cada 12 meses. HTML é estável desde 1999.
- **Refactor barato**: se algum dia precisar migrar pra SPA, conteúdo estático é fácil de extrair pra CMS. Inverso (SPA → estático) é raro e doloroso.

### Negativas / Trade-offs

- **Componentização limitada**: web components vanilla resolvem ~80% dos casos, mas não chega ao DX de React/Svelte. Aceito — escala atual não pede.
- **Estado compartilhado entre páginas exige solução manual**: `localStorage`/`sessionStorage` ou query params. Nenhuma global store. Aceito — fluxos do produto são lineares (form → ver output → salvar).
- **Sem hot reload nativo**: dev usa `python -m http.server` ou Vercel CLI dev. Aceitável.
- **Testes E2E ficam mais artesanais**: sem framework, nada de Vitest/Jest dom-testing. Mitigação: Playwright (testa o HTML servido, agnóstico).
- **Type safety reduzida**: JSDoc + TS check no editor cobre os casos básicos. Strict typing em Edge Fns sim.
- **Repetição de markup**: nav/footer copiados em cada HTML. Mitigação: web component `<case-nav>` injetado no `<head>` script.

### Neutras

- O "mix estático + dinâmico" pode confundir quem espera 100% de um lado ou 100% do outro. Mitigação: comment block no topo de cada HTML explicando o pattern.

## Alternatives Considered

### Alt A — Migrar pra Next.js (App Router)
- **Por que rejeitada**:
  - Build step + node_modules = atrito enorme pra um produto editado por pessoas não-dev (Queila, Felipe).
  - SSR/ISR não dá ganho real: conteúdo é público e cacheável estaticamente.
  - Lock-in maior (Vercel-specific features).
  - Custo Vercel sobe quando passa do free tier de Functions.

### Alt B — Migrar pra Astro (multi-framework, ships zero JS)
- **Por que tentadora**: filosofia alinhada (HTML-first, JS opcional).
- **Por que rejeitada (V1)**: ainda é build step. Migration custa 1-2 semanas. ROI baixo dado que o pain real (zero) não justifica. Reconsiderar em V2 se chegar a 50+ páginas.

### Alt C — SvelteKit estático (SSG)
- **Por que rejeitada**: mesma razão de Astro — build step + framework churn risk. Ganho de DX não compensa pro tipo de página (mais conteúdo, menos interação).

### Alt D — HTMX + servidor próprio
- **Por que rejeitada**: não tem servidor dedicado. Edge Functions cobrem mutations. HTMX vira complexidade extra sem ganho.

### Alt E — Notion como CMS + render via API
- **Por que rejeitada**: o handoff explicitamente abandonou Notion. Custo + lock-in + perda de controle SEO.

## Implementation Hooks

- Páginas novas (E1+): seguem padrão de `trilhas.html` (HTML inline + fetch JS).
- Componente compartilhado primeiro: `/_components/case-nav.js` (web component) — elimina copy-paste de nav.
- Páginas de agentes (`/agentes/*.html`): seguem o mesmo padrão. Form HTML nativo + JS pra POST pra Edge Fn.

## Revisitar quando

- Páginas estáticas chegarem a >50 (hoje são 5).
- Interatividade rica passar a ser core (drag-drop, real-time collab).
- Time de devs frontend dedicados crescer pra ≥2 pessoas.
- Necessidade de TypeScript end-to-end virar bloqueador.

## Related ADRs

- ADR-0003 (agentes como módulos) — UI de cada agente segue este padrão.
- ADR-0005 (n8n preserved) — toda a complexidade de pipeline fica no backend, libera o front pra ser simples.
