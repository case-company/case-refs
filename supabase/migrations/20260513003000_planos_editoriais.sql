-- E06: tabela agente.planos_editoriais (Agente 01 — Estrategista).
-- Schema conforme spec-tech §2.4.

CREATE TABLE IF NOT EXISTS agente.planos_editoriais (
  id              BIGSERIAL PRIMARY KEY,
  cliente_slug    TEXT NOT NULL,
  mapa_id         BIGINT REFERENCES agente.mapas_interesse(id) ON DELETE SET NULL,
  download_id     BIGINT REFERENCES agente.downloads_expert(id) ON DELETE SET NULL,
  versao          INT NOT NULL DEFAULT 1,
  titulo          TEXT NOT NULL,
  fase            TEXT NOT NULL CHECK (fase IN ('D+E','VENDAS','MISTO')),
  capacidade      JSONB NOT NULL DEFAULT '{}'::jsonb,
  historico       JSONB,
  mix_alvo        JSONB NOT NULL DEFAULT '{"D_E":0.7,"C_I_D":0.3,"A":0.0}'::jsonb,
  banco_ideias    JSONB NOT NULL DEFAULT '[]'::jsonb,
  cronograma      JSONB,
  valido          BOOLEAN GENERATED ALWAYS AS (
    jsonb_typeof(banco_ideias) = 'array'
    AND jsonb_array_length(banco_ideias) > 0
  ) STORED,
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

CREATE INDEX IF NOT EXISTS idx_planos_cliente ON agente.planos_editoriais (cliente_slug)
  WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_planos_mapa ON agente.planos_editoriais (mapa_id);
CREATE INDEX IF NOT EXISTS idx_planos_download ON agente.planos_editoriais (download_id);

DROP VIEW IF EXISTS public.v_planos_editoriais;
CREATE VIEW public.v_planos_editoriais AS
  SELECT id, cliente_slug, mapa_id, download_id, versao, titulo,
         fase, capacidade, historico, mix_alvo, banco_ideias, cronograma, valido,
         status, created_at, updated_at, approved_at
  FROM agente.planos_editoriais
  WHERE deleted_at IS NULL
  ORDER BY created_at DESC;

GRANT SELECT ON public.v_planos_editoriais TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.case_agente_plano_save(
  p_cliente_slug TEXT,
  p_mapa_id      BIGINT,
  p_download_id  BIGINT,
  p_titulo       TEXT,
  p_fase         TEXT,
  p_capacidade   JSONB,
  p_historico    JSONB,
  p_mix_alvo     JSONB,
  p_banco_ideias JSONB,
  p_cronograma   JSONB
)
RETURNS TABLE(out_id BIGINT, out_versao INT, out_valido BOOLEAN)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, agente
AS $$
DECLARE
  v_next_versao INT;
  v_row         agente.planos_editoriais%ROWTYPE;
BEGIN
  IF coalesce(trim(p_cliente_slug), '') = '' THEN
    RAISE EXCEPTION 'missing_cliente_slug' USING ERRCODE = 'check_violation';
  END IF;
  IF coalesce(trim(p_titulo), '') = '' THEN
    RAISE EXCEPTION 'missing_titulo' USING ERRCODE = 'check_violation';
  END IF;
  IF p_fase NOT IN ('D+E','VENDAS','MISTO') THEN
    RAISE EXCEPTION 'invalid_fase: %', p_fase USING ERRCODE = 'check_violation';
  END IF;

  SELECT coalesce(max(versao), 0) + 1 INTO v_next_versao
    FROM agente.planos_editoriais
   WHERE cliente_slug = p_cliente_slug AND deleted_at IS NULL;

  INSERT INTO agente.planos_editoriais
    (cliente_slug, mapa_id, download_id, versao, titulo,
     fase, capacidade, historico, mix_alvo, banco_ideias, cronograma)
  VALUES
    (p_cliente_slug, p_mapa_id, p_download_id, v_next_versao, p_titulo,
     p_fase,
     coalesce(p_capacidade, '{}'::jsonb),
     p_historico,
     coalesce(p_mix_alvo, '{"D_E":0.7,"C_I_D":0.3,"A":0.0}'::jsonb),
     coalesce(p_banco_ideias, '[]'::jsonb),
     p_cronograma)
  RETURNING * INTO v_row;

  out_id := v_row.id;
  out_versao := v_row.versao;
  out_valido := v_row.valido;
  RETURN NEXT;
END;
$$;

GRANT EXECUTE ON FUNCTION public.case_agente_plano_save(TEXT,BIGINT,BIGINT,TEXT,TEXT,JSONB,JSONB,JSONB,JSONB,JSONB)
  TO anon, authenticated;
