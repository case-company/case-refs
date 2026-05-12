-- Safe-view: substitui SELECT * por whitelist explícita de colunas em
-- v_referencias_publicas, excluindo `notas` (campo interno de curador).
--
-- Motivo: as migrations anteriores (20260430140000 e 20260512000000) usam
-- `SELECT * FROM agente.referencias_conteudo` o que expõe a coluna `notas`
-- (texto interno do curador) via anon key. Hoje a coluna está vazia, mas
-- assim que E01/E02 entrar e curadores começarem a anotar coisas tipo
-- "mentorada X ainda nao pagou — nao promover", esse texto vaza para o
-- mundo. Esta migration tampa o vazamento ANTES que E01 popule.
--
-- Esta migration é idempotente (CREATE OR REPLACE) e reversível
-- (basta reaplicar a versao anterior do CREATE OR REPLACE).

CREATE OR REPLACE VIEW public.v_referencias_publicas AS
  SELECT
    id,
    perfil,
    trilha,
    tipo_artefato,
    posicao,
    url,
    shortcode,
    formato,
    caption,
    display_url,
    video_url,
    cover_url,
    titulo,
    likes,
    comments,
    views,
    timestamp_post,
    transcricao,
    language_code,
    audio_duration_ms,
    tipo_estrategico,
    etapa_funil,
    tags,
    promoted_at,
    created_at,
    updated_at
  FROM agente.referencias_conteudo
  WHERE deleted_at IS NULL;

COMMENT ON VIEW public.v_referencias_publicas IS
  'View publica do banco de referencias. Whitelist explicita de colunas — `notas` (campo interno do curador) FICA DE FORA por design. Antes de adicionar coluna nova aqui, conferir se ela pode ser exposta ao anon.';

GRANT SELECT ON public.v_referencias_publicas TO anon, authenticated;
