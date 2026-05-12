-- E05: tabela agente.downloads_expert (Agente 00.5 — Download do Expert).
-- Schema conforme spec-tech §2.3.

CREATE TABLE IF NOT EXISTS agente.downloads_expert (
  id              BIGSERIAL PRIMARY KEY,
  cliente_slug    TEXT NOT NULL,
  mapa_id         BIGINT REFERENCES agente.mapas_interesse(id) ON DELETE SET NULL,
  versao          INT NOT NULL DEFAULT 1,
  titulo          TEXT NOT NULL,
  crencas         JSONB,
  teses           JSONB,
  provas          JSONB,
  historias       JSONB,
  metodo          JSONB,
  linguagem       JSONB,
  fontes          JSONB,
  modelo_llm      TEXT,
  prompt_versao   TEXT,
  custo_usd       NUMERIC(8,4),
  duracao_ms      INT,
  status          TEXT NOT NULL DEFAULT 'draft'
                  CHECK (status IN ('draft','aprovado','arquivado')),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  approved_at     TIMESTAMPTZ,
  deleted_at      TIMESTAMPTZ,
  UNIQUE (cliente_slug, versao)
);

CREATE INDEX IF NOT EXISTS idx_downloads_cliente ON agente.downloads_expert (cliente_slug)
  WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_downloads_mapa ON agente.downloads_expert (mapa_id);

DROP VIEW IF EXISTS public.v_downloads_expert;
CREATE VIEW public.v_downloads_expert AS
  SELECT id, cliente_slug, mapa_id, versao, titulo,
         crencas, teses, provas, historias, metodo, linguagem, fontes,
         status, created_at, updated_at, approved_at
  FROM agente.downloads_expert
  WHERE deleted_at IS NULL
  ORDER BY created_at DESC;

GRANT SELECT ON public.v_downloads_expert TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.case_agente_download_save(
  p_cliente_slug TEXT,
  p_mapa_id      BIGINT,
  p_titulo       TEXT,
  p_crencas      JSONB,
  p_teses        JSONB,
  p_provas       JSONB,
  p_historias    JSONB,
  p_metodo       JSONB,
  p_linguagem    JSONB,
  p_fontes       JSONB
)
RETURNS TABLE(out_id BIGINT, out_versao INT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, agente
AS $$
DECLARE
  v_next_versao INT;
BEGIN
  IF coalesce(trim(p_cliente_slug), '') = '' THEN
    RAISE EXCEPTION 'missing_cliente_slug' USING ERRCODE = 'check_violation';
  END IF;
  IF coalesce(trim(p_titulo), '') = '' THEN
    RAISE EXCEPTION 'missing_titulo' USING ERRCODE = 'check_violation';
  END IF;

  SELECT coalesce(max(versao), 0) + 1 INTO v_next_versao
    FROM agente.downloads_expert
   WHERE cliente_slug = p_cliente_slug AND deleted_at IS NULL;

  RETURN QUERY
  INSERT INTO agente.downloads_expert
    (cliente_slug, mapa_id, versao, titulo,
     crencas, teses, provas, historias, metodo, linguagem, fontes)
  VALUES
    (p_cliente_slug, p_mapa_id, v_next_versao, p_titulo,
     p_crencas, p_teses, p_provas, p_historias, p_metodo, p_linguagem, p_fontes)
  RETURNING id, versao;
END;
$$;

GRANT EXECUTE ON FUNCTION public.case_agente_download_save(TEXT,BIGINT,TEXT,JSONB,JSONB,JSONB,JSONB,JSONB,JSONB,JSONB)
  TO anon, authenticated;
