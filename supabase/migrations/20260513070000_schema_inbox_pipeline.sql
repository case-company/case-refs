-- ====================================================================
-- E10 — Schema completo pra retroalimentação automática + lifecycle 4 estados
-- Aplicar no Supabase Dashboard SQL Editor.
--
-- Adiciona:
--   1) coluna `plataforma` (instagram/youtube/tiktok/meta_ads/manual)
--   2) coluna `status` enum 4 estados (inbox|curado|publicado|descartado)
--   3) coluna `objetivo` enum (Atrair|Identificar|Desejo|Confiar|Vender)
--   4) coluna `quality_score` (0-100) — usado pelo pipeline pra filtrar lixo
--   5) coluna `auto_classified` (BOOL) — marca se LLM classificou ou humano
--   6) coluna `top_player_perfil` (TEXT) — qual seed gerou esse item
--   7) Backfill das 76 refs existentes
--   8) RPC case_refs_inbox_submit (pipeline insere via essa RPC)
--   9) View v_referencias_inbox (Queila aprova daqui)
-- ====================================================================

-- 1. Colunas
ALTER TABLE agente.referencias_conteudo
  ADD COLUMN IF NOT EXISTS plataforma         TEXT,
  ADD COLUMN IF NOT EXISTS status             TEXT,
  ADD COLUMN IF NOT EXISTS quality_score      INT,
  ADD COLUMN IF NOT EXISTS auto_classified    BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS top_player_perfil  TEXT;

-- CHECK constraints
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='chk_plataforma_valida') THEN
    ALTER TABLE agente.referencias_conteudo
      ADD CONSTRAINT chk_plataforma_valida
      CHECK (plataforma IS NULL OR plataforma IN
        ('instagram','youtube','tiktok','meta_ads','linkedin','google_drive','manual'))
      NOT VALID;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='chk_status_valido') THEN
    ALTER TABLE agente.referencias_conteudo
      ADD CONSTRAINT chk_status_valido
      CHECK (status IS NULL OR status IN
        ('inbox','curado','publicado','descartado'))
      NOT VALID;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='chk_objetivo_valido') THEN
    ALTER TABLE agente.referencias_conteudo
      ADD CONSTRAINT chk_objetivo_valido
      CHECK (objetivo IS NULL OR objetivo IN
        ('Atrair','Identificar','Desejo','Confiar','Vender'))
      NOT VALID;
  END IF;
END $$;

-- 2. Backfill: refs existentes
UPDATE agente.referencias_conteudo
   SET plataforma = CASE
     WHEN url ILIKE '%instagram.com%' THEN 'instagram'
     WHEN url ILIKE '%youtube.com%' OR url ILIKE '%youtu.be%' THEN 'youtube'
     WHEN url ILIKE '%tiktok.com%' THEN 'tiktok'
     WHEN url ILIKE '%drive.google.com%' THEN 'google_drive'
     ELSE 'manual'
   END
 WHERE plataforma IS NULL AND deleted_at IS NULL;

UPDATE agente.referencias_conteudo
   SET status = CASE
     WHEN promoted_at IS NOT NULL THEN 'publicado'
     ELSE 'inbox'
   END
 WHERE status IS NULL AND deleted_at IS NULL;

-- 3. Indices
CREATE INDEX IF NOT EXISTS idx_refs_status
  ON agente.referencias_conteudo (status) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_refs_plataforma
  ON agente.referencias_conteudo (plataforma) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_refs_top_player
  ON agente.referencias_conteudo (top_player_perfil) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_refs_quality
  ON agente.referencias_conteudo (quality_score DESC) WHERE deleted_at IS NULL;

-- 4. View pra Queila aprovar inbox (escondida de /trilhas)
DROP VIEW IF EXISTS public.v_referencias_inbox;
CREATE VIEW public.v_referencias_inbox AS
  SELECT
    id, perfil, trilha, tipo_artefato, plataforma, status, top_player_perfil,
    quality_score, auto_classified,
    url, shortcode, caption, thumb_url, video_url,
    likes, comments, views, audio_duration_ms,
    transcricao, language_code,
    tipo_estrategico, etapa_funil, objetivo,
    quando_usar, por_que_funciona, como_adaptar,
    tags, created_at, promoted_at
  FROM agente.referencias_conteudo
  WHERE deleted_at IS NULL AND status = 'inbox'
  ORDER BY quality_score DESC NULLS LAST, created_at DESC;

GRANT SELECT ON public.v_referencias_inbox TO anon, authenticated;

