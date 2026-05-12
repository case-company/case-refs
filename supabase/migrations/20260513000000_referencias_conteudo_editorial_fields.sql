-- E02-S1: campos editoriais obrigatorios na promocao (ADR-0002).
-- Adiciona quando_usar/por_que_funciona/como_adaptar/objetivo na tabela
-- agente.agente.referencias_conteudo. Itens legados ja promovidos NAO sao
-- validados pela constraint (NOT VALID) — somente promocoes a partir
-- de agora exigem os 3 campos com >= 20 caracteres.
--
-- Tabela referenciada no schema atual e `agente.referencias_conteudo` (sem schema
-- explicito em algumas migrations anteriores). Aqui mantemos o mesmo padrao.

ALTER TABLE agente.referencias_conteudo
  ADD COLUMN IF NOT EXISTS quando_usar       TEXT,
  ADD COLUMN IF NOT EXISTS por_que_funciona  TEXT,
  ADD COLUMN IF NOT EXISTS como_adaptar      TEXT,
  ADD COLUMN IF NOT EXISTS objetivo          TEXT;

-- Constraint: linha promovida exige os 3 campos com >= 20 chars.
-- NOT VALID = nao aplica retroativamente aos itens legados ja promovidos.
-- A constraint passa a valer para todo INSERT/UPDATE a partir desta migration.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'chk_promoted_requires_editorial_fields'
      AND conrelid = 'agente.referencias_conteudo'::regclass
  ) THEN
    ALTER TABLE agente.referencias_conteudo
      ADD CONSTRAINT chk_promoted_requires_editorial_fields
      CHECK (
        promoted_at IS NULL
        OR (
          char_length(coalesce(quando_usar, '')) >= 20
          AND char_length(coalesce(por_que_funciona, '')) >= 20
          AND char_length(coalesce(como_adaptar, '')) >= 20
        )
      ) NOT VALID;
  END IF;
END $$;

-- objetivo aceita valores livres por enquanto — hint dos canonicos no COMMENT.
COMMENT ON COLUMN agente.referencias_conteudo.objetivo IS
  'Atrair | Identificar | Desejo | Confiar | Vender (separado de etapa_funil)';

COMMENT ON COLUMN agente.referencias_conteudo.quando_usar IS
  'Editorial: em que momento esse conteudo serve. Min 20 chars quando promovido.';
COMMENT ON COLUMN agente.referencias_conteudo.por_que_funciona IS
  'Editorial: por que esse conteudo funciona. Min 20 chars quando promovido.';
COMMENT ON COLUMN agente.referencias_conteudo.como_adaptar IS
  'Editorial: como adaptar para outro contexto. Min 20 chars quando promovido.';

-- Indices
CREATE INDEX IF NOT EXISTS idx_refs_objetivo
  ON agente.referencias_conteudo (objetivo)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_refs_etapa_promoted
  ON agente.referencias_conteudo (etapa_funil, promoted_at)
  WHERE deleted_at IS NULL AND promoted_at IS NOT NULL;
