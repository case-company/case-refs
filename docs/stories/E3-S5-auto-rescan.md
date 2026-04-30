# E3-S5 — Auto-rescan periódico de perfis

**Epic:** EPIC-03 — Intelligence & Integration
**Status:** Ready
**Prioridade:** P3
**Estimate:** 1 dia
**Owner:** Kaique
**Dependências:** Cron n8n + Apify rate limit budget

---

## User Story

Como **curador**, quero que **perfis cadastrados sejam re-checkados automaticamente** toda semana pra capturar **posts fixados novos** e **destaques novos** que foram adicionados, pra **não perder atualização** sem ter que re-cadastrar manualmente.

## Contexto

Hoje: cadastra perfil → scraper roda 1x → 3 posts fixados ficam salvos. Se o perfil trocar os fixados depois (comum em IG profissional), a Case nunca sabe.

## Critérios de Aceite

1. **Cron job semanal** (domingo 22h, baixo tráfego) lista perfis cadastrados como `type=perfil` e cujo último scan foi >7 dias atrás
2. **Re-roda scraper Apify** pra cada perfil (em batch, throttled)
3. **Diff inteligente**:
   - Posts fixados novos → INSERT
   - Posts fixados que sumiram → marca `unpinned_at` (não deleta)
   - Posts fixados que mudaram de posição → UPDATE
   - Destaques novos → INSERT
4. **Coluna `last_scanned_at`** em `referencias_conteudo` (perfis pais)
5. **Notificação** pra curadores quando há mudanças significativas (ex: perfil X tem 2 posts fixados novos)
6. **Throttle**: max 30 perfis por execução (caso bata em rate limit Apify, retoma na próxima)
7. **Logs estruturados**: tabela `scan_runs` com timestamp, perfis processados, items adicionados/removidos

## Notas Técnicas

### Migration

```sql
ALTER TABLE referencias_conteudo ADD COLUMN last_scanned_at TIMESTAMPTZ;
ALTER TABLE referencias_conteudo ADD COLUMN unpinned_at TIMESTAMPTZ;

CREATE TABLE scan_runs (
  id BIGSERIAL PRIMARY KEY,
  ran_at TIMESTAMPTZ DEFAULT now(),
  perfis_processados INTEGER,
  refs_adicionadas INTEGER,
  refs_removidas INTEGER,
  duracao_segundos INTEGER,
  erros JSONB
);
```

### Cron n8n workflow

```
Trigger: Cron - Domingo 22:00
Step 1: Query Supabase
  SELECT DISTINCT perfil, trilha
  FROM referencias_conteudo
  WHERE type = 'perfil'
    AND (last_scanned_at IS NULL OR last_scanned_at < now() - interval '7 days')
  LIMIT 30
Step 2: Loop por perfil:
  - Run Apify Actor (instagram-profile-scraper)
  - Diff com posts atuais no banco
  - INSERT novos
  - UPDATE last_scanned_at
  - Sleep 30s (rate limit)
Step 3: Compile summary
Step 4: INSERT em scan_runs
Step 5: If há refs novas, notify (banner ou email)
```

### Diff logic

```js
function diffPinned(current, fresh) {
  const adds = [];
  const removes = [];
  const changes = [];
  
  // Novos
  fresh.forEach(f => {
    if (!current.find(c => c.shortcode === f.shortcode)) adds.push(f);
  });
  
  // Sumiram (unpin)
  current.forEach(c => {
    if (!fresh.find(f => f.shortcode === c.shortcode)) removes.push(c);
  });
  
  // Mudaram posição
  fresh.forEach(f => {
    const c = current.find(x => x.shortcode === f.shortcode);
    if (c && c.posicao !== f.posicao) changes.push({ ...f, oldPos: c.posicao });
  });
  
  return { adds, removes, changes };
}
```

## Definition of Done

- [ ] Migration aplicada
- [ ] Cron n8n criado e ativo
- [ ] Diff lógica testada (com perfil teste)
- [ ] Tabela `scan_runs` recebe execuções
- [ ] Notificação dispara quando há mudanças
- [ ] Throttle respeita limite Apify
- [ ] README documenta o comportamento

## Custo estimado

- Apify: ~30 perfis/semana × $0.0008/perfil = **~$0.10/mês**
- n8n execution: incluído no plano existente
- Storage Supabase: desprezível

## Edge cases

- **Perfil deletado/privado**: marca `last_scanned_at` mas registra erro em `scan_runs.erros`
- **Rate limit hit**: pausa 5min, retoma. Se persistir, aborta + email "Apify rate limit excedido"
- **Conflito**: post manual adicionado entre scans → respeita o manual, não sobrescreve

## Não cobre

- Re-transcrição automática (transcrição não muda do post original)
- Detecção de mudança no caption/likes (só estrutural: posts existem ou não)
- Configuração de frequência por perfil (default 7 dias pra todos)
