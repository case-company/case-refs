# EPIC-01 — Quick Wins

**Status:** Ready
**Horizonte:** Imediato (1 commit por story)
**Prioridade:** P0
**Owner:** Kaique Rodrigues
**Estimate:** 1 dia total (4 stories × ~2h cada)

---

## Goal

Fechar 4 gaps óbvios de UX e segurança que travam adoção do time. Tudo é pequeno, isolado, baixo risco. Solta tudo numa tarde.

## Stories

- [x] ✅ [E1-S1: Domínio customizado refs.casein.com.br](../stories/E1-S1-dominio-customizado.md) — concluído 2026-04-30
- [x] ✅ [E1-S2: Proteção por senha (gate client-side)](../stories/E1-S2-protecao-por-senha.md) — concluído 2026-04-30
- [x] 🟡 [E1-S3: Edição inline de notas em cards](../stories/E1-S3-edicao-inline-notas.md) — frontend done, aguarda webhook n8n
- [x] 🟡 [E1-S4: Botão deletar referência com confirm](../stories/E1-S4-botao-deletar.md) — frontend done, aguarda webhook n8n

## Progresso

**4/4 stories com frontend done.**
- 2 totalmente concluídas (S1 + S2)
- 2 aguardando backend mínimo (S3 + S4 compartilham 1 migration + 1 webhook n8n)

## Backend pendente pra fechar EPIC-01

**1 migration Supabase** (~5 min):
```sql
ALTER TABLE referencias_conteudo ADD COLUMN IF NOT EXISTS deleted_at timestamptz;
CREATE OR REPLACE VIEW v_referencias_publicas AS
  SELECT * FROM referencias_conteudo WHERE deleted_at IS NULL;
```

**1 webhook n8n** (~10 min) — path `/case-refs-mutate`, switch em `body.op`:
- `update_note` → UPDATE notas
- `soft_delete` → UPDATE deleted_at

Total pra fechar epic: **~15 min de configuração backend.**

## Critérios de Sucesso

- Time acessa via URL memorável (`refs.case.com.br`)
- Acesso restrito ao time Case (sem leak público dos dados, mesmo repo público)
- Notas das refs editáveis sem subir nova ref
- Refs erradas removíveis sem ir pro Supabase

## Não inclui

- Histórico de edições (audit log) — fica em E3
- Múltiplos níveis de permissão — só "tem senha / não tem"

## Dependências externas

- Acesso ao DNS do `case.com.br` (Kaique tem)
- Conta Vercel da Case (já configurada)
- Função RPC ou endpoint no n8n pra delete/update (criar se não existir)
