# PRD — case-refs

**Status:** Active
**Owner:** Kaique Rodrigues
**Última atualização:** 2026-04-30
**Versão:** 1.0

---

## 1. Visão

case-refs é o microapp de banco de referências de conteúdo da Case. Centraliza posts e perfis do Instagram que servem como benchmark estratégico para as trilhas Mentoria e Clínica, com transcrição automática, classificação por etapa do funil, e fluxo de cadastro 1-clique.

**Hoje:** repo público em `case-company/case-refs`, deploy estático no Vercel (`case-refs.vercel.app`), 4 páginas (`/`, `/trilhas`, `/posts`, `/live`), escrita via webhook n8n, leitura via Supabase REST.

**Visão de 6 meses:** ferramenta de curadoria + descoberta + apresentação que substitui o "jeitinho manual" de organizar referências em pastas/notion/screenshots.

---

## 2. Problema

A Case acumula referências de conteúdo em fontes dispersas (screenshots em pastas, prints no WhatsApp, notes do Notion). O time perde tempo procurando "aquela referência específica" e não consegue:

- Saber quais áreas do funil estão cobertas vs. com gap
- Compartilhar uma referência específica sem mandar PDF inteiro
- Reaproveitar transcrições em prompts/dossiês
- Acompanhar quando perfis de referência postam coisas novas
- Vincular referência → mentorada que usou aquele material

---

## 3. Objetivos

| KPI | Hoje | 30d | 90d |
|---|---|---|---|
| Referências catalogadas | ~600 | 1.000 | 2.500 |
| Tempo médio pra achar 1 ref | 5+ min | 30s | 5s |
| Cobertura do funil sem gap visível | manual | 80% | 95% |
| % referências com transcrição | ~70% | 95% | 100% |
| Reuso (refs vinculadas a 2+ mentoradas) | 0 | 20% | 50% |

---

## 4. Público

**Primário:**
- Queila Trizotti (curadoria estratégica, decisão final)
- Felipe Gobbi (operação, validação de qualidade)

**Secundário:**
- Time da Case que produz dossiês (consome refs)
- Mentoradas em fase de implementação (consomem via apresentação)

**Não-público (evitar inflar escopo):**
- Mentoradas auto-serviço — refs continuam sob curadoria humana
- Público externo — ferramenta interna, repo público mas dados internos

---

## 5. Stack & Restrições

**Stack atual (não muda sem motivo forte):**
- HTML/CSS/JS puro estático no Vercel
- GitHub público (`case-company/case-refs`)
- Supabase Case (leitura via view pública + REST anon key)
- n8n webhook (`webhook.manager01.feynmanproject.com`) recebe formulários
- Sem build step, sem framework

**Restrições:**
- Custo marginal: zero (Vercel hobby + Supabase existente + n8n existente)
- Sem servidor próprio — toda lógica no front + Supabase + n8n
- Compatibilidade: Chrome/Safari/Firefox modernos (sem suporte a IE)

---

## 6. Roadmap por Horizonte

### Horizonte 1 — IMEDIATO (1 commit cada)
**Goal:** Fechar gaps óbvios de UX e segurança que travam adoção do time.

- EPIC-01 — Quick Wins (4 stories)

### Horizonte 2 — CURTO PRAZO (horas cada)
**Goal:** Power tools de curadoria pra reduzir fricção do uso diário.

- EPIC-02 — Curadoria Power Tools (6 stories)

### Horizonte 3 — MÉDIO PRAZO (1-2 dias cada)
**Goal:** Inteligência operacional + integração com outros sistemas Case.

- EPIC-03 — Intelligence & Integration (6 stories)

### Horizonte 4 — LONGO PRAZO (semana+)
**Goal:** Capacidades transformadoras (mobile, busca semântica, comparador IA).

- EPIC-04 — AI & Mobile (3 stories)

---

## 7. Out of Scope (v1)

- Edição de classificação automática (etapa do funil, tipo estratégico) por humano — fica na confiança do classificador
- Versionamento de referências — se o post mudar no Instagram, a versão antiga não fica preservada
- Comentários/threads sociais entre time dentro da ferramenta — usar Slack/WhatsApp
- Integração com TikTok/YouTube/LinkedIn — só Instagram por enquanto
- Multi-tenancy — é instância única da Case

---

## 8. Métricas de Sucesso

**Produto:**
- Time Queila + Gobbi adicionando ≥10 refs/semana sem suporte
- 0 reclamações de "não acho a ref que adicionei" após 30d
- Pelo menos 1 dossiê produzido com refs vindas do banco em 60d

**Técnico:**
- Uptime ≥ 99% (depende Vercel + Supabase)
- p95 de carregamento `/live` < 2s
- 0 perdas de dados (write-confirms via webhook)

---

## 9. Riscos & Mitigações

| Risco | Probabilidade | Mitigação |
|---|---|---|
| n8n webhook cair | Média | Retry no client + fila local em localStorage |
| Supabase RLS bloquear writes | Baixa | Anon key só lê view pública; writes via webhook |
| URL de capa do Instagram CDN expirar | Alta | Já implementado: `displayUrl` como fallback de `thumb_local` |
| Repo público expor dados sensíveis | Média | Sem credenciais no repo; thumbs no repo são públicos por design |
| Curadoria virar gargalo | Alta | Bulk add (E2-S5) + auto-rescan (E3-S5) reduzem load humano |

---

## 10. Decisões Arquiteturais

- **Sem build step:** facilita contribuição (qualquer dev abre HTML e edita)
- **Estático no Vercel:** custo zero, deploy 30s, rollback via git
- **Supabase como banco de leitura:** já existe na Case, não duplica infra
- **n8n como pipeline:** Queila/Gobbi já operam n8n, evita criar runtime novo
- **Repo público:** facilita fork/inspiration, sem segredos no código

---

## 11. Referências

- Repo: https://github.com/case-company/case-refs
- Deploy: https://case-refs.vercel.app
- Webhook n8n: `https://webhook.manager01.feynmanproject.com/webhook/fila-referencias-novos`
- View Supabase: `v_referencias_publicas` (projeto Case)
