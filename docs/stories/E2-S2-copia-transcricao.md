# E2-S2 — Cópia de transcrição com 1 clique

**Epic:** EPIC-02 — Curadoria Power Tools
**Status:** Ready
**Prioridade:** P1
**Estimate:** 1h
**Owner:** Kaique
**Dependências:** Nenhuma

---

## User Story

Como **time produzindo dossiê**, quero **copiar a transcrição** de uma ref pro clipboard com 1 clique, pra **colar em prompt do GPT/Claude** ou no documento sem ter que selecionar texto manualmente no modal.

## Contexto

Hoje: abre modal, scroll até transcrição, seleciona texto longo (que tem scroll interno), Cmd+C, Cmd+V no destino. Mais penoso ainda em mobile.
Queremos: 1 clique → clipboard.

## Critérios de Aceite

1. **No modal**, ao lado do título "Transcrição", botão **"📋 Copiar"**
2. Clicar copia **transcrição completa** + formato:
   ```
   @perfil — Trilha: clinic | Etapa: CONFIANCA | Tipo: Prova Social
   URL: https://www.instagram.com/p/SHORTCODE/

   [transcrição completa]
   ```
3. Toast "Transcrição copiada ✓"
4. **Botão secundário "📋 Só texto"** copia só a transcrição (sem header)
5. **Indicador de tamanho** ("3.2k caracteres") pro usuário saber se vai estourar limite de prompt

## Notas Técnicas

```js
function copyTranscript(ref, mode = 'full') {
  let txt;
  if (mode === 'full') {
    txt = `@${ref.perfil} — Trilha: ${ref.trilha} | Etapa: ${ref.etapa_funil || '—'} | Tipo: ${ref.tipo_estrategico || '—'}\n`;
    txt += `URL: ${ref.url}\n\n`;
    txt += ref.transcricao || '(sem transcrição)';
  } else {
    txt = ref.transcricao || '';
  }
  navigator.clipboard.writeText(txt).then(() => {
    showToast(`Copiado ✓ (${txt.length.toLocaleString('pt-BR')} caracteres)`);
  });
}
```

## Definition of Done

- [ ] Botão "📋 Copiar" no header da seção Transcrição (modal `/posts` e `/live`)
- [ ] Botão "📋 Só texto" alternativo
- [ ] Toast mostra tamanho copiado
- [ ] Header inclui contexto (perfil, trilha, etapa, tipo, URL)
- [ ] Funciona em mobile (Safari iOS, Chrome Android)

## Não cobre

- Cópia em massa (várias refs de uma vez) — fica em E3-S2 (modo apresentação)
- Formato Markdown vs. plain text — só plain text por simplicidade
