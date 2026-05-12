---
id: E02-S2
title: "Edge Function: op promote_editorial"
type: story
epic: E02
status: Done (deployed em prod 2026-05-12)
priority: P0
estimated_effort: M
date: 2026-05-12
owner: Kaique Rodrigues
depends_on: [E02-S1]
---

# Story E02-S2 — Edge Function: op promote_editorial

## Story

**Como** front-end do `/live`,
**eu quero** chamar `case-refs-mutate` com `op: "promote_editorial"` enviando os 3 campos editoriais,
**para que** o servidor valide presença e tamanho antes de setar `promoted_at` — e o front receba erro 422 estruturado se algo faltar.

## Acceptance Criteria

1. Edge Function `case-refs-mutate` aceita nova operação `promote_editorial` (paralela à `promote` existente).
2. Payload esperado: `{ op: "promote_editorial", id: number, quando_usar: string, por_que_funciona: string, como_adaptar: string, objetivo?: string }`.
3. Validação server-side: cada um dos 3 campos obrigatórios deve ter `trim().length >= 20`. Falha → resposta 422 com body `{ error: "missing_editorial_fields", fields: [...] }`.
4. Em sucesso: UPDATE da linha setando os 4 campos + `promoted_at = now()`, retorna 200 com `{ id, promoted_at }`.
5. Operação `promote` antiga **permanece funcional** durante transição (rollback safety) — deprecada via comentário no código.
6. Logs de auditoria: cada chamada registrada com timestamp, `id`, autor (header `x-curator` ou similar) — destino: tabela `agente.audit_log` se existir, senão `console.log` (decisão na implementação).
7. CORS preserva configuração atual da função.

## Tasks

- [ ] Ler a Edge Function existente `case-refs-mutate` (AC 1, 5)
- [ ] Adicionar branch `if (op === "promote_editorial")` antes da branch `promote` (AC 1)
- [ ] Implementar validação de tamanho dos campos (AC 3)
- [ ] Montar UPDATE com placeholder seguro (Supabase client ou SQL parametrizado) (AC 4)
- [ ] Decidir destino dos logs (AC 6) — começar simples com `console.log` se `audit_log` não existir
- [ ] Deploy via `supabase functions deploy case-refs-mutate` (AC 1)
- [ ] Smoke `curl` direto: payload válido → 200; payload faltando `quando_usar` → 422 (AC 3, 4)

## Dev Notes

- Edge Function path: `supabase/functions/case-refs-mutate/` (estrutura padrão Supabase).
- Cliente Supabase nas Edge Functions usa `SUPABASE_SERVICE_ROLE_KEY` — disponível em env automaticamente.
- Não há autenticação cliente forte hoje — não bloquear nessa story. Header `x-curator` informativo apenas.
- A constraint do DB (E02-S1) é a defesa-em-profundidade: mesmo que a validação da função falhe, o DB rejeita.

## Testing

- Smoke: 2 curls (success + 422).
- Conferir que `promote` antiga ainda funciona após deploy (chamar um item de teste no `/live` via UI antes do E02-S4 modal mudar).

## Definition of Done

- [ ] AC 1-7 verificados
- [ ] Curl logs anexados ao PR/commit como evidência
- [ ] Commit `feat(edge-fn): op promote_editorial com validação dos 3 campos`
