-- Safe-view: remove `notas` (campo interno do curador) de
-- public.v_referencias_publicas — mantem mesma estrutura derivada
-- (resumo = COALESCE(titulo, left(caption,80)), thumb_url = COALESCE(...))
-- + mesma ordenacao da view atual.
--
-- DROP + CREATE porque a remocao de `notas` (que esta no meio da
-- ordenacao atual) muda a posicao das colunas, e CREATE OR REPLACE
-- nao aceita reordenacao.

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
    promoted_at
  FROM agente.referencias_conteudo
  WHERE deleted_at IS NULL
  ORDER BY created_at DESC;

COMMENT ON VIEW public.v_referencias_publicas IS
  'View publica do banco de referencias. Whitelist explicita — `notas` (campo interno do curador) FICA DE FORA por design. resumo e thumb_url sao colunas derivadas via COALESCE. Antes de adicionar coluna nova aqui, conferir se ela pode ser exposta ao anon.';

GRANT SELECT ON public.v_referencias_publicas TO anon, authenticated;
