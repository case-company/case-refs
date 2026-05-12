-- E04: tabela agente.mapas_interesse (Agente 00 — Mapa de Interesse).
-- Schema conforme spec-tech §2.2.

CREATE TABLE IF NOT EXISTS agente.mapas_interesse (
  id              BIGSERIAL PRIMARY KEY,
  cliente_slug    TEXT NOT NULL,
  versao          INT NOT NULL DEFAULT 1,
  titulo          TEXT NOT NULL,
  publico         JSONB NOT NULL DEFAULT '{}'::jsonb,
  oferta          JSONB NOT NULL DEFAULT '{}'::jsonb,
  sinais_externos JSONB,
  gavetas         JSONB NOT NULL DEFAULT '{}'::jsonb,
  top_assuntos    JSONB,
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

CREATE INDEX IF NOT EXISTS idx_mapas_cliente ON agente.mapas_interesse (cliente_slug)
  WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_mapas_status ON agente.mapas_interesse (status)
  WHERE deleted_at IS NULL;

-- View publica (sem campos de provenance / custo)
DROP VIEW IF EXISTS public.v_mapas_interesse;
CREATE VIEW public.v_mapas_interesse AS
  SELECT id, cliente_slug, versao, titulo, publico, oferta, sinais_externos,
         gavetas, top_assuntos, status, created_at, updated_at, approved_at
  FROM agente.mapas_interesse
  WHERE deleted_at IS NULL
  ORDER BY created_at DESC;

GRANT SELECT ON public.v_mapas_interesse TO anon, authenticated;

COMMENT ON VIEW public.v_mapas_interesse IS
  'Mapas de interesse (Agente 00). Whitelist sem custo_usd/modelo_llm/prompt_versao.';

-- RPC: criar mapa de interesse
CREATE OR REPLACE FUNCTION public.case_agente_mapa_save(
  p_cliente_slug TEXT,
  p_titulo       TEXT,
  p_publico      JSONB,
  p_oferta       JSONB,
  p_sinais       JSONB,
  p_gavetas      JSONB,
  p_top_assuntos JSONB DEFAULT NULL
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
    FROM agente.mapas_interesse
   WHERE cliente_slug = p_cliente_slug AND deleted_at IS NULL;

  RETURN QUERY
  INSERT INTO agente.mapas_interesse
    (cliente_slug, versao, titulo, publico, oferta, sinais_externos, gavetas, top_assuntos)
  VALUES
    (p_cliente_slug, v_next_versao, p_titulo,
     coalesce(p_publico, '{}'::jsonb),
     coalesce(p_oferta, '{}'::jsonb),
     p_sinais,
     coalesce(p_gavetas, '{}'::jsonb),
     p_top_assuntos)
  RETURNING id, versao;
END;
$$;

GRANT EXECUTE ON FUNCTION public.case_agente_mapa_save(TEXT,TEXT,JSONB,JSONB,JSONB,JSONB,JSONB)
  TO anon, authenticated;
