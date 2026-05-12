---
title: E04-E07 Smoke E2E dos 4 Agentes — 2026-05-12
type: test-run
status: PASS
date: 2026-05-12
operator: Zion (autônomo, sob autorização do Kaique)
target: case-refs / Supabase project knusqfbvhsqworzyhvip
---

# E04-E07 Smoke E2E — 2026-05-12 PASS

Validação end-to-end dos 4 agentes editoriais via cURL direto contra os RPCs do Supabase. `cliente_slug` de teste: `smoke-test-zion`.

## Resultado

**PASS — 4/4 RPCs + 4/4 views + 2/2 validações negativas**

### Positivos

| # | Agente | RPC | Resultado |
|---|--------|-----|-----------|
| 1 | 00 — Mapa | `case_agente_mapa_save` | 200 `[{out_id:1,out_versao:1}]` |
| 2 | 00.5 — Download | `case_agente_download_save` | 200 `[{out_id:1,out_versao:1}]` |
| 3 | 01 — Estrategista | `case_agente_plano_save` | 200 `[{out_id:1,out_versao:1,out_valido:true}]` |
| 4 | 02 — Modelador | `case_agente_roteiro_save` | 200 `[{out_id:1}]` |

Cada save retornou os campos esperados pelo schema `RETURNS TABLE`. Cadeia de FK valida: Mapa(1) → Download(1, mapa_id=1) → Plano(1, mapa_id=1, download_id=1) → Roteiro(1, plano_id=1).

### Views

Cada uma das 4 views retornou exatamente 1 linha filtrando por `cliente_slug=eq.smoke-test-zion`:
- `v_mapas_interesse`     → 1 row (status=draft)
- `v_downloads_expert`    → 1 row (status=draft)
- `v_planos_editoriais`   → 1 row (status=draft, fase=D+E, **valido=true**)
- `v_roteiros_modelados`  → 1 row (status=draft, formato_visual=reel)

### Validações negativas

1. **Mapa sem `cliente_slug`** → `HTTP 400 {"code":"23514","message":"missing_cliente_slug"}` — RAISE EXCEPTION semântico funciona.
2. **Plano com `banco_ideias=[]`** → `out_valido=false` — coluna GENERATED detecta P6 inválido (sem array não-vazio).

## Observações

1. **Dados de smoke ficaram no DB** (`cliente_slug='smoke-test-zion'`, 4 rows na schema `agente.*` + 1 plano extra com banco vazio). Cleanup manual via Dashboard se quiser remover:
   ```sql
   UPDATE agente.mapas_interesse SET deleted_at=NOW() WHERE cliente_slug='smoke-test-zion';
   UPDATE agente.downloads_expert SET deleted_at=NOW() WHERE cliente_slug='smoke-test-zion';
   UPDATE agente.planos_editoriais SET deleted_at=NOW() WHERE cliente_slug='smoke-test-zion';
   UPDATE agente.roteiros_modelados SET deleted_at=NOW() WHERE cliente_slug='smoke-test-zion';
   ```
   As views filtram `deleted_at IS NULL` então um soft delete some da UI.

2. **Tipagem BIGINT consistente** — diferente do E02 onde tive que fazer fix tardio, os 4 RPCs já saíram com `BIGINT` desde o início + alias `out_*` pra evitar ambiguidade.

3. **PostgREST CORS** — todos os calls bateram com `apikey + Authorization Bearer` headers; nenhum 401/403. View pública grants em `anon` confirmaram.

## Conclusão

Os 4 agentes editoriais (E04-E07) estão operacionais em produção. Frontend (Vercel) + Backend (Supabase) integrados. V1 do Content System CASE está completo.

Próximo passo (E08-S1): commit final `chore: V1 release` + atualizar README marcando 1.0.0 released.
