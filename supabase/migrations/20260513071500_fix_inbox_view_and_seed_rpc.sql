-- Fix 1: v_referencias_inbox usava 'thumb_url' como coluna (não é — é derivado).
-- Fix 2: RPC case_refs_top_players_seed (usada pelo n8n).

DROP VIEW IF EXISTS public.v_referencias_inbox;
CREATE VIEW public.v_referencias_inbox AS
  SELECT
    id, perfil, trilha, tipo_artefato, plataforma, status, top_player_perfil,
    quality_score, auto_classified,
    url, shortcode, caption,
    COALESCE(cover_url, display_url) AS thumb_url,
    video_url,
    likes, comments, views, audio_duration_ms,
    transcricao, language_code,
    tipo_estrategico, etapa_funil, objetivo,
    quando_usar, por_que_funciona, como_adaptar,
    tags, created_at, promoted_at
  FROM agente.referencias_conteudo
  WHERE deleted_at IS NULL AND status = 'inbox'
  ORDER BY quality_score DESC NULLS LAST, created_at DESC;

GRANT SELECT ON public.v_referencias_inbox TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.case_refs_top_players_seed(
  p_limit     INT DEFAULT 30,
  p_min_score INT DEFAULT 80
)
RETURNS TABLE(perfil TEXT, refs_count BIGINT, max_score INT, trilha TEXT)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, agente
AS $$
BEGIN
  RETURN QUERY
  SELECT
    r.perfil::TEXT,
    count(*) AS refs_count,
    coalesce(max(r.quality_score), 0) AS max_score,
    mode() WITHIN GROUP (ORDER BY r.trilha)::TEXT AS trilha
  FROM agente.referencias_conteudo r
  WHERE r.deleted_at IS NULL
    AND r.status = 'publicado'
    AND r.perfil IS NOT NULL
    AND r.perfil <> 'desconhecido'
  GROUP BY r.perfil
  HAVING count(*) >= 1 AND coalesce(max(r.quality_score), 100) >= p_min_score
  ORDER BY refs_count DESC, max_score DESC
  LIMIT p_limit;
END;
$$;

GRANT EXECUTE ON FUNCTION public.case_refs_top_players_seed(INT, INT) TO anon, authenticated;

COMMENT ON FUNCTION public.case_refs_top_players_seed IS
  'Retorna perfis seed pro cron semanal: top N perfis com refs publicadas e qualidade >= threshold.';
