-- E02-S3: views expoem campos editoriais sem `notas`.
-- Sucessora da safe-view (20260512200000) — mantem whitelist explicita
-- e adiciona os 4 campos editoriais. Cria tambem v_referencias_promovidas.
--
-- INVARIANTE: `notas` (campo interno do curador) FICA DE FORA das duas views.
-- Antes de adicionar coluna nova a essas views, conferir se ela pode ser
-- exposta ao anon.
--
-- Estrategia: DROP + CREATE para permitir adicao de colunas no final
-- (CREATE OR REPLACE bloqueia se ordem das colunas mudou).

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
    promoted_at,
    quando_usar,
    por_que_funciona,
    como_adaptar,
    objetivo
  FROM agente.referencias_conteudo
  WHERE deleted_at IS NULL;

COMMENT ON VIEW public.v_referencias_publicas IS
  'View publica do banco. Whitelist explicita — `notas` (interno do curador) FICA DE FORA. Antes de adicionar coluna nova aqui, conferir se ela pode ser exposta ao anon.';

DROP VIEW IF EXISTS public.v_referencias_promovidas;

CREATE VIEW public.v_referencias_promovidas AS
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
    promoted_at,
    quando_usar,
    por_que_funciona,
    como_adaptar,
    objetivo
  FROM agente.referencias_conteudo
  WHERE deleted_at IS NULL AND promoted_at IS NOT NULL
  ORDER BY promoted_at DESC;

COMMENT ON VIEW public.v_referencias_promovidas IS
  'Atalho do /trilhas para itens promovidos. Mesma regra de seguranca da v_referencias_publicas — `notas` nunca aparece aqui.';

GRANT SELECT ON public.v_referencias_publicas TO anon, authenticated;
GRANT SELECT ON public.v_referencias_promovidas TO anon, authenticated;
