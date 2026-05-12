// case-refs — utilitarios compartilhados das paginas de agente editorial.
// Inclua via <script src="/_agente-shared.js"></script> APOS o body
// (precisa que SUPABASE_URL e SUPABASE_ANON estejam definidos antes).

(function () {
  const SUPABASE_URL = "https://knusqfbvhsqworzyhvip.supabase.co";
  const SUPABASE_ANON = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtudXNxZmJ2aHNxd29yenlodmlwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ4NTg3MjcsImV4cCI6MjA3MDQzNDcyN30.f-m7TlmCoccBpUxLZhA4P5kr2lWBGtRIv6inzInAKCo";

  const headers = {
    apikey: SUPABASE_ANON,
    Authorization: "Bearer " + SUPABASE_ANON,
    "Content-Type": "application/json",
  };

  // Chama RPC do schema public via PostgREST.
  async function callRpc(fnName, args) {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/rpc/${fnName}`, {
      method: "POST",
      headers,
      body: JSON.stringify(args),
    });
    let body = null;
    try { body = await res.json(); } catch (_) {}
    if (!res.ok) {
      const msg = (body && (body.message || body.error)) || `HTTP ${res.status}`;
      throw new Error(msg);
    }
    return body;
  }

  // GET de uma view public via PostgREST com filtros opcionais.
  async function fetchView(viewName, query = "") {
    const url = `${SUPABASE_URL}/rest/v1/${viewName}${query ? "?" + query : ""}`;
    const res = await fetch(url, { headers: { apikey: SUPABASE_ANON, Authorization: "Bearer " + SUPABASE_ANON } });
    if (!res.ok) throw new Error("HTTP " + res.status);
    return res.json();
  }

  // Parser tolerante: aceita JSON ou retorna o valor cru se nao for parseavel.
  function parseJsonField(text, fallback) {
    text = (text || "").trim();
    if (!text) return fallback === undefined ? null : fallback;
    try { return JSON.parse(text); } catch (_) { return text; }
  }

  // Toast minimo.
  function toast(msg, kind = "ok") {
    let el = document.getElementById("toast-anchor");
    if (!el) {
      el = document.createElement("div");
      el.id = "toast-anchor";
      el.style.cssText = "position:fixed;bottom:32px;left:50%;transform:translateX(-50%);background:#554d33;color:white;padding:12px 20px;border-radius:99px;box-shadow:0 8px 20px rgba(0,0,0,.2);font-size:.85rem;z-index:9999;opacity:0;transition:opacity .25s;pointer-events:none;max-width:90vw";
      document.body.appendChild(el);
    }
    if (kind === "err") el.style.background = "#c0392b";
    else el.style.background = "#554d33";
    el.textContent = msg;
    el.style.opacity = "1";
    setTimeout(() => { el.style.opacity = "0"; }, 3500);
  }

  function escapeHtml(s) {
    return String(s == null ? "" : s).replace(/[&<>"']/g, c => ({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));
  }

  function fmtDate(iso) {
    if (!iso) return "—";
    try { return new Date(iso).toLocaleString("pt-BR", { dateStyle:"short", timeStyle:"short" }); }
    catch(_) { return iso; }
  }

  window.AGENTE = { callRpc, fetchView, parseJsonField, toast, escapeHtml, fmtDate };
})();
