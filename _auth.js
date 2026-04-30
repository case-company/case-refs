// case-refs — auth gate (client-side simples)
// NÃO é segurança forte. É um gate pra deter acesso casual ao link público.
// Pra trocar a senha: gera hash com `await sha256("nova-senha")` no console e atualiza PASSWORD_HASH abaixo.
// Repo é público de propósito; dados sensíveis estão protegidos no Supabase via RLS.

(async function() {
  const COOKIE = 'case-refs-auth';
  const COOKIE_DAYS = 30;

  // SHA-256 hash de "case2026" — TROCAR antes de divulgar
  const PASSWORD_HASH = '92d53e97654ec612118e91304c85fed122163390bfbec8e1447c8b7f35b8827b';

  function getCookie(name) {
    const m = document.cookie.match(new RegExp('(?:^|; )' + name + '=([^;]*)'));
    return m ? m[1] : null;
  }

  function setCookie(name, value, days) {
    const exp = new Date(Date.now() + days * 86400000).toUTCString();
    document.cookie = `${name}=${value}; expires=${exp}; path=/; SameSite=Lax`;
  }

  async function sha256(text) {
    const buf = new TextEncoder().encode(text);
    const hash = await crypto.subtle.digest('SHA-256', buf);
    return Array.from(new Uint8Array(hash)).map(b => b.toString(16).padStart(2, '0')).join('');
  }

  if (getCookie(COOKIE) === 'ok') return;

  // Esconde tudo enquanto pede senha
  document.documentElement.style.visibility = 'hidden';

  const overlay = document.createElement('div');
  overlay.style.cssText = `
    position:fixed;inset:0;background:#faf9f7;z-index:99999;
    display:flex;flex-direction:column;align-items:center;justify-content:center;
    visibility:visible;font-family:system-ui,-apple-system,sans-serif;color:#2e2b25;
  `;
  overlay.innerHTML = `
    <div style="text-align:center;max-width:340px;padding:32px">
      <div style="font-family:Optima,'Times New Roman',serif;font-size:2rem;color:#554d33;margin-bottom:8px">case-refs</div>
      <div style="color:#807a67;font-size:.9rem;margin-bottom:24px">Banco de referências — acesso restrito</div>
      <input id="pwInput" type="password" placeholder="Senha" autofocus
        style="width:100%;padding:12px 16px;border:1px solid #e5e3dc;border-radius:8px;font-size:1rem;font-family:inherit;outline:none;margin-bottom:12px">
      <button id="pwBtn"
        style="width:100%;padding:12px;background:#554d33;color:white;border:none;border-radius:8px;font-size:1rem;font-weight:600;cursor:pointer;font-family:inherit">Entrar</button>
      <div id="pwErr" style="color:#c0392b;font-size:.85rem;margin-top:12px;min-height:1.2em"></div>
    </div>
  `;
  document.documentElement.appendChild(overlay);

  async function tryAuth() {
    const v = document.getElementById('pwInput').value;
    if (!v) return;
    const h = await sha256(v);
    if (h === PASSWORD_HASH) {
      setCookie(COOKIE, 'ok', COOKIE_DAYS);
      overlay.remove();
      document.documentElement.style.visibility = 'visible';
    } else {
      document.getElementById('pwErr').textContent = 'Senha incorreta';
      document.getElementById('pwInput').value = '';
      document.getElementById('pwInput').focus();
    }
  }

  document.getElementById('pwBtn').addEventListener('click', tryAuth);
  document.getElementById('pwInput').addEventListener('keydown', e => {
    if (e.key === 'Enter') tryAuth();
  });
})();