-- 5. Adicionar plataforma+status nas views públicas existentes (drop+recreate)
DROP VIEW IF EXISTS public.v_referencias_publicas;
CREATE VIEW public.v_referencias_publicas AS
  SELECT
    id, perfil, trilha, tipo_artefato, posicao,
    COALESCE(titulo, "left"(caption, 80)) AS resumo,
    tipo_estrategico, etapa_funil,
    COALESCE(cover_url, display_url) AS thumb_url,
    url, shortcode, highlight_id, caption,
    likes, comments, views,
    CASE WHEN transcricao IS NOT NULL AND length(transcricao) > 0 THEN true ELSE false END AS tem_transcricao,
    transcricao, language_code, audio_duration_ms,
    origem, tags, created_at, promoted_at,
    quando_usar, por_que_funciona, como_adaptar, objetivo,
    plataforma, status, quality_score, auto_classified, top_player_perfil
  FROM agente.referencias_conteudo
  WHERE deleted_at IS NULL
  ORDER BY created_at DESC;

DROP VIEW IF EXISTS public.v_referencias_promovidas;
CREATE VIEW public.v_referencias_promovidas AS
  SELECT
    id, perfil, trilha, tipo_artefato, posicao,
    COALESCE(titulo, "left"(caption, 80)) AS resumo,
    tipo_estrategico, etapa_funil,
    COALESCE(cover_url, display_url) AS thumb_url,
    url, shortcode, highlight_id, caption,
    likes, comments, views,
    CASE WHEN transcricao IS NOT NULL AND length(transcricao) > 0 THEN true ELSE false END AS tem_transcricao,
    transcricao, language_code, audio_duration_ms,
    origem, tags, created_at, promoted_at,
    quando_usar, por_que_funciona, como_adaptar, objetivo,
    plataforma, status, quality_score, auto_classified, top_player_perfil
  FROM agente.referencias_conteudo
  WHERE deleted_at IS NULL AND promoted_at IS NOT NULL
  ORDER BY promoted_at DESC;

GRANT SELECT ON public.v_referencias_publicas TO anon, authenticated;
GRANT SELECT ON public.v_referencias_promovidas TO anon, authenticated;

-- 6. RPC: pipeline submete refs novas em batch (já com classificação LLM)
CREATE OR REPLACE FUNCTION public.case_refs_inbox_submit(p_items JSONB)
RETURNS TABLE(inserted_count INT, rejected_count INT, rejected_reasons JSONB)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, agente
AS $$
DECLARE
  v_item       JSONB;
  v_inserted   INT := 0;
  v_rejected   INT := 0;
  v_reasons    JSONB := '[]'::jsonb;
  v_shortcode  TEXT;
  v_url        TEXT;
  v_quality    INT;
  v_min_quality INT := 60; -- ratchet de qualidade — abaixo disso vira lixo
