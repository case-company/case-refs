-- Promoção de itens do /live pro /trilhas (banco curado).
-- Item entra via webhook -> aparece em /live com badge "Pendente curadoria".
-- Curador clica "Promover" -> some do /live, aparece em /trilhas.

ALTER TABLE agente.referencias_conteudo
  ADD COLUMN IF NOT EXISTS promoted_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_refs_promoted_at
  ON agente.referencias_conteudo (promoted_at)
  WHERE deleted_at IS NULL AND promoted_at IS NOT NULL;

-- View pública continua expondo TUDO (live filtra IS NULL, trilhas filtra IS NOT NULL)
CREATE OR REPLACE VIEW public.v_referencias_publicas AS
  SELECT * FROM agente.referencias_conteudo WHERE deleted_at IS NULL;

-- RPC: promote
CREATE OR REPLACE FUNCTION public.case_refs_promote(p_id INT)
RETURNS TABLE(id INT, promoted_at TIMESTAMPTZ)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, agente
AS $$
BEGIN
  RETURN QUERY
  UPDATE agente.referencias_conteudo
     SET promoted_at = NOW()
   WHERE referencias_conteudo.id = p_id
     AND deleted_at IS NULL
  RETURNING referencias_conteudo.id, referencias_conteudo.promoted_at;
END;
$$;

-- RPC: unpromote (volta pro /live caso curador erre)
CREATE OR REPLACE FUNCTION public.case_refs_unpromote(p_id INT)
RETURNS TABLE(id INT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, agente
AS $$
BEGIN
  RETURN QUERY
  UPDATE agente.referencias_conteudo
     SET promoted_at = NULL
   WHERE referencias_conteudo.id = p_id
  RETURNING referencias_conteudo.id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.case_refs_promote(INT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.case_refs_unpromote(INT) TO anon, authenticated;
