// case-refs — Service Worker
// v2 (2026-05-13): HTML/JS/CSS agora é network-first com fallback de cache.
// Resolve bug de UI antiga aparecer após deploy.

const CACHE_VERSION = 'v2';
const CACHE_NAME = `case-refs-${CACHE_VERSION}`;
const STATIC_ASSETS = [
  '/',
  '/index.html',
  '/trilhas',
  '/posts',
  '/live',
  '/dashboard',
  '/como-usar',
  '/_auth.js',
  '/_decida.js',
  '/_tour.js',
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

  // HTML/JS/CSS: network-first (sempre busca rede; cache só como fallback offline)
  e.respondWith(
    fetch(e.request).then(r => {
      if (r.ok) {
        const copy = r.clone();
        caches.open(CACHE_NAME).then(c => c.put(e.request, copy));
      }
      return r;
    }).catch(() => caches.open(CACHE_NAME).then(c => c.match(e.request)))
  );
});
