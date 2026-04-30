# E3-S2 — Modo apresentação (slide/PDF)

**Epic:** EPIC-03 — Intelligence & Integration
**Status:** Ready
**Prioridade:** P2
**Estimate:** 2 dias
**Owner:** Kaique
**Dependências:** Lib de geração de PDF (jsPDF + html2canvas)

---

## User Story

Como **mentor** preparando reunião com mentorada, quero **selecionar 5-10 refs** e gerar um **slide/PDF apresentável** pra mostrar exemplos sem ter que mandar 10 links separados.

## Contexto

Hoje: pra apresentar refs pra mentorada, mentor abre cada link no Instagram, dá print, cola no Keynote/Slides, escreve descrição. Demora 30min+ por reunião.
Queremos: select N refs → "Gerar apresentação" → PDF pronto.

## Critérios de Aceite

1. **Modo seleção**: botão "📊 Modo apresentação" na toolbar de `/live` ou `/posts`
2. Em modo seleção, cards mostram **checkbox**, e badge "X selecionadas"
3. **Botão "Gerar apresentação (X)"** quando há ≥1 selecionada
4. **Modal de configuração**:
   - Título da apresentação (default: "Referências — {data}")
   - Mentorada destinatária (opcional, dropdown se E3-S3 estiver pronto)
   - Notas customizadas por slide (opcional)
   - Tema: Light / Dark / Brand Case
5. **Gera PDF** (1 ref por slide):
   - Capa: thumb grande, perfil, tipo estratégico, etapa
   - Caption (se tiver)
   - Trecho da transcrição (200 chars)
   - QR code do link IG (opcional)
6. **Download direto** no browser (`apresentacao-{titulo}-{data}.pdf`)
7. **Histórico**: apresentações salvas em `presentations` table com lista de IDs (pra E3-S3 vincular mentorada)

## Notas Técnicas

### Stack

- **jsPDF** + **html2canvas** (CDN, sem build)
- Templates HTML render em iframe oculto, captura como canvas, vira página PDF

```html
<!-- CDN -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js"></script>
```

```js
async function generatePDF(refs, opts) {
  const { jsPDF } = window.jspdf;
  const pdf = new jsPDF({ orientation: 'landscape', format: 'a4' });
  
  // Capa
  pdf.setFontSize(28);
  pdf.text(opts.titulo, 20, 30);
  pdf.setFontSize(14);
  pdf.text(`${refs.length} referências · ${new Date().toLocaleDateString('pt-BR')}`, 20, 45);
  
  for (let i = 0; i < refs.length; i++) {
    pdf.addPage();
    const slide = renderSlideHTML(refs[i], opts.theme);
    const canvas = await html2canvas(slide, { scale: 2, useCORS: true });
    const img = canvas.toDataURL('image/jpeg', 0.85);
    pdf.addImage(img, 'JPEG', 0, 0, 297, 210); // A4 landscape mm
  }
  
  pdf.save(`${opts.titulo.replace(/[^a-z0-9]/gi,'-')}-${Date.now()}.pdf`);
}

function renderSlideHTML(ref, theme) {
  const tpl = document.getElementById('slideTemplate').cloneNode(true);
  tpl.style.display = 'block';
  tpl.querySelector('.slide-thumb').style.backgroundImage = `url(${ref.thumb_url})`;
  tpl.querySelector('.slide-perfil').textContent = '@' + ref.perfil;
  tpl.querySelector('.slide-tipo').textContent = ref.tipo_estrategico;
  tpl.querySelector('.slide-etapa').textContent = ref.etapa_funil;
  tpl.querySelector('.slide-caption').textContent = (ref.caption || '').slice(0, 200);
  tpl.querySelector('.slide-transcript').textContent = (ref.transcricao || '').slice(0, 300);
  document.body.appendChild(tpl);
  return tpl;
}
```

### Migration

```sql
CREATE TABLE presentations (
  id BIGSERIAL PRIMARY KEY,
  title TEXT,
  ref_ids BIGINT[],
  mentorada_id BIGINT, -- nullable, FK pra E3-S3
  generated_at TIMESTAMPTZ DEFAULT now(),
  created_by TEXT
);
```

## Definition of Done

- [ ] Modo seleção com checkbox em cards
- [ ] Modal de config gera PDF
- [ ] Templates Light/Dark/Brand
- [ ] PDF download funciona
- [ ] Histórico salvo em tabela
- [ ] Performance: 10 refs em <30s

## Edge cases

- **Ref sem thumb**: usa placeholder com texto
- **Caption longa**: trunca em 200 chars com "..."
- **Transcrição vazia**: omite o bloco
- **CORS issue com thumb_url**: pré-carrega via fetch + base64

## Variantes futuras

- Slide HTML interativo (PDF é mais portátil mas estático)
- Export pra Google Slides via API
- Templates customizáveis por usuário
