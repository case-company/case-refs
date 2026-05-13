-- RPC case_refs_enrich_batch — atualiza metadados Apify em massa.
-- Recebe array JSONB com shortcode + campos do Apify (caption/display_url/
-- video_url/cover_url/perfil/likes/comments/views/timestamp/audio_url).
-- Faz UPDATE por shortcode preservando campos editoriais (etapa_funil,
-- tipo_estrategico, titulo, quando_usar, por_que_funciona, como_adaptar,
-- objetivo, trilha, origem, notas, tags, promoted_at).

CREATE OR REPLACE FUNCTION public.case_refs_enrich_batch(p_items JSONB)
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
       SET caption           = COALESCE(nullif(v_item->>'caption', ''), caption),
           display_url       = COALESCE(nullif(v_item->>'display_url', ''), display_url),
           video_url         = COALESCE(nullif(v_item->>'video_url', ''), video_url),
           cover_url         = COALESCE(nullif(v_item->>'cover_url', ''), cover_url),
           perfil            = CASE
                                  WHEN perfil = 'desconhecido' AND nullif(v_item->>'perfil', '') IS NOT NULL
                                  THEN v_item->>'perfil'
                                  ELSE perfil
                               END,
           likes             = COALESCE((v_item->>'likes')::INT, likes),
           comments          = COALESCE((v_item->>'comments')::INT, comments),
           views             = COALESCE((v_item->>'views')::INT, views),
           timestamp_post    = COALESCE((v_item->>'timestamp_post')::TIMESTAMPTZ, timestamp_post)
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

GRANT EXECUTE ON FUNCTION public.case_refs_enrich_batch(JSONB) TO anon, authenticated;

COMMENT ON FUNCTION public.case_refs_enrich_batch IS
  'Update em batch de metadados Apify. Preserva campos editoriais e curadoria humana.';
