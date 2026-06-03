-- Chave natural única pro UPSERT do ingest:
--   publicações/fixados → shortcode (globalmente único na tabela)
--   destaques           → perfil|highlight_id (sem shortcode)
-- Com isso, re-cadastrar uma referência existente vira REPROCESSAMENTO:
-- re-scrape Apify + transcrição + guia IA preenchem só o que falta
-- (curadoria humana preservada via COALESCE no DO UPDATE do workflow n8n).
CREATE UNIQUE INDEX IF NOT EXISTS uniq_referencias_natkey
  ON agente.referencias_conteudo ((COALESCE(shortcode, perfil || '|' || highlight_id)))
  WHERE shortcode IS NOT NULL OR highlight_id IS NOT NULL;
