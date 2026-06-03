-- Thumb permanente no Supabase Storage (URLs do CDN do Instagram expiram em
-- horas/dias — mesmo padrão que já quebrou as fotos do Spalla).
-- O pipeline n8n baixa display_url/cover_url no ingest e sobe pro bucket
-- público `refs-thumbs`; aqui só o schema + views.

ALTER TABLE agente.referencias_conteudo
  ADD COLUMN IF NOT EXISTS thumb_storage_url TEXT;

COMMENT ON COLUMN agente.referencias_conteudo.thumb_storage_url IS
  'URL pública no Supabase Storage (bucket refs-thumbs). Permanente — preferida sobre cover_url/display_url do CDN IG, que expiram.';

-- Bucket público de thumbs (leitura anônima via /storage/v1/object/public/;
-- escrita só via service_role do n8n — bypassa RLS, sem policy extra).
INSERT INTO storage.buckets (id, name, public)
VALUES ('refs-thumbs', 'refs-thumbs', true)
ON CONFLICT (id) DO NOTHING;

-- Views: thumb_url passa a preferir o Storage. Mesma whitelist de sempre —
-- `notas` segue de fora (invariante das views públicas).
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
    COALESCE(thumb_storage_url, cover_url, display_url) AS thumb_url,
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
  'View publica. Whitelist explicita — `notas` FICA DE FORA. thumb_url prefere Storage permanente sobre CDN IG.';

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
    COALESCE(thumb_storage_url, cover_url, display_url) AS thumb_url,
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
  'Atalho do /trilhas para itens promovidos. Mesma seguranca da v_referencias_publicas.';

GRANT SELECT ON public.v_referencias_publicas TO anon, authenticated;
GRANT SELECT ON public.v_referencias_promovidas TO anon, authenticated;
