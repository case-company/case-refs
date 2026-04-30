# E3-S3 — Vincular referência → mentorada

**Epic:** EPIC-03 — Intelligence & Integration
**Status:** Ready
**Prioridade:** P2
**Estimate:** 1.5 dia
**Owner:** Kaique
**Dependências:** Acesso à tabela de mentoradas (Spalla ou Supabase Case)

---

## User Story

Como **mentor**, quero **vincular cada referência a uma mentorada específica** que recebeu/usou aquela ref, pra **não repetir material** e **rastrear histórico** da relação ref ↔ mentorada.

## Contexto

Hoje: zero rastro. Mentor manda ref pra Mentorada A, depois 2 meses depois manda mesma ref pra ela de novo (esquece). Pior: time 2 manda mesma ref pra Mentorada B (desperdício).

## Critérios de Aceite

1. **Migration**: tabela `mentorada_referencias` (many-to-many)
2. **No modal de detalhes** da ref, seção **"Mentoradas vinculadas"**:
   - Lista atual com chips removíveis
   - Input "+ Vincular mentorada" com autocomplete da lista de mentoradas
   - Campo "Contexto" opcional ("usei pra mostrar exemplo de hook")
   - Campo "Data" automática (hoje)
3. **No card** da ref: badge "📌 N" indicando quantas mentoradas usaram
4. **Filtro por mentorada** na toolbar (multi-select)
5. **Página `/mentorada/:id`** opcional: lista todas as refs vinculadas
6. **Endpoint n8n** `/link-mentee` faz INSERT/DELETE na junction
7. **Aviso de duplicata**: ao vincular, se mentorada já tem aquela ref, pergunta "Já vinculada em DD/MM. Vincular novamente?"

## Notas Técnicas

### Migration

```sql
CREATE TABLE mentorada_referencias (
  id BIGSERIAL PRIMARY KEY,
  ref_id BIGINT REFERENCES referencias_conteudo(id),
  mentorada_id BIGINT NOT NULL,
  contexto TEXT,
  vinculado_em TIMESTAMPTZ DEFAULT now(),
  vinculado_por TEXT,
  UNIQUE(ref_id, mentorada_id, vinculado_em)
);
CREATE INDEX idx_mentref_ref ON mentorada_referencias(ref_id);
CREATE INDEX idx_mentref_ment ON mentorada_referencias(mentorada_id);

-- View pra contar vínculos
CREATE OR REPLACE VIEW v_referencias_publicas AS
SELECT r.*, 
  (SELECT COUNT(*) FROM mentorada_referencias mr WHERE mr.ref_id = r.id) as vinculos_count,
  (SELECT array_agg(mentorada_id) FROM mentorada_referencias mr WHERE mr.ref_id = r.id) as mentoradas_vinculadas
FROM referencias_conteudo r
WHERE deleted_at IS NULL;
```

### Endpoint n8n

```
POST /webhook/case-refs-link-mentee
Body: { op: 'link', ref_id, mentorada_id, contexto?: string }
Body: { op: 'unlink', ref_id, mentorada_id }
```

### Front

```js
async function linkMentee(refId, menteeId, contexto = '') {
  const ref = DATA.find(r => r.id === refId);
  // Check duplicata
  if ((ref.mentoradas_vinculadas || []).includes(menteeId)) {
    if (!confirm('Já vinculada antes. Vincular novamente?')) return;
  }
  await fetch(WEBHOOK_LINK, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ op: 'link', ref_id: refId, mentorada_id: menteeId, contexto })
  });
  showToast('Vinculada ✓');
  refreshRefView(refId);
}
```

### Lista de mentoradas

- Source: tabela `mentees` ou view `v_mentoradas_ativas` no Supabase Case
- Cache local (1h TTL) pra autocomplete rápido
- Format: `{ id, nome, foto, cohort }`

## Definition of Done

- [ ] Migration aplicada (tabela + índices + view atualizada)
- [ ] Seção "Mentoradas vinculadas" no modal funciona
- [ ] Vincular/desvincular via endpoint
- [ ] Badge "📌 N" no card
- [ ] Filtro por mentorada na toolbar
- [ ] Aviso de duplicata
- [ ] Lista de mentoradas carrega com autocomplete

## Variantes futuras

- Histórico temporal: "Mentorada X recebeu refs em Y datas"
- Export do "kit de refs" da mentorada (junta com E3-S2 modo apresentação)
- Sugestão automática: "Mentorada A é parecida com B, B usou refs C/D, sugerir C/D pra A"

## Não cobre

- Permissão por mentor (todos veem todos os vínculos)
- Edição em massa (selecionar 10 refs e vincular todas a 1 mentorada)
