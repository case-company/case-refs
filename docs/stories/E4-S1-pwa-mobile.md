# E4-S1 — PWA mobile instalável

**Epic:** EPIC-04 — AI & Mobile
**Status:** Discovery
**Prioridade:** P3
**Estimate:** 1 semana
**Owner:** Kaique
**Dependências:** Service Worker, Web App Manifest, ícones

---

## User Story

Como **curador em reunião** (com mentorada, em viagem, no celular), quero **abrir case-refs como app no celular** e cadastrar uma referência rapidamente, pra **não precisar de notebook** ou **screenshot+desktop depois**.

## Contexto

Hoje: `case-refs.vercel.app` no Safari mobile funciona, mas:
- Não abre em fullscreen
- Sem ícone na home screen (precisa decorar URL)
- Sem cache offline
- Modal de adicionar é pequeno em mobile

Queremos: PWA real, instalável, com UX otimizada pra cadastro rápido durante reunião.

## Critérios de Aceite

1. **Web App Manifest** (`manifest.json`):
   - Nome: "case-refs"
   - Ícones: 192x192, 512x512, maskable
   - `display: standalone`
   - `theme_color`, `background_color`
   - Shortcuts: "Adicionar referência" / "Ver últimas"
2. **Service Worker** com cache strategy:
   - HTML/CSS/JS: stale-while-revalidate
   - Thumbs: cache-first
   - API calls: network-first
3. **Install prompt** com banner customizado ("Instalar app pra cadastro rápido")
4. **Offline mode**:
   - Última lista de refs cached
   - Adicionar offline → fila local → envia quando online (background sync)
5. **Mobile UX**:
   - Modal full-screen em mobile
   - Bottom-sheet style ao invés de centralizado
   - Botões 44px+ touch target
   - "Compartilhar" do iOS/Android → abre direto modal "Adicionar" com URL pré-preenchida
6. **Web Share Target API**: aparece na lista de "Compartilhar" do Instagram

## Notas Técnicas

### manifest.json

```json
{
  "name": "case-refs",
  "short_name": "case-refs",
  "description": "Banco de referências Case",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#faf9f7",
  "theme_color": "#554d33",
  "icons": [
    { "src": "/icons/192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "/icons/512.png", "sizes": "512x512", "type": "image/png" },
    { "src": "/icons/maskable-512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable" }
  ],
  "shortcuts": [
    { "name": "Adicionar referência", "url": "/trilhas#open-form", "icons": [{"src":"/icons/add-96.png","sizes":"96x96"}] },
    { "name": "Últimas adicionadas", "url": "/live?periodo=24h" }
  ],
  "share_target": {
    "action": "/trilhas",
    "method": "GET",
    "params": { "url": "shared_url" }
  }
}
```

### Service Worker

```js
// sw.js
const CACHE = 'case-refs-v1';
const STATIC = ['/', '/trilhas', '/posts', '/live', '/manifest.json'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(STATIC)));
});

self.addEventListener('fetch', e => {
  const url = new URL(e.request.url);
  if (url.pathname.startsWith('/thumbs/')) {
    e.respondWith(cacheFirst(e.request));
  } else if (url.hostname.includes('supabase.co')) {
    e.respondWith(networkFirst(e.request));
  } else {
    e.respondWith(staleWhileRevalidate(e.request));
  }
});

self.addEventListener('sync', e => {
  if (e.tag === 'flush-pending-refs') {
    e.waitUntil(flushPendingRefs());
  }
});
```

### Background sync

```js
// No front quando offline
async function addRefOffline(payload) {
  const queue = JSON.parse(localStorage.getItem('case-refs:offline-queue') || '[]');
  queue.push({ ...payload, queued_at: Date.now() });
  localStorage.setItem('case-refs:offline-queue', JSON.stringify(queue));
  if ('serviceWorker' in navigator && 'sync' in self.registration) {
    await navigator.serviceWorker.ready;
    await self.registration.sync.register('flush-pending-refs');
  }
  showToast('Salvo offline, vai enviar quando voltar online');
}
```

### Mobile UX patches

```css
@media (max-width: 768px) {
  .modal-form {
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
    border-radius: 16px 16px 0 0;
    max-height: 90vh;
    transform: translateY(100%);
    transition: transform .3s;
  }
  .modal-bg.open .modal-form { transform: translateY(0); }
  .btn { min-height: 44px; }
  .input, .select { font-size: 16px; /* evita zoom iOS */ }
}
```

## Definition of Done

- [ ] manifest.json válido (testar em https://manifest-validator.appspot.com/)
- [ ] Service Worker registrado e funcionando
- [ ] Install prompt aparece após critério (ex: 2 visitas)
- [ ] Offline: última lista funciona
- [ ] Background sync envia refs queued
- [ ] Mobile UX: modal bottom-sheet, touch targets ok
- [ ] Web Share Target funcionando (compartilhar do IG abre app)
- [ ] Lighthouse PWA score ≥ 90
- [ ] Testado em iOS Safari + Chrome Android

## Edge cases

- **Cache estourar quota**: Service Worker limpa thumbs > 30 dias
- **Service Worker desatualizado**: skipWaiting + claim + reload notification
- **Background sync não suportado** (Safari iOS): fallback pra retry no próximo open

## Não cobre

- App nativo iOS/Android (PWA cobre 95%)
- Push notifications (futuro)
- Acesso à câmera pra OCR de print de IG (futuro avançado)
