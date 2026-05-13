// case-refs — widget de coleta de feedback do cliente (E09-S1).
//
// Atende a subtarefa do handoff Felipe Gobbi: captar feedback de uso real
// para "resumir feedback / organizar pontos de melhoria / reescrever
// trechos confusos / propor ajustes de fluxo e linguagem".
//
// Renderiza um botao flutuante no canto inferior direito. Clique abre
// modal com 3 campos: categoria (chips), mensagem (textarea), email
// (opcional). Submit chama RPC publica case_refs_feedback_submit.
//
// Inclua via <script src="/_feedback.js" defer></script> nas paginas
// que devem coletar feedback (trilhas, como-usar, posts, live, index).

(function () {
  const SUPABASE_URL = "https://knusqfbvhsqworzyhvip.supabase.co";
  const SUPABASE_ANON = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtudXNxZmJ2aHNxd29yenlodmlwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ4NTg3MjcsImV4cCI6MjA3MDQzNDcyN30.f-m7TlmCoccBpUxLZhA4P5kr2lWBGtRIv6inzInAKCo";

  const CATEGORIAS = [
    { value: "confuso",  label: "Confuso",   hint: "Algo não ficou claro" },
    { value: "sugestao", label: "Sugestão",  hint: "Tenho uma ideia de melhoria" },
    { value: "erro",     label: "Erro",      hint: "Encontrei um bug ou problema" },
    { value: "elogio",   label: "Elogio",    hint: "Funcionou bem, queria contar" },
  ];

  function injectStyles() {
    if (document.getElementById("fb-styles")) return;
    const s = document.createElement("style");
    s.id = "fb-styles";
    s.textContent = `
      #fb-btn { position: fixed; bottom: 24px; right: 24px; z-index: 9000;
        background: var(--accent-500, #d4703a); color: white; border: none;
        padding: 12px 18px; border-radius: 99px; font-family: var(--font-ui, system-ui), sans-serif;
        font-weight: 600; font-size: .85rem; cursor: pointer;
        box-shadow: 0 6px 20px rgba(85,77,51,.25); transition: transform .2s, box-shadow .2s; }
      #fb-btn:hover { transform: translateY(-2px); box-shadow: 0 10px 28px rgba(85,77,51,.35); }
      #fb-overlay { position: fixed; inset: 0; background: rgba(46,43,37,.6); z-index: 9001;
        display: none; align-items: center; justify-content: center; padding: 16px; }
      #fb-overlay.open { display: flex; }
      #fb-modal { background: white; border-radius: 16px; max-width: 480px; width: 100%;
        max-height: 90vh; overflow-y: auto; padding: 24px; box-shadow: 0 24px 60px rgba(0,0,0,.3);
        font-family: var(--font-ui, system-ui), sans-serif; color: var(--neutral-800, #2e2b25); }
      #fb-modal h3 { font-family: var(--font-display, "Optima", serif); margin: 0 0 6px;
        font-size: 1.35rem; color: var(--brand-700, #554d33); }
      #fb-modal p.sub { margin: 0 0 16px; color: var(--cream-700, #807a67); font-size: .9rem; }
      #fb-modal label { display: block; font-size: .78rem; font-weight: 600;
        color: var(--brand-700, #554d33); margin: 12px 0 6px; }
      #fb-cats { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
      .fb-cat { background: white; border: 1px solid var(--neutral-200, #e5e3dc); border-radius: 8px;
        padding: 10px 12px; cursor: pointer; font-size: .85rem; text-align: left;
        font-family: inherit; color: var(--neutral-800, #2e2b25); transition: all .15s; }
      .fb-cat .lbl { font-weight: 600; }
      .fb-cat .hint { display: block; font-size: .72rem; color: var(--cream-700, #807a67); margin-top: 2px; }
      .fb-cat:hover { border-color: var(--brand-700, #554d33); }
      .fb-cat.active { border-color: var(--accent-500, #d4703a); background: #fef9f3;
        box-shadow: 0 0 0 2px rgba(212,112,58,.2); }
      #fb-msg, #fb-email { width: 100%; padding: 10px 12px; border: 1px solid var(--neutral-200, #e5e3dc);
        border-radius: 8px; font-family: inherit; font-size: .9rem; color: var(--neutral-800, #2e2b25); }
      #fb-msg { min-height: 100px; resize: vertical; line-height: 1.45; }
      #fb-msg:focus, #fb-email:focus { outline: 2px solid var(--accent-500, #d4703a); outline-offset: 1px; }
      #fb-status { font-size: .8rem; min-height: 1.2em; margin-top: 8px; color: var(--cream-700, #807a67); }
      #fb-status.error { color: #c0392b; }
      #fb-status.success { color: #4a8c5c; }
      #fb-actions { display: flex; justify-content: flex-end; gap: 8px; margin-top: 16px; }
      #fb-cancel, #fb-submit { font-family: inherit; cursor: pointer; padding: 9px 18px;
        border-radius: 8px; font-weight: 600; font-size: .85rem; border: 1px solid var(--neutral-200, #e5e3dc); }
      #fb-cancel { background: white; color: var(--cream-700, #807a67); }
      #fb-submit { background: var(--accent-500, #d4703a); color: white; border-color: var(--accent-500, #d4703a); }
      #fb-submit:hover { background: var(--accent-700, #964627); }
      #fb-submit:disabled { opacity: .5; cursor: not-allowed; }
    `;
    document.head.appendChild(s);
  }

  function buildModal() {
    const overlay = document.createElement("div");
    overlay.id = "fb-overlay";
    overlay.addEventListener("click", e => { if (e.target.id === "fb-overlay") close(); });

    const catsHtml = CATEGORIAS.map(c =>
      `<button type="button" class="fb-cat" data-cat="${c.value}"><span class="lbl">${c.label}</span><span class="hint">${c.hint}</span></button>`
    ).join("");

    overlay.innerHTML = `
      <div id="fb-modal" role="dialog" aria-modal="true" aria-labelledby="fb-title">
        <h3 id="fb-title">Envie um feedback</h3>
        <p class="sub">A gente lê tudo. Não precisa ser longo — fala o que sentiu.</p>

        <label>Categoria</label>
        <div id="fb-cats">${catsHtml}</div>

        <label for="fb-msg">Mensagem <span style="font-weight:400;color:var(--cream-700,#807a67);font-size:.72rem">(mínimo 10 caracteres)</span></label>
        <textarea id="fb-msg" placeholder="Conta aqui o que aconteceu — confuso, ideia, bug, ou só elogio..."></textarea>

        <label for="fb-email">Email <span style="font-weight:400;color:var(--cream-700,#807a67);font-size:.72rem">(opcional, só se quiser resposta)</span></label>
        <input id="fb-email" type="email" placeholder="seu@email.com">

        <div id="fb-status"></div>
        <div id="fb-actions">
          <button id="fb-cancel" type="button">Cancelar</button>
          <button id="fb-submit" type="button" disabled>Enviar</button>
        </div>
      </div>
    `;
    document.body.appendChild(overlay);

    let chosenCat = null;
    overlay.querySelectorAll(".fb-cat").forEach(btn => {
      btn.addEventListener("click", () => {
        overlay.querySelectorAll(".fb-cat").forEach(b => b.classList.remove("active"));
        btn.classList.add("active");
        chosenCat = btn.dataset.cat;
        recompute();
      });
    });

    const msgEl = overlay.querySelector("#fb-msg");
    const submitBtn = overlay.querySelector("#fb-submit");
    function recompute() {
      submitBtn.disabled = !(chosenCat && msgEl.value.trim().length >= 10);
    }
    msgEl.addEventListener("input", recompute);

    overlay.querySelector("#fb-cancel").addEventListener("click", close);
    submitBtn.addEventListener("click", () => submit(chosenCat, msgEl.value.trim(), overlay.querySelector("#fb-email").value.trim()));

    return overlay;
  }

  let overlay = null;
  function open() {
    if (!overlay) overlay = buildModal();
    overlay.classList.add("open");
    document.body.style.overflow = "hidden";
  }
  function close() {
    if (overlay) overlay.classList.remove("open");
    document.body.style.overflow = "";
  }

  async function submit(categoria, mensagem, email) {
    const status = overlay.querySelector("#fb-status");
    const btn    = overlay.querySelector("#fb-submit");
    status.className = ""; status.textContent = "Enviando…";
    btn.disabled = true;

    const payload = {
      p_categoria: categoria,
      p_pagina:    location.pathname || "/",
      p_mensagem:  mensagem,
      p_contexto:  null,
      p_email:     email || null,
      p_user_agent: navigator.userAgent.slice(0, 200),
      p_ip:        null,
    };

    try {
      const res = await fetch(`${SUPABASE_URL}/rest/v1/rpc/case_refs_feedback_submit`, {
        method: "POST",
        headers: {
          apikey: SUPABASE_ANON,
          Authorization: "Bearer " + SUPABASE_ANON,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(payload),
      });
      const body = await res.json().catch(() => ({}));
      if (!res.ok) {
        const msg = body.message || `HTTP ${res.status}`;
        status.className = "error";
        status.textContent = "Erro: " + msg;
        btn.disabled = false;
        return;
      }
      status.className = "success";
      status.textContent = "Recebido — obrigada por contar.";
      setTimeout(close, 1500);
    } catch (e) {
      status.className = "error";
      status.textContent = "Erro de rede: " + e.message;
      btn.disabled = false;
    }
  }

  function ensureButton() {
    if (document.getElementById("fb-btn")) return;
    const btn = document.createElement("button");
    btn.id = "fb-btn";
    btn.type = "button";
    btn.textContent = "💬 Feedback";
    btn.addEventListener("click", open);
    document.body.appendChild(btn);
  }

  function init() {
    injectStyles();
    ensureButton();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