BEGIN
  IF jsonb_typeof(p_items) <> 'array' THEN
    RAISE EXCEPTION 'p_items must be array' USING ERRCODE='check_violation';
  END IF;

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items) LOOP
    v_shortcode := nullif(trim(v_item->>'shortcode'), '');
    v_url := nullif(trim(v_item->>'url'), '');
    v_quality := nullif(v_item->>'quality_score', '')::INT;

    -- 1. Filtro de qualidade
    IF v_quality IS NULL OR v_quality < v_min_quality THEN
      v_rejected := v_rejected + 1;
      v_reasons := v_reasons || jsonb_build_object('shortcode', v_shortcode, 'reason', 'quality_below_60', 'score', v_quality);
      CONTINUE;
    END IF;

    -- 2. Filtro: precisa de shortcode OU url
    IF v_shortcode IS NULL AND v_url IS NULL THEN
      v_rejected := v_rejected + 1;
      v_reasons := v_reasons || jsonb_build_object('reason', 'missing_url_and_shortcode');
      CONTINUE;
    END IF;

    -- 3. Dedup (shortcode OR url)
    IF EXISTS (SELECT 1 FROM agente.referencias_conteudo
                WHERE deleted_at IS NULL
                  AND ((v_shortcode IS NOT NULL AND shortcode = v_shortcode)
                       OR (v_url IS NOT NULL AND url = v_url))) THEN
      v_rejected := v_rejected + 1;
      v_reasons := v_reasons || jsonb_build_object('shortcode', v_shortcode, 'reason', 'duplicate');
      CONTINUE;
    END IF;

    -- 4. Filtro: caption ou transcricao precisa ter conteúdo mínimo
    IF coalesce(char_length(v_item->>'caption'), 0) < 30
       AND coalesce(char_length(v_item->>'transcricao'), 0) < 50 THEN
      v_rejected := v_rejected + 1;
      v_reasons := v_reasons || jsonb_build_object('shortcode', v_shortcode, 'reason', 'no_content_insights');
      CONTINUE;
    END IF;

    -- 5. Filtro: precisa de classificação editorial mínima da LLM
    IF (v_item->>'etapa_funil') IS NULL OR (v_item->>'tipo_estrategico') IS NULL THEN
      v_rejected := v_rejected + 1;
      v_reasons := v_reasons || jsonb_build_object('shortcode', v_shortcode, 'reason', 'missing_classification');
      CONTINUE;
    END IF;

    -- Passou — insere como inbox
    INSERT INTO agente.referencias_conteudo (
      perfil, trilha, tipo_artefato, plataforma, status,
      url, shortcode, caption, display_url, video_url, cover_url,
      likes, comments, views, audio_duration_ms, language_code, transcricao,
      tipo_estrategico, etapa_funil, objetivo,
      quando_usar, por_que_funciona, como_adaptar,
      origem, quality_score, auto_classified, top_player_perfil,
      timestamp_post
    ) VALUES (
      coalesce(nullif(trim(v_item->>'perfil'), ''), 'desconhecido'),
      nullif(trim(v_item->>'trilha'), ''),
      coalesce(nullif(trim(v_item->>'tipo_artefato'), ''), 'publicacao_avulsa'),
      coalesce(nullif(trim(v_item->>'plataforma'), ''), 'instagram'),
      'inbox',
      v_url, v_shortcode,
      nullif(v_item->>'caption', ''),
      nullif(v_item->>'display_url', ''),
      nullif(v_item->>'video_url', ''),
      nullif(v_item->>'cover_url', ''),
      coalesce((v_item->>'likes')::INT, 0),
      coalesce((v_item->>'comments')::INT, 0),
      coalesce((v_item->>'views')::INT, 0),
      (v_item->>'audio_duration_ms')::INT,
      nullif(v_item->>'language_code', ''),
      nullif(v_item->>'transcricao', ''),
      nullif(v_item->>'tipo_estrategico', ''),
      nullif(v_item->>'etapa_funil', ''),
      nullif(v_item->>'objetivo', ''),
      nullif(v_item->>'quando_usar', ''),
      nullif(v_item->>'por_que_funciona', ''),
      nullif(v_item->>'como_adaptar', ''),
      coalesce(nullif(v_item->>'origem', ''), 'pipeline_semanal'),
      v_quality,
      true,
      nullif(v_item->>'top_player_perfil', ''),
      (v_item->>'timestamp_post')::TIMESTAMPTZ
    );
    v_inserted := v_inserted + 1;
  END LOOP;

  inserted_count := v_inserted;
  rejected_count := v_rejected;
  rejected_reasons := v_reasons;
  RETURN NEXT;
END;
$$;

GRANT EXECUTE ON FUNCTION public.case_refs_inbox_submit(JSONB) TO anon, authenticated;

-- 7. RPC: aprovar 1 item do inbox → publicado (gatekeeper humano)
CREATE OR REPLACE FUNCTION public.case_refs_inbox_approve(p_id BIGINT)
RETURNS TABLE(out_id BIGINT, out_status TEXT, out_promoted_at TIMESTAMPTZ)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, agente
AS $$
BEGIN
  RETURN QUERY
  UPDATE agente.referencias_conteudo
     SET status = 'publicado',
         promoted_at = COALESCE(promoted_at, NOW())
   WHERE id = p_id AND deleted_at IS NULL AND status = 'inbox'
  RETURNING id, status, promoted_at;
END; $$;

GRANT EXECUTE ON FUNCTION public.case_refs_inbox_approve(BIGINT) TO anon, authenticated;

-- 8. RPC: descartar item do inbox
CREATE OR REPLACE FUNCTION public.case_refs_inbox_reject(p_id BIGINT, p_motivo TEXT DEFAULT NULL)
RETURNS TABLE(out_id BIGINT, out_status TEXT)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, agente
AS $$
BEGIN
  RETURN QUERY
  UPDATE agente.referencias_conteudo
     SET status = 'descartado',
         notas = COALESCE(notas, '') || E'\nDescartado: ' || coalesce(p_motivo, '(sem motivo)')
   WHERE id = p_id AND deleted_at IS NULL AND status = 'inbox'
  RETURNING id, status;
END; $$;

GRANT EXECUTE ON FUNCTION public.case_refs_inbox_reject(BIGINT, TEXT) TO anon, authenticated;
