-- RPC case_refs_import_batch — import em batch de referencias (E09-S2).
-- Recebe JSONB array, faz INSERT em agente.referencias_conteudo com
-- dedup por shortcode OR url. Idempotente: chamar 2x nao duplica.
--
-- Usado pelo script de import da planilha V2 da Queila.
-- Itens entram com promoted_at=NULL (pendente curadoria no /live).

CREATE OR REPLACE FUNCTION public.case_refs_import_batch(p_items JSONB)
RETURNS TABLE(inserted_count INT, skipped_count INT, sample_ids BIGINT[])
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, agente
AS $$
DECLARE
  v_item       JSONB;
  v_inserted   INT := 0;
  v_skipped    INT := 0;
  v_new_id     BIGINT;
  v_ids        BIGINT[] := ARRAY[]::BIGINT[];
  v_shortcode  TEXT;
  v_url        TEXT;
BEGIN
  IF jsonb_typeof(p_items) <> 'array' THEN
    RAISE EXCEPTION 'p_items must be a JSONB array' USING ERRCODE = 'check_violation';
  END IF;

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items) LOOP
    v_shortcode := nullif(trim(v_item->>'shortcode'), '');
    v_url := nullif(trim(v_item->>'url'), '');

    IF v_shortcode IS NULL AND v_url IS NULL THEN
      v_skipped := v_skipped + 1;
      CONTINUE;
    END IF;

    IF EXISTS (
      SELECT 1 FROM agente.referencias_conteudo
       WHERE deleted_at IS NULL
         AND ((v_shortcode IS NOT NULL AND shortcode = v_shortcode)
              OR (v_url IS NOT NULL AND url = v_url))
    ) THEN
      v_skipped := v_skipped + 1;
      CONTINUE;
    END IF;

    INSERT INTO agente.referencias_conteudo
      (perfil, trilha, tipo_artefato, url, shortcode, titulo,
       etapa_funil, tipo_estrategico, notas, origem)
    VALUES
      (nullif(trim(v_item->>'perfil'), ''),
       nullif(trim(v_item->>'trilha'), ''),
       coalesce(nullif(trim(v_item->>'tipo_artefato'), ''), 'desconhecido'),
       v_url,
       v_shortcode,
       nullif(trim(v_item->>'titulo'), ''),
       nullif(trim(v_item->>'etapa_funil'), ''),
       nullif(trim(v_item->>'tipo_estrategico'), ''),
       nullif(trim(v_item->>'notas'), ''),
       coalesce(nullif(trim(v_item->>'origem'), ''), 'import_batch'))
    RETURNING id INTO v_new_id;

    v_inserted := v_inserted + 1;
    IF v_inserted <= 5 THEN
      v_ids := array_append(v_ids, v_new_id);
    END IF;
  END LOOP;

  inserted_count := v_inserted;
  skipped_count := v_skipped;
  sample_ids := v_ids;
  RETURN NEXT;
END;
$$;

GRANT EXECUTE ON FUNCTION public.case_refs_import_batch(JSONB) TO anon, authenticated;

COMMENT ON FUNCTION public.case_refs_import_batch IS
  'Import em batch de referencias. Dedup por shortcode OR url. Itens entram com promoted_at=NULL (pendente curadoria).';
