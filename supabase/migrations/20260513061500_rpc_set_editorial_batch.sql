-- RPC case_refs_set_editorial_batch — update em massa dos 3 campos editoriais
-- (quando_usar, por_que_funciona, como_adaptar).
-- Aceita lookup por id OU shortcode (id tem prioridade quando ambos vêm).

CREATE OR REPLACE FUNCTION public.case_refs_set_editorial_batch(p_items JSONB)
RETURNS TABLE(updated_count INT, missing TEXT[])
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, agente
AS $$
DECLARE
  v_item       JSONB;
  v_updated    INT := 0;
  v_missing    TEXT[] := ARRAY[]::TEXT[];
  v_id         BIGINT;
  v_shortcode  TEXT;
  v_rowcount   INT;
BEGIN
  IF jsonb_typeof(p_items) <> 'array' THEN
    RAISE EXCEPTION 'p_items must be a JSONB array' USING ERRCODE = 'check_violation';
  END IF;

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items) LOOP
    v_id := nullif(v_item->>'id', '')::BIGINT;
    v_shortcode := nullif(trim(v_item->>'shortcode'), '');

    IF v_id IS NULL AND v_shortcode IS NULL THEN
      v_missing := array_append(v_missing, '(sem id nem shortcode)');
      CONTINUE;
    END IF;

    UPDATE agente.referencias_conteudo
       SET quando_usar      = COALESCE(nullif(v_item->>'quando_usar', ''), quando_usar),
           por_que_funciona = COALESCE(nullif(v_item->>'por_que_funciona', ''), por_que_funciona),
           como_adaptar     = COALESCE(nullif(v_item->>'como_adaptar', ''), como_adaptar)
     WHERE deleted_at IS NULL
       AND ((v_id IS NOT NULL AND id = v_id)
            OR (v_id IS NULL AND v_shortcode IS NOT NULL AND shortcode = v_shortcode));

    GET DIAGNOSTICS v_rowcount = ROW_COUNT;
    IF v_rowcount > 0 THEN
      v_updated := v_updated + 1;
    ELSE
      v_missing := array_append(v_missing, coalesce(v_id::TEXT, v_shortcode));
    END IF;
  END LOOP;

  updated_count := v_updated;
  missing := v_missing;
  RETURN NEXT;
END;
$$;

GRANT EXECUTE ON FUNCTION public.case_refs_set_editorial_batch(JSONB) TO anon, authenticated;
