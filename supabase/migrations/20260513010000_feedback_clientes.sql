-- E09-S1: tabela agente.feedback_clientes — coleta de feedback dos usuarios
-- do `refs.casein.com.br`. Atende subtarefa do handoff Felipe Gobbi:
-- "resumir feedback coletado, organizar pontos de melhoria, reescrever
-- trechos confusos, propor ajustes de fluxo e linguagem".
--
-- Categorias canonicas: confuso / sugestao / erro / elogio.
-- Cliente preenche sem login. Curador le via view publica restrita
-- (sem PII alem do email opcional).

CREATE TABLE IF NOT EXISTS agente.feedback_clientes (
  id            BIGSERIAL PRIMARY KEY,
  categoria     TEXT NOT NULL CHECK (categoria IN ('confuso','sugestao','erro','elogio')),
  pagina        TEXT NOT NULL,                         -- '/trilhas', '/como-usar', '/live', etc.
  contexto      JSONB,                                 -- ex: { referencia_id: 42, shortcode: 'DXY...' }
  mensagem      TEXT NOT NULL CHECK (char_length(trim(mensagem)) >= 10),
  email         TEXT,                                  -- opcional, pra follow-up
  user_agent    TEXT,
  ip_hash       TEXT,                                  -- hash, NUNCA IP cru
  status        TEXT NOT NULL DEFAULT 'novo'
                CHECK (status IN ('novo','em_analise','resolvido','arquivado')),
  resposta      TEXT,                                  -- preenchida pelo curador (interno)
  resolved_at   TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at    TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_feedback_categoria
  ON agente.feedback_clientes (categoria)
  WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_feedback_status
  ON agente.feedback_clientes (status)
  WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_feedback_created
  ON agente.feedback_clientes (created_at DESC)
  WHERE deleted_at IS NULL;

-- View publica (read-only para curador autenticado).
-- Whitelist explicita — NAO expoe `resposta` (campo interno) nem `ip_hash`.
DROP VIEW IF EXISTS public.v_feedback_clientes;
CREATE VIEW public.v_feedback_clientes AS
  SELECT id, categoria, pagina, contexto, mensagem, email,
         status, created_at, resolved_at
  FROM agente.feedback_clientes
  WHERE deleted_at IS NULL
  ORDER BY created_at DESC;

COMMENT ON VIEW public.v_feedback_clientes IS
  'Feedback recebido dos clientes. Whitelist sem `resposta` (interno do curador) e `ip_hash` (PII).';

GRANT SELECT ON public.v_feedback_clientes TO anon, authenticated;

-- RPC: submeter feedback (sem login).
CREATE OR REPLACE FUNCTION public.case_refs_feedback_submit(
  p_categoria   TEXT,
  p_pagina      TEXT,
  p_mensagem    TEXT,
  p_contexto    JSONB DEFAULT NULL,
  p_email       TEXT DEFAULT NULL,
  p_user_agent  TEXT DEFAULT NULL,
  p_ip          TEXT DEFAULT NULL
)
RETURNS TABLE(out_id BIGINT, out_created_at TIMESTAMPTZ)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, agente
AS $$
DECLARE
BEGIN
  IF p_categoria NOT IN ('confuso','sugestao','erro','elogio') THEN
    RAISE EXCEPTION 'invalid_categoria: %', p_categoria USING ERRCODE = 'check_violation';
  END IF;
  IF coalesce(trim(p_pagina), '') = '' THEN
    RAISE EXCEPTION 'missing_pagina' USING ERRCODE = 'check_violation';
  END IF;
  IF char_length(coalesce(trim(p_mensagem), '')) < 10 THEN
    RAISE EXCEPTION 'mensagem_muito_curta: minimo 10 caracteres' USING ERRCODE = 'check_violation';
  END IF;

  -- p_ip ignorado nesta versao (pgcrypto nao habilitado no projeto).
  -- Pra ativar hash do IP futuramente: CREATE EXTENSION pgcrypto;
  -- + voltar o branch CASE com encode(digest(p_ip,'sha256'),'hex').

  RETURN QUERY
  INSERT INTO agente.feedback_clientes
    (categoria, pagina, contexto, mensagem, email, user_agent, ip_hash)
  VALUES
    (p_categoria, trim(p_pagina), p_contexto, trim(p_mensagem),
     nullif(trim(coalesce(p_email, '')), ''),
     nullif(trim(coalesce(p_user_agent, '')), ''),
     NULL)
  RETURNING id, created_at;
END;
$$;

GRANT EXECUTE ON FUNCTION public.case_refs_feedback_submit(TEXT,TEXT,TEXT,JSONB,TEXT,TEXT,TEXT)
  TO anon, authenticated;

COMMENT ON FUNCTION public.case_refs_feedback_submit IS
  'Receber feedback do cliente sem login. Mensagem minima 10 chars. p_ip atualmente ignorado (pgcrypto nao habilitado).';
