# E2-S6 — Notificação quando processamento termina

**Epic:** EPIC-02 — Curadoria Power Tools
**Status:** Ready
**Prioridade:** P2
**Estimate:** 3h
**Owner:** Kaique
**Dependências:** Realtime Supabase OU polling agressivo

---

## User Story

Como **curador que acabou de adicionar refs**, quero ser **avisado quando o processamento terminou** (transcrição + capa + classificação prontas), pra **não ficar dando F5** pra ver se chegou.

## Contexto

Hoje: adiciona ref, fecha modal, fica olhando `/live` esperando aparecer. Refresh manual a cada 30s (já tem auto-refresh, mas curador não sabe). Frustrante.

## Critérios de Aceite

1. **Banner discreto no topo da página** após adicionar ref:
   - "⏳ Processando 3 referência(s)..."
   - Atualiza contador conforme as refs terminam
2. **Toast quando 1 ref específica termina**:
   - "✓ @perfil — Prova Social processado [Ver]"
   - Botão "Ver" abre o modal da ref
3. **Notificação do navegador** (opcional, com permissão):
   - Mesmo se a aba estiver em background
   - Se `Notification.permission === 'granted'`
4. **Listener via Supabase Realtime** OU polling do `/live` a cada 10s enquanto há pendentes
5. **Estado em localStorage**: lista de IDs pendentes persiste se recarregar página
6. **Limpa automaticamente** quando todas as pendentes processaram OU após 10 minutos

## Notas Técnicas

### Opção A — Supabase Realtime (preferida)

```js
const supa = supabase.createClient(URL, ANON);
const ch = supa
  .channel('refs-processed')
  .on('postgres_changes', {
    event: 'UPDATE',
    schema: 'public',
    table: 'referencias_conteudo',
    filter: 'status=eq.processed'
  }, payload => {
    const ref = payload.new;
    if (PENDING_IDS.has(ref.id)) {
      PENDING_IDS.delete(ref.id);
      notifyDone(ref);
      updateBanner();
    }
  })
  .subscribe();

function notifyDone(ref) {
  showToast(`✓ @${ref.perfil} — ${ref.tipo_estrategico || 'processado'}`);
  if (Notification.permission === 'granted') {
    new Notification('case-refs', {
      body: `@${ref.perfil} pronto!`,
      icon: ref.thumb_url || '/favicon.ico'
    });
  }
}
```

### Opção B — Polling agressivo (fallback)

```js
async function pollPending() {
  if (!PENDING_IDS.size) return;
  const ids = [...PENDING_IDS].join(',');
  const url = `${SUPABASE_URL}/rest/v1/v_referencias_publicas?id=in.(${ids})`;
  const r = await fetch(url, { headers: SUPA_HEADERS });
  const rows = await r.json();
  rows.forEach(ref => {
    if (ref.status === 'processed') {
      PENDING_IDS.delete(ref.id);
      notifyDone(ref);
    }
  });
  updateBanner();
  if (PENDING_IDS.size) setTimeout(pollPending, 10000);
}
```

### Estado persistente

```js
function addPending(id) {
  PENDING_IDS.add(id);
  localStorage.setItem('case-refs:pending', JSON.stringify([...PENDING_IDS]));
}

function loadPending() {
  const stored = JSON.parse(localStorage.getItem('case-refs:pending') || '[]');
  stored.forEach(id => PENDING_IDS.add(id));
}
```

## Coluna necessária

```sql
ALTER TABLE referencias_conteudo ADD COLUMN status TEXT DEFAULT 'pending';
-- valores: pending | processing | processed | failed
```

n8n atualiza `status` ao final do workflow:
- Apify scraper rodou → `processing`
- Transcrição + classificação prontas → `processed`
- Erro → `failed`

## Definition of Done

- [ ] Banner aparece após adicionar
- [ ] Toast por ref ao processar
- [ ] Notification do navegador (com permissão)
- [ ] Estado persiste em localStorage
- [ ] Limpa após 10 min
- [ ] Coluna `status` na tabela
- [ ] Realtime ou polling funcionando

## Edge cases

- **Ref nunca termina** (n8n falhou silenciosamente): após 10min, banner some + toast "Algumas refs ainda processando, recarregue depois"
- **Múltiplas abas abertas**: cada uma mostra próprio estado (sem broadcast)
- **Bloqueio de notification**: degrada gracefully pro toast
