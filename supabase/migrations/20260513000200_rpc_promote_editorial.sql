-- E02-S2 (parte SQL): RPC case_refs_promote_editorial.
-- Valida server-side (>= 20 chars em cada um dos 3 campos) antes de promover.
-- Edge Function `case-refs-mutate` delega aqui via op="promote_editorial".
--
-- Notas de tipagem:
--   - id da tabela e BIGSERIAL (BIGINT). RETURNS TABLE declara BIGINT
--     para evitar "structure of query does not match function result type".
--   - OUT params nomeados out_id/out_promoted_at evita ambiguidade com
--     coluna id da tabela no RETURNING.
--
-- O op="promote" antigo foi removido — a check constraint
-- chk_promoted_requires_editorial_fields rejeita promocoes sem
-- os 3 campos editoriais, tornando case_refs_promote(p_id) inutilizavel.

DROP FUNCTION IF EXISTS public.case_refs_promote_editorial(INT, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.case_refs_promote_editorial(BIGINT, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.case_refs_promote(INT);
DROP FUNCTION IF EXISTS public.case_refs_promote(BIGINT);

CREATE OR REPLACE FUNCTION public.case_refs_promote_editorial(
  p_id              BIGINT,
  p_quando_usar     TEXT,
  p_por_que_funciona TEXT,
  p_como_adaptar    TEXT,
  p_objetivo        TEXT DEFAULT NULL
)
RETURNS TABLE(out_id BIGINT, out_promoted_at TIMESTAMPTZ)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, agente
AS $$
DECLARE
  v_missing TEXT[] := ARRAY[]::TEXT[];
BEGIN
  IF char_length(coalesce(trim(p_quando_usar), '')) < 20 THEN
    v_missing := array_append(v_missing, 'quando_usar');
  END IF;
  IF char_length(coalesce(trim(p_por_que_funciona), '')) < 20 THEN
    v_missing := array_append(v_missing, 'por_que_funciona');
  END IF;
  IF char_length(coalesce(trim(p_como_adaptar), '')) < 20 THEN
    v_missing := array_append(v_missing, 'como_adaptar');
  END IF;

  IF array_length(v_missing, 1) > 0 THEN
    RAISE EXCEPTION 'missing_editorial_fields: %', array_to_string(v_missing, ',')
      USING ERRCODE = 'check_violation';
  END IF;

  RETURN QUERY
  UPDATE agente.referencias_conteudo r
     SET quando_usar      = trim(p_quando_usar),
         por_que_funciona = trim(p_por_que_funciona),
         como_adaptar     = trim(p_como_adaptar),
         objetivo         = nullif(trim(coalesce(p_objetivo, '')), ''),
         promoted_at      = NOW()
   WHERE r.id = p_id
     AND r.deleted_at IS NULL
  RETURNING r.id, r.promoted_at;
END;
$$;

GRANT EXECUTE ON FUNCTION public.case_refs_promote_editorial(BIGINT, TEXT, TEXT, TEXT, TEXT)
  TO anon, authenticated;

COMMENT ON FUNCTION public.case_refs_promote_editorial(BIGINT, TEXT, TEXT, TEXT, TEXT) IS
  'Promove item de /live pro /trilhas exigindo 3 campos editoriais >= 20 chars.';
