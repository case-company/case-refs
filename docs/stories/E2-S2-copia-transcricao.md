# E2-S2 — Cópia de transcrição com 1 clique

**Epic:** EPIC-02 — Curadoria Power Tools
**Status:** ✅ Done
**Concluído em:** 2026-04-30

## Implementação

- **Botão "📋 Copiar"** ao lado do título "Transcrição" no modal de `/live`
- Copia transcrição completa pro clipboard
- Toast mostra contador: "Copiado ✓ (3.245 caracteres)"
- Útil pra colar em prompt do GPT/Claude ou em dossiê

## Arquivos modificados

- `live.html` — função `copyTranscription()` no header da seção Transcrição

## Iteração futura (não implementada)

- Botão "📋 Só texto" vs "📋 Com header" — atualmente só copia o texto puro
- Cópia em massa de várias refs — fica em E3-S2 (modo apresentação)
