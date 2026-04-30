// case-refs — Service Worker
const CACHE_VERSION = 'v1';
const CACHE_NAME = `case-refs-${CACHE_VERSION}`;
const STATIC_ASSETS = [
  '/',
  '/index.html',
  '/trilhas',
  '/posts',
  '/live',
  '/dashboard',
  '/_auth.js',
  '/manifest.json'
];

self.addEventListener('install', (e) => {
  e.waitUntil(
    caches.open(CACHE_NAME).then(c => c.addAll(STATIC_ASSETS).catch(() => null))
  );
  self.skipWaiting();
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys().then(keys => Promise.all(
      keys.filter(k => k.startsWith('case-refs-') && k !== CACHE_NAME).map(k => caches.delete(k))
    ))
  );
  self.clients.claim();
});

self.addEventListener('fetch', (e) => {
  const url = new URL(e.request.url);

  // Não interceptar Supabase / webhooks externos
  if (url.hostname.includes('supabase.co') || url.hostname.includes('feynmanproject.com')) return;
  if (e.request.method !== 'GET') return;

  // Thumbs: cache-first (raramente mudam)
  if (url.pathname.startsWith('/thumbs/')) {
    e.respondWith(
      caches.open(CACHE_NAME).then(c =>
        c.match(e.request).then(cached => cached || fetch(e.request).then(r => {
          if (r.ok) c.put(e.request, r.clone());
          return r;
        }).catch(() => cached))
      )
    );
    return;
  }

  // HTML/JS/CSS: stale-while-revalidate
  e.respondWith(
    caches.open(CACHE_NAME).then(c =>
      c.match(e.request).then(cached => {
        const network = fetch(e.request).then(r => {
          if (r.ok) c.put(e.request, r.clone());
          return r;
        }).catch(() => cached);
        return cached || network;
      })
    )
  );
});
