-- E07: tabela agente.roteiros_modelados (Agente 02 — Modelador).
-- Schema conforme spec-tech §2.5.

CREATE TABLE IF NOT EXISTS agente.roteiros_modelados (
  id              BIGSERIAL PRIMARY KEY,
  cliente_slug    TEXT NOT NULL,
  referencia_id   BIGINT REFERENCES agente.referencias_conteudo(id) ON DELETE SET NULL,
  referencia_url  TEXT,
  formato_visual  TEXT NOT NULL CHECK (formato_visual IN
                    ('reel','carrossel','story','live','post_estatico','video_longo')),
  ideia_alvo      TEXT NOT NULL,
  plano_id        BIGINT REFERENCES agente.planos_editoriais(id) ON DELETE SET NULL,
  estrutura       JSONB NOT NULL DEFAULT '{}'::jsonb,
  roteiro         JSONB NOT NULL DEFAULT '{}'::jsonb,
  observacoes     TEXT,
  modelo_llm      TEXT,
  prompt_versao   TEXT,
  custo_usd       NUMERIC(8,4),
  duracao_ms      INT,
  status          TEXT NOT NULL DEFAULT 'draft'
                  CHECK (status IN ('draft','aprovado','arquivado','publicado')),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  approved_at     TIMESTAMPTZ,
  published_at    TIMESTAMPTZ,
  deleted_at      TIMESTAMPTZ,
  CHECK (referencia_id IS NOT NULL OR referencia_url IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS idx_roteiros_cliente ON agente.roteiros_modelados (cliente_slug)
  WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_roteiros_referencia ON agente.roteiros_modelados (referencia_id);
CREATE INDEX IF NOT EXISTS idx_roteiros_plano ON agente.roteiros_modelados (plano_id);

DROP VIEW IF EXISTS public.v_roteiros_modelados;
CREATE VIEW public.v_roteiros_modelados AS
  SELECT id, cliente_slug, referencia_id, referencia_url, formato_visual,
         ideia_alvo, plano_id, estrutura, roteiro, observacoes,
         status, created_at, updated_at, approved_at, published_at
  FROM agente.roteiros_modelados
  WHERE deleted_at IS NULL
  ORDER BY created_at DESC;

GRANT SELECT ON public.v_roteiros_modelados TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.case_agente_roteiro_save(
  p_cliente_slug   TEXT,
  p_referencia_id  BIGINT,
  p_referencia_url TEXT,
  p_formato_visual TEXT,
  p_ideia_alvo     TEXT,
  p_plano_id       BIGINT,
  p_estrutura      JSONB,
  p_roteiro        JSONB,
  p_observacoes    TEXT
)
RETURNS TABLE(out_id BIGINT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, agente
AS $$
BEGIN
  IF coalesce(trim(p_cliente_slug), '') = '' THEN
    RAISE EXCEPTION 'missing_cliente_slug' USING ERRCODE = 'check_violation';
  END IF;
  IF coalesce(trim(p_ideia_alvo), '') = '' THEN
    RAISE EXCEPTION 'missing_ideia_alvo' USING ERRCODE = 'check_violation';
  END IF;
  IF p_formato_visual NOT IN ('reel','carrossel','story','live','post_estatico','video_longo') THEN
    RAISE EXCEPTION 'invalid_formato_visual: %', p_formato_visual USING ERRCODE = 'check_violation';
  END IF;
  IF p_referencia_id IS NULL AND coalesce(trim(p_referencia_url), '') = '' THEN
    RAISE EXCEPTION 'missing_referencia' USING ERRCODE = 'check_violation';
  END IF;

  RETURN QUERY
  INSERT INTO agente.roteiros_modelados
    (cliente_slug, referencia_id, referencia_url, formato_visual, ideia_alvo, plano_id,
     estrutura, roteiro, observacoes)
  VALUES
    (p_cliente_slug, p_referencia_id, nullif(trim(coalesce(p_referencia_url, '')), ''),
     p_formato_visual, p_ideia_alvo, p_plano_id,
     coalesce(p_estrutura, '{}'::jsonb),
     coalesce(p_roteiro, '{}'::jsonb),
     p_observacoes)
  RETURNING id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.case_agente_roteiro_save(TEXT,BIGINT,TEXT,TEXT,TEXT,BIGINT,JSONB,JSONB,TEXT)
  TO anon, authenticated;
