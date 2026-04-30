# E3-S2 — Modo apresentação (PDF)

**Epic:** EPIC-03 — Intelligence & Integration
**Status:** ✅ Done
**Concluído em:** 2026-04-30

## Implementação (no ar em `/live`)

### Modo seleção
- Botão **"📊 Selecionar pra apresentação"** na toolbar de `/live`
- Ao ativar: cards ganham checkbox no canto superior direito; click no card seleciona/desseleciona (não abre modal)
- Cards selecionados ficam com borda laranja (outline accent-500)
- **Barra fixa no rodapé** mostra contador "N selecionada(s)" + botões "📥 Gerar PDF" / "Cancelar"

### Geração PDF
- Pergunta título (default: "Referências — DD/MM/YYYY")
- Carrega thumbs como base64 (com CORS fallback)
- **Capa**: fundo brand cor `#554d33`, título centralizado, contador de slides + data
- **1 slide por referência** (A4 landscape):
  - Header bar marrom com `@perfil` + trilha · etapa · tipo
  - Thumb 90×90mm à esquerda
  - Resumo + caption (240 chars) à direita
  - Trecho da transcrição (360 chars)
  - Footer com numeração `N / total` + URL Instagram
- Download direto: `apresentacao-{titulo}-{timestamp}.pdf`

### Stack
- **jsPDF** via CDN (sem build)
- 100% client-side, sem servidor

## Arquivos modificados

- `live.html`:
  - `<script src="...jspdf.umd.min.js">`
  - CSS `.select-bar`, `.card.selected`, `.card-checkbox`
  - HTML `#selectBar` no body
  - Funções `toggleSelectMode()`, `onCardClick()`, `generatePresentation()`, `loadImageAsDataURL()`

## Limites assumidos

- Thumbs com CORS fechado caem pra placeholder cinza ("sem prévia") — só thumbs próprias do nosso CDN funcionam (CORS configurado pelo Vercel)
- Sem editor de slide individual (template fixo)
- Sem export pra Google Slides / PPTX (PDF é portátil suficiente)

## Iteração futura

- Salvar presentation em tabela `presentations` (audit + reabrir)
- Templates Light/Dark/Brand
- Notas customizadas por slide
- Vincular automaticamente a uma mentorada (depende E3-S3)
