-- Safe-view: substitui SELECT * por whitelist explicita em
-- v_referencias_publicas, excluindo `notas` (campo interno do curador).
--
-- Por que DROP + CREATE em vez de CREATE OR REPLACE:
--   o SELECT * anterior gerou a view com ordem fixa de colunas que
--   inclui `notas` no meio. CREATE OR REPLACE exige preservar nome+ordem
--   das colunas; pra remover `notas` do meio precisamos recriar a view.

DROP VIEW IF EXISTS public.v_referencias_publicas;

CREATE VIEW public.v_referencias_publicas AS
  SELECT
    id,
    perfil,
    trilha,
    tipo_artefato,
    posicao,
    resumo,
    tipo_estrategico,
    etapa_funil,
    thumb_url,
    url,
    shortcode,
    highlight_id,
    caption,
    likes,
    comments,
    views,
    tem_transcricao,
    transcricao,
    language_code,
    audio_duration_ms,
    origem,
    tags,
    created_at,
    promoted_at
  FROM agente.referencias_conteudo
  WHERE deleted_at IS NULL;

COMMENT ON VIEW public.v_referencias_publicas IS
  'View publica do banco de referencias. Whitelist explicita de colunas — `notas` (campo interno do curador) FICA DE FORA por design. Antes de adicionar coluna nova aqui, conferir se ela pode ser exposta ao anon.';

GRANT SELECT ON public.v_referencias_publicas TO anon, authenticated;
