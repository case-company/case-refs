// case-refs — bootstrap PWA + theme color.
//
// O gate de senha client-side foi REMOVIDO em 2026-05-13 (decisão Kaique:
// site é central pública pra cliente CASE consumir).
// Dados sensíveis continuam protegidos no Supabase: view publica usa
// whitelist explícita sem `notas` (campo interno do curador).
//
// Histórico: até a versão anterior este arquivo pedia senha (`case2026`).
// Se precisar reativar, ver git history.

if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('/sw.js').catch(() => {});
}

(function injectManifest() {
  if (document.querySelector('link[rel="manifest"]')) return;
  const link = document.createElement('link');
  link.rel = 'manifest';
  link.href = '/manifest.json';
  document.head.appendChild(link);
  const meta = document.createElement('meta');
  meta.name = 'theme-color';
  meta.content = '#554d33';
  document.head.appendChild(meta);
  const apple = document.createElement('link');
  apple.rel = 'apple-touch-icon';
  apple.href = '/icons/icon-192.png';
  document.head.appendChild(apple);
})();
