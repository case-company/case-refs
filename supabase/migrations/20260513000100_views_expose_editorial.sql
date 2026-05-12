-- E02-S3: views expoem campos editoriais sem `notas`.
-- Sucessora da safe-view (20260512200000) — mesma estrutura derivada
-- (resumo = COALESCE(titulo, left(caption,80)),
--  thumb_url = COALESCE(cover_url, display_url))
-- + 4 campos editoriais no final.
--
-- INVARIANTE: `notas` (campo interno do curador) FICA DE FORA das duas views.
-- Antes de adicionar coluna nova a essas views, conferir se ela pode ser
-- exposta ao anon.

DROP VIEW IF EXISTS public.v_referencias_publicas;

CREATE VIEW public.v_referencias_publicas AS
  SELECT
    id,
    perfil,
    trilha,
    tipo_artefato,
    posicao,
    COALESCE(titulo, "left"(caption, 80)) AS resumo,
    tipo_estrategico,
    etapa_funil,
    COALESCE(cover_url, display_url)      AS thumb_url,
    url,
    shortcode,
    highlight_id,
    caption,
    likes,
    comments,
    views,
    CASE WHEN (transcricao IS NOT NULL AND length(transcricao) > 0) THEN true ELSE false END AS tem_transcricao,
    transcricao,
    language_code,
    audio_duration_ms,
    origem,
    tags,
    created_at,
    promoted_at,
    quando_usar,
    por_que_funciona,
    como_adaptar,
    objetivo
  FROM agente.referencias_conteudo
  WHERE deleted_at IS NULL
  ORDER BY created_at DESC;

COMMENT ON VIEW public.v_referencias_publicas IS
  'View publica. Whitelist explicita — `notas` FICA DE FORA. resumo e thumb_url derivados via COALESCE.';

DROP VIEW IF EXISTS public.v_referencias_promovidas;

CREATE VIEW public.v_referencias_promovidas AS
  SELECT
    id,
    perfil,
    trilha,
    tipo_artefato,
    posicao,
    COALESCE(titulo, "left"(caption, 80)) AS resumo,
    tipo_estrategico,
    etapa_funil,
    COALESCE(cover_url, display_url)      AS thumb_url,
    url,
    shortcode,
    highlight_id,
    caption,
    likes,
    comments,
    views,
    CASE WHEN (transcricao IS NOT NULL AND length(transcricao) > 0) THEN true ELSE false END AS tem_transcricao,
    transcricao,
    language_code,
    audio_duration_ms,
    origem,
    tags,
    created_at,
    promoted_at,
    quando_usar,
    por_que_funciona,
    como_adaptar,
    objetivo
  FROM agente.referencias_conteudo
  WHERE deleted_at IS NULL AND promoted_at IS NOT NULL
  ORDER BY promoted_at DESC;

COMMENT ON VIEW public.v_referencias_promovidas IS
  'Atalho do /trilhas para itens promovidos. Mesma seguranca da v_referencias_publicas — `notas` nunca aparece aqui.';

GRANT SELECT ON public.v_referencias_publicas TO anon, authenticated;
GRANT SELECT ON public.v_referencias_promovidas TO anon, authenticated;
