-- E02-S2 (parte SQL): RPC case_refs_promote_editorial.
-- Valida server-side (>= 20 chars em cada um dos 3 campos) antes de promover.
-- Edge Function `case-refs-mutate` delega aqui via op="promote_editorial".

CREATE OR REPLACE FUNCTION public.case_refs_promote_editorial(
  p_id              INT,
  p_quando_usar     TEXT,
  p_por_que_funciona TEXT,
  p_como_adaptar    TEXT,
  p_objetivo        TEXT DEFAULT NULL
)
RETURNS TABLE(id INT, promoted_at TIMESTAMPTZ)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_missing TEXT[] := ARRAY[]::TEXT[];
BEGIN
  -- Validacao de tamanho minimo (defesa em profundidade — a CHECK
  -- constraint da tabela tambem barra, mas damos erro mais semantico).
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
  UPDATE referencias_conteudo
     SET quando_usar      = trim(p_quando_usar),
         por_que_funciona = trim(p_por_que_funciona),
         como_adaptar     = trim(p_como_adaptar),
         objetivo         = nullif(trim(coalesce(p_objetivo, '')), ''),
         promoted_at      = NOW()
   WHERE referencias_conteudo.id = p_id
     AND deleted_at IS NULL
  RETURNING referencias_conteudo.id, referencias_conteudo.promoted_at;
END;
$$;

GRANT EXECUTE ON FUNCTION public.case_refs_promote_editorial(INT, TEXT, TEXT, TEXT, TEXT)
  TO anon, authenticated;

COMMENT ON FUNCTION public.case_refs_promote_editorial(INT, TEXT, TEXT, TEXT, TEXT) IS
  'Promove item de /live pro /trilhas exigindo 3 campos editoriais >= 20 chars. Substitui case_refs_promote para fluxos novos. Legado mantido em case_refs_promote.';
