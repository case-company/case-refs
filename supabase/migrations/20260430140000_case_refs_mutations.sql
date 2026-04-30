-- case-refs: soft delete + tags pra suportar E1-S3, E1-S4, E2-S4

ALTER TABLE referencias_conteudo ADD COLUMN IF NOT EXISTS deleted_at timestamptz;
ALTER TABLE referencias_conteudo ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}';

CREATE INDEX IF NOT EXISTS idx_refs_tags ON referencias_conteudo USING gin(tags);
CREATE INDEX IF NOT EXISTS idx_refs_deleted_at ON referencias_conteudo (deleted_at) WHERE deleted_at IS NULL;

-- View pública atualizada: filtra deletadas, expõe tags
CREATE OR REPLACE VIEW v_referencias_publicas AS
  SELECT * FROM referencias_conteudo WHERE deleted_at IS NULL;
