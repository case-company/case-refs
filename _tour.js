// case-refs — tour de primeira visita (E03-S2).
//
// Mostra 3 tooltips para visitantes novos em /trilhas. Flag de visita
// persistida em localStorage. Re-disparavel via querystring `?tour=1`.
//
// Uso: incluir <script src="/_tour.js" defer></script> nas paginas que
// devem mostrar o tour (hoje so /trilhas).

(function () {
  const FLAG_KEY = 'caso-ref-toured';
  const FLAG_VERSION = 'v1';

  const STEPS = [
    {
      target: '#etapa',
      title: 'Filtre pelos três grupos DECIDA',
      body: 'Use este filtro para isolar Descoberta (70%), C+I+D (30%) ou Ação (10%). O critério editorial muda em cada grupo — consulte o "Como usar" se ficar em dúvida.',
    },
    {
      target: '.card',
      title: 'Clique para abrir a referência completa',
      body: 'Cada card abre um modal com prévia, transcrição e o Guia de uso editorial (quando usar / por que funciona / como adaptar). É o coração do banco.',
    },
    {
      target: '.back-bar',
      title: 'Volte ao guia a qualquer momento',
      body: 'O link "📖 Como usar" no topo te leva pro guia DECIDA completo. Não precisa decorar nada — só voltar aqui quando bater dúvida.',
    },
  ];

  function shouldStart() {
    const params = new URLSearchParams(location.search);
    if (params.get('tour') === '1') return true;
    try {
      return localStorage.getItem(FLAG_KEY) !== FLAG_VERSION;
    } catch (_) {
      return false;
    }
  }

  function markDone() {
    try { localStorage.setItem(FLAG_KEY, FLAG_VERSION); } catch (_) {}
  }

  function injectStyles() {
    if (document.getElementById('tour-styles')) return;
    const s = document.createElement('style');
    s.id = 'tour-styles';
    s.textContent = `
      .tour-overlay { position: fixed; inset: 0; background: rgba(46,43,37,.55); z-index: 9998; }
      .tour-tooltip { position: absolute; z-index: 9999; max-width: 320px; background: white; border-radius: 12px; padding: 16px 18px; box-shadow: 0 16px 40px rgba(0,0,0,.25); font-family: var(--font-ui), system-ui, sans-serif; color: var(--neutral-800, #2e2b25); }
      .tour-tooltip h4 { font-family: var(--font-display, "Optima", serif); margin: 0 0 6px; font-size: 1.05rem; color: var(--brand-700, #554d33); }
      .tour-tooltip p { margin: 0 0 12px; font-size: .88rem; line-height: 1.5; color: var(--cream-700, #807a67); }
      .tour-tooltip .tour-actions { display: flex; justify-content: space-between; align-items: center; gap: 8px; }
      .tour-tooltip .tour-step { font-size: .7rem; color: var(--cream-700, #807a67); letter-spacing: .08em; text-transform: uppercase; }
      .tour-tooltip button { font-family: inherit; cursor: pointer; }
      .tour-skip { background: transparent; border: none; color: var(--cream-700, #807a67); font-size: .8rem; padding: 6px 10px; }
      .tour-next { background: var(--accent-500, #d4703a); color: white; border: none; border-radius: 6px; padding: 8px 16px; font-weight: 600; font-size: .85rem; }
      .tour-highlight { box-shadow: 0 0 0 4px rgba(212,112,58,.6), 0 0 0 9999px rgba(46,43,37,.55) !important; border-radius: 8px; position: relative; z-index: 9999; }
    `;
    document.head.appendChild(s);
  }

  function placeTooltip(tip, target) {
    const rect = target.getBoundingClientRect();
    const tipRect = tip.getBoundingClientRect();
    const margin = 12;
    // Tenta abaixo; se nao couber, acima.
    let top = rect.bottom + margin + window.scrollY;
    if (top + tipRect.height > window.scrollY + window.innerHeight) {
      top = rect.top - tipRect.height - margin + window.scrollY;
    }
    let left = rect.left + (rect.width / 2) - (tipRect.width / 2) + window.scrollX;
    left = Math.max(12, Math.min(left, window.scrollX + window.innerWidth - tipRect.width - 12));
    tip.style.top = `${Math.max(12, top)}px`;
    tip.style.left = `${left}px`;
  }

  let currentStep = -1;
  let overlay, tooltip, currentTarget;

  function cleanup() {
    if (overlay) overlay.remove();
    if (tooltip) tooltip.remove();
    if (currentTarget) currentTarget.classList.remove('tour-highlight');
    overlay = tooltip = currentTarget = null;
  }

  function finish() {
    cleanup();
    markDone();
  }

  function showStep(idx) {
    cleanup();
    if (idx >= STEPS.length) { finish(); return; }
    const step = STEPS[idx];
    const target = document.querySelector(step.target);
    if (!target) { showStep(idx + 1); return; }

    overlay = document.createElement('div');
    overlay.className = 'tour-overlay';
    overlay.addEventListener('click', () => finish());
    document.body.appendChild(overlay);

    currentTarget = target;
    target.classList.add('tour-highlight');
    // Garante que o target seja visivel
    target.scrollIntoView({ behavior: 'smooth', block: 'center', inline: 'center' });

    tooltip = document.createElement('div');
    tooltip.className = 'tour-tooltip';
    tooltip.setAttribute('role', 'dialog');
    tooltip.setAttribute('aria-modal', 'true');
    tooltip.innerHTML = `
      <h4>${step.title}</h4>
      <p>${step.body}</p>
      <div class="tour-actions">
        <span class="tour-step">${idx + 1} / ${STEPS.length}</span>
        <div>
          <button type="button" class="tour-skip">Pular tour</button>
          <button type="button" class="tour-next">${idx === STEPS.length - 1 ? 'Concluir' : 'Próximo'}</button>
        </div>
      </div>
    `;
    document.body.appendChild(tooltip);

    tooltip.querySelector('.tour-skip').addEventListener('click', finish);
    tooltip.querySelector('.tour-next').addEventListener('click', () => showStep(idx + 1));

    // Posicionamento depois de inserido no DOM (precisa do bounding box real)
    requestAnimationFrame(() => placeTooltip(tooltip, target));
  }

  function start() {
    if (!shouldStart()) return;
    injectStyles();
    // Pequeno delay para garantir que cards renderizaram
    setTimeout(() => showStep(0), 400);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', start);
  } else {
    start();
  }
})();
