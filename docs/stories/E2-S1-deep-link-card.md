# E2-S1 — Compartilhamento de card via deep-link

**Epic:** EPIC-02 — Curadoria Power Tools
**Status:** ✅ Done
**Concluído em:** 2026-04-30

## Implementação

- **Botão 🔗 no canto inferior direito de cada card** em `/live` (aparece no hover)
- **Botão "🔗 Compartilhar link"** no rodapé do modal de detalhes
- Clique copia `https://refs.casein.com.br/live#card={id}` pro clipboard
- Toast: "Link copiado ✓"
- Ao abrir URL com `#card=ID`: aguarda DATA carregar (até 6s), abre modal automaticamente, scroll suave até o card
- Funciona em hashchange (compartilhar link sem reload)
- Em ID inexistente (ex: ref deletada): toast "Referência não encontrada"

## Arquivos modificados

- `live.html` — função `shareCard()`, listener de hashchange/load, `data-card-id` em cada card, CSS `.card-share`
