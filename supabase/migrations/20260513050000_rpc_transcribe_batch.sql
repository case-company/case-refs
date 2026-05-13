-- RPC case_refs_transcribe_batch — update em massa de transcrição.
-- Recebe array de {shortcode, transcricao, language_code, audio_duration_ms}.
-- Preserva campos editoriais e curadoria humana.

CREATE OR REPLACE FUNCTION public.case_refs_transcribe_batch(p_items JSONB)
RETURNS TABLE(updated_count INT, missing_shortcodes TEXT[])
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, agente
AS $$
DECLARE
  v_item       JSONB;
  v_updated    INT := 0;
  v_missing    TEXT[] := ARRAY[]::TEXT[];
  v_shortcode  TEXT;
  v_rowcount   INT;
BEGIN
  IF jsonb_typeof(p_items) <> 'array' THEN
    RAISE EXCEPTION 'p_items must be a JSONB array' USING ERRCODE = 'check_violation';
  END IF;

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items) LOOP
    v_shortcode := nullif(trim(v_item->>'shortcode'), '');
    IF v_shortcode IS NULL THEN CONTINUE; END IF;

    UPDATE agente.referencias_conteudo
       SET transcricao        = COALESCE(nullif(v_item->>'transcricao', ''), transcricao),
           language_code      = COALESCE(nullif(v_item->>'language_code', ''), language_code),
           audio_duration_ms  = COALESCE((v_item->>'audio_duration_ms')::INT, audio_duration_ms)
     WHERE shortcode = v_shortcode
       AND deleted_at IS NULL;

    GET DIAGNOSTICS v_rowcount = ROW_COUNT;
    IF v_rowcount > 0 THEN
      v_updated := v_updated + 1;
    ELSE
      v_missing := array_append(v_missing, v_shortcode);
    END IF;
  END LOOP;

  updated_count := v_updated;
  missing_shortcodes := v_missing;
  RETURN NEXT;
END;
$$;

GRANT EXECUTE ON FUNCTION public.case_refs_transcribe_batch(JSONB) TO anon, authenticated;

COMMENT ON FUNCTION public.case_refs_transcribe_batch IS
  'Update em batch de transcricao+language_code+audio_duration_ms. Preserva tudo mais.';
