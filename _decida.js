// case-refs — DECIDA taxonomy single source of truth (ADR 0001).
//
// Enum no banco continua `DESCOBERTA | CONFIANCA | ACAO`. A UX renderiza
// a partir desta constante. Antes de hardcoded label em qualquer pagina,
// importar este arquivo via `<script src="/_decida.js"></script>` e ler
// de `window.DECIDA_MAP`.
//
// Por que C+I+D em vez de "Confiança":
//   O bloco do meio cobre 3 movimentos editoriais (Confiança +
//   Identificação + Desejo). Chamar so de "Confiança" perde 2/3 da
//   verdade do metodo. Por isso o label visivel exibe "C+I+D" e o
//   tooltip/label longo explica os 3 nomes por extenso.

(function () {
  const MAP = {
    DESCOBERTA: {
      enum_value: 'DESCOBERTA',
      label: 'Descoberta',
      label_long: 'Descoberta · Entendimento',
      letras: 'D+E',
      percentual_recomendado: 60,
      descricao_curta: 'Conteúdo que atrai e faz a audiência entender quem você é e que problema você resolve.',
      badge_class: 'badge-brand',
    },
    CONFIANCA: {
      enum_value: 'CONFIANCA',
      label: 'C+I+D',
      label_long: 'Confiança · Identificação · Desejo',
      letras: 'C+I+D',
      percentual_recomendado: 30,
      descricao_curta: 'Conteúdo que aprofunda — autoridade, prova social, identificação, desejo.',
      badge_class: 'badge-accent',
    },
    ACAO: {
      enum_value: 'ACAO',
      label: 'Ação',
      label_long: 'Ação',
      letras: 'A',
      percentual_recomendado: 10,
      descricao_curta: 'Conteúdo que pede decisão e próximo passo concreto.',
      badge_class: 'badge-warning',
    },
  };

  // Ordem canonica para listagem (topo→fundo do funil).
  const ORDER = ['DESCOBERTA', 'CONFIANCA', 'ACAO'];

  // Helpers de leitura segura. Aceitam null/undefined sem quebrar.
  function labelOf(enumValue) {
    return (MAP[enumValue] && MAP[enumValue].label) || enumValue || '';
  }
  function labelLongOf(enumValue) {
    return (MAP[enumValue] && MAP[enumValue].label_long) || enumValue || '';
  }
  function badgeOf(enumValue) {
    return (MAP[enumValue] && MAP[enumValue].badge_class) || 'badge-neutral';
  }

  window.DECIDA_MAP = MAP;
  window.DECIDA_ORDER = ORDER;
  window.decidaLabel = labelOf;
  window.decidaLabelLong = labelLongOf;
  window.decidaBadge = badgeOf;
})();
