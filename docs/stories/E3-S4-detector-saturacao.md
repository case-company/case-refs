# E3-S4 — Detector de saturação

**Epic:** EPIC-03 — Intelligence & Integration
**Status:** Ready
**Prioridade:** P2
**Estimate:** 1 dia
**Owner:** Kaique
**Dependências:** E3-S1 (dashboard de cobertura)

---

## User Story

Como **dona da Case (Queila)**, quero **alertas automáticos** quando alguma trilha/etapa do funil tem cobertura abaixo do esperado, pra **agir antes do gap virar problema** em dossiês ou apresentações.

## Contexto

E3-S1 mostra heatmap visual. Mas Queila não vai abrir dashboard todo dia. Queremos alerta proativo: "Cobertura fraca em Mentoria/Confiança/Prova Social — só 2 refs nos últimos 90 dias".

## Critérios de Aceite

1. **Definição de threshold por categoria**:
   - **Crítico**: ≤2 refs
   - **Atenção**: 3-5 refs
   - **Saudável**: 6+ refs
2. **Cron job semanal** (segunda 9h) calcula cobertura
3. **Notifica** via:
   - Email pra Queila + Gobbi (configurável)
   - Slack/WhatsApp opcional (futuro)
   - Banner no `/dashboard` quando há crítico
4. **Conteúdo do alerta**:
   - "🚨 3 categorias críticas:"
   - Lista: trilha / etapa / tipo / count atual / link pro filtro
   - "📊 Veja dashboard completo"
5. **Snooze**: botão "OK, vou cuidar" silencia alerta por 7 dias
6. **Histórico**: tabela `saturation_alerts` persiste alertas pra evolução temporal

## Notas Técnicas

### View Supabase

```sql
CREATE OR REPLACE VIEW v_saturacao AS
WITH categorias AS (
  SELECT DISTINCT trilha, etapa_funil, tipo_estrategico
  FROM referencias_conteudo
  WHERE deleted_at IS NULL
)
SELECT
  c.trilha, c.etapa_funil, c.tipo_estrategico,
  COUNT(r.id) as total_refs,
  COUNT(r.id) FILTER (WHERE r.created_at > now() - interval '90 days') as recentes_90d,
  CASE
    WHEN COUNT(r.id) FILTER (WHERE r.created_at > now() - interval '90 days') <= 2 THEN 'critico'
    WHEN COUNT(r.id) FILTER (WHERE r.created_at > now() - interval '90 days') <= 5 THEN 'atencao'
    ELSE 'saudavel'
  END as nivel
FROM categorias c
LEFT JOIN referencias_conteudo r 
  ON r.trilha = c.trilha 
  AND r.etapa_funil = c.etapa_funil 
  AND r.tipo_estrategico = c.tipo_estrategico
  AND r.deleted_at IS NULL
GROUP BY c.trilha, c.etapa_funil, c.tipo_estrategico
ORDER BY total_refs ASC;
```

### Cron n8n (semanal)

```
Trigger: Cron - Toda segunda 09:00
Step 1: Query Supabase v_saturacao WHERE nivel='critico'
Step 2: If count > 0:
  - Format email
  - Send via Resend/Mailgun pra Queila + Gobbi
  - INSERT em saturation_alerts
Step 3: Optionally Slack webhook
```

### Tabela de histórico

```sql
CREATE TABLE saturation_alerts (
  id BIGSERIAL PRIMARY KEY,
  alerted_at TIMESTAMPTZ DEFAULT now(),
  niveis_criticos JSONB, -- array de {trilha, etapa, tipo, count}
  notificados TEXT[], -- emails que receberam
  snoozed_until TIMESTAMPTZ
);
```

### Banner no dashboard

```js
async function checkSaturation() {
  const r = await fetch(`${SUPABASE_URL}/rest/v1/v_saturacao?nivel=eq.critico`);
  const criticos = await r.json();
  if (!criticos.length) return;
  
  const banner = document.getElementById('saturationBanner');
  banner.innerHTML = `
    <strong>🚨 ${criticos.length} categoria(s) com cobertura crítica</strong>
    <ul>${criticos.map(c => `<li>${c.trilha} / ${c.etapa_funil} / ${c.tipo_estrategico}: ${c.recentes_90d} refs</li>`).join('')}</ul>
    <button onclick="snoozeAlert()">OK, vou cuidar (silenciar 7d)</button>
  `;
  banner.style.display = 'block';
}
```

## Definition of Done

- [ ] View `v_saturacao` criada
- [ ] Cron n8n agendado e testado
- [ ] Email enviado em sucesso (template formatado)
- [ ] Banner no `/dashboard` aparece quando há crítico
- [ ] Snooze persiste 7 dias
- [ ] Tabela de histórico recebe alertas

## Edge cases

- **Categoria sem refs nenhuma** (count=0): nivel='critico' automaticamente
- **Nova categoria sendo introduzida**: aparece como crítica até atingir threshold
- **Snooze ativo + novo crítico aparece**: ainda alerta (snooze é por categoria, não global)

## Não cobre

- Configuração de threshold por usuário (uses default global)
- Sugestão automática de quem postar (fica em E4 chat-to-search)
