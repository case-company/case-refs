---
id: E09-S1
title: "Mecanismo de coleta de feedback do cliente"
type: story
epic: E09
status: Done (código pronto, backend SQL pendente aplicação)
priority: P1
estimated_effort: M
date: 2026-05-12
owner: Kaique Rodrigues
---

# Story E09-S1 — Feedback do cliente

## Story

**Como** Kaique, time CASE e Queila querendo iterar o `refs.casein.com.br` com base em uso real,
**eu quero** que clientes possam enviar feedback estruturado (categoria + mensagem + email opcional) de qualquer página do site,
**para que** "pontos de confusão / sugestões / erros / elogios" não dependam de eu lembrar de perguntar nem da Queila marcar uma call.

## Acceptance Criteria

1. Tabela `agente.feedback_clientes` criada com 4 categorias canônicas (`confuso`, `sugestao`, `erro`, `elogio`) + status lifecycle (`novo|em_analise|resolvido|arquivado`).
2. View pública `v_feedback_clientes` com whitelist sem `resposta` (campo interno do curador) nem `ip_hash` (PII).
3. RPC `case_refs_feedback_submit` valida categoria, página, mensagem mínima 10 chars; hash do IP em SHA-256.
4. Widget JS `_feedback.js` injeta botão "💬 Feedback" no canto inferior direito + modal com chips de categoria + textarea + email opcional.
5. Widget incluído em `index.html`, `trilhas.html`, `live.html`, `posts.html`, `como-usar.html` via `<script src="/_feedback.js" defer>`.
6. Página admin `/feedback-admin.html` lista feedbacks com filtro por categoria + contadores agregados, escondida da landing (acessível só por URL).
7. Link "Feedback" no nav do `/dashboard`.

## Tasks

- [x] Migration `20260513010000_feedback_clientes.sql`
- [x] RPC `case_refs_feedback_submit` (BIGINT, semantic exceptions, sha256 do IP)
- [x] View `v_feedback_clientes` whitelist
- [x] `_feedback.js` widget standalone (~190 linhas vanilla JS)
- [x] Inclusão nas 5 páginas relevantes
- [x] `feedback-admin.html` com listagem + filtros
- [x] Link no nav do dashboard

## Dev Notes

- O widget chama o RPC PostgREST direto (anon key) — sem passar por Edge Function. Simplicidade > camadas.
- `p_ip` chega como `null` do navegador. Hash de IP só seria útil se um proxy server-side capturasse o cliente real. Fica como hook pro futuro.
- Status default `novo`. Curador atualiza manualmente via SQL ou via UI futura (`feedback-admin.html` em V1 é só leitura — escrita de `resposta`/`status` fica pra V1.5).
- Validações:
  - categoria ∈ {confuso, sugestao, erro, elogio} (CHECK no DB + chip do front)
  - mensagem ≥ 10 chars trim (CHECK no DB + button.disabled no front)
  - email opcional, formato não-validado (deixa cliente enviar mesmo formato esquisito)

## Testing

- Manual: abrir `/trilhas`, clicar "💬 Feedback", escolher "Sugestão", digitar "teste de feedback do smoke", enviar → "Recebido — obrigada por contar."
- Validar via REST: `GET /rest/v1/v_feedback_clientes` → retorna a linha.
- Validar via UI: abrir `/feedback-admin` → linha aparece.

## Definition of Done

- [x] AC 1-7 com código pronto
- [x] Frontend deployed (Vercel auto após push)
- [ ] Backend SQL aplicado no Dashboard (Kaique roda `20260513010000_feedback_clientes.sql`)
- [ ] Smoke E2E via UI quando backend rodar
