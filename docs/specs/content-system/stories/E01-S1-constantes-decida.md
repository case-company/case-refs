---
id: E01-S1
title: "Criar constante DECIDA no front"
type: story
epic: E01
status: Done
priority: P0
estimated_effort: S
date: 2026-05-12
owner: Kaique Rodrigues
---

# Story E01-S1 — Criar constante DECIDA no front

## Story

**Como** desenvolvedor mantenedor do `refs.casein.com.br`,
**eu quero** uma constante única exportada que mapeia os valores enum do banco (`DESCOBERTA`, `CONFIANCA`, `ACAO`) para os labels DECIDA e percentuais canônicos,
**para que** nenhum label viva como string hardcoded espalhado pelas páginas e a tradução enum → label seja a única fonte de verdade.

## Acceptance Criteria

1. Arquivo `_decida.js` (ou similar) na raiz do projeto exporta o objeto `DECIDA_MAP`.
2. Cada entrada do mapa tem: `enum_value` (DB), `label` (exibido — ex.: "C+I+D"), `label_long` (ex.: "Confiança · Identificação · Desejo"), `percentual_recomendado` (70/30/10), `descricao_curta`.
3. Pelo menos um arquivo HTML do site importa a constante (smoke da exportação).
4. Grep por `"Confiança"` em `*.html` retorna zero ocorrências como label de etapa (pode aparecer em texto livre não-label).

## Tasks

- [ ] Criar `_decida.js` com `export const DECIDA_MAP` (módulo ES) (AC 1, 2)
- [ ] Definir as 3 entradas: DESCOBERTA, CONFIANCA, ACAO (AC 2)
- [ ] Documentar inline com comentário explicando o "porquê" do C+I+D (AC 2)
- [ ] Importar a constante em uma página piloto (sugestão: `trilhas.html`) só para validar ES module resolution no Vercel (AC 3)
- [ ] Grep guarda como parte do DoD: `grep -n 'Confiança' *.html | grep -i 'etapa\|filtro\|badge'` deve retornar vazio (AC 4)

## Dev Notes

- Stack: HTML estático + JS vanilla servido pelo Vercel. Sem bundler — usar `<script type="module">`.
- DB enum nunca muda: a UX é que vai renderizar `label`, mas a query continua filtrando `etapa_funil = 'CONFIANCA'`.
- Não tocar o schema; nem a view pública. Esta story é 100% front.
- Caminho sugerido: `_decida.js` na raiz seguindo o padrão `_auth.js` que já existe.

## Testing

- Manual: abrir `/trilhas`, no console: `import('./_decida.js').then(m => console.log(m.DECIDA_MAP))` — deve retornar o objeto.
- Visual: nenhuma regressão em `/trilhas`, `/live`, `/dashboard` (esta story não altera UX, só introduz o módulo).
- Lint manual: `grep -n 'Confiança' *.html`.

## Definition of Done

- [ ] AC 1-4 verificados
- [ ] Commit com mensagem `feat(decida): constante DECIDA_MAP unificada`
- [ ] PR ou push direto para `main` (projeto não usa branches feature ainda)
