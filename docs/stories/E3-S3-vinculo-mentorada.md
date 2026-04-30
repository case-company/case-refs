# E3-S3 — Vincular referência → mentorada

**Epic:** EPIC-03 — Intelligence & Integration
**Status:** 🔵 Discovery (não implementada nesta sprint)

## Por que não foi implementada agora

Esta story depende de **3 fontes de dado externas** que requerem decisão humana antes:

1. **Schema da tabela de mentoradas** — case-refs não tem isso. Está em outra base de dados (Spalla, Supabase Case com RLS apropriado, ou ClickUp).
2. **Decisão de canon**: a "fonte da verdade" da lista de mentoradas é Spalla? Supabase Case? Outro? O squad precisa alinhar.
3. **RLS / permissão**: anon key atual de case-refs lê só view pública de refs. Vincular mentorada = write em tabela nova com FK pra mentorada — precisa de RLS específica.

## Pré-requisitos pra destravar

- [ ] Decisão: qual tabela é canônica pra mentoradas?
- [ ] Migration nova: `mentorada_referencias (ref_id, mentorada_id, contexto, vinculado_em, vinculado_por)`
- [ ] View pública atualizada com `mentoradas_vinculadas` agregada
- [ ] Endpoint n8n `case-refs-link-mentee` (ops `link` / `unlink`)
- [ ] Decisão UX: dropdown de mentoradas vem de onde? (cache JSON? endpoint? hardcoded?)

## Quando voltar

Quando você (Kaique) trouxer:
- Path da view de mentoradas no Supabase Case (ou export JSON da lista)
- Aprovação pra criar `mentorada_referencias`

A story fica clara em `docs/stories/E3-S3-vinculo-mentorada.md` (versão original com critérios técnicos detalhados — basta destravar pre-reqs).
