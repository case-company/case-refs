-- RPC usada pelo op store_thumb da Edge Function case-refs-mutate.
-- Só grava a URL pública do Storage — download/upload acontecem na function.
CREATE OR REPLACE FUNCTION public.case_refs_set_thumb_storage(p_id BIGINT, p_url TEXT)
RETURNS TABLE(out_id BIGINT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, agente
AS $$
BEGIN
  RETURN QUERY
  UPDATE agente.referencias_conteudo r
     SET thumb_storage_url = p_url
   WHERE r.id = p_id
     AND r.deleted_at IS NULL
  RETURNING r.id;
END;
$$;

-- Só service_role (Edge Function) — anon não tem por que escrever thumb.
REVOKE EXECUTE ON FUNCTION public.case_refs_set_thumb_storage(BIGINT, TEXT) FROM anon, authenticated, PUBLIC;
GRANT EXECUTE ON FUNCTION public.case_refs_set_thumb_storage(BIGINT, TEXT) TO service_role;
