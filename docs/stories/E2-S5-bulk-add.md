# E2-S5 — Bulk add (vários links de uma vez)

**Epic:** EPIC-02 — Curadoria Power Tools
**Status:** ✅ Done
**Concluído em:** 2026-04-30

## Implementação

- **Toggle "Adicionar várias de uma vez"** no topo do modal de adicionar
- Substitui input único por **textarea (1 link por linha)**
- **Pré-validação visual em tempo real**: "X link(s) válido(s) · Y inválido(s) (serão ignorados)"
- Ao clicar **"Adicionar todas"**:
  - Loop sequencial enviando 1 por 1 pro webhook
  - Progress no botão: "Enviando 5/20…"
  - Linhas que falharem voltam pro textarea pra retry
  - Sucesso final fecha modal automaticamente
- Trilha + notas aplicadas a todos os items do batch
- Suporta mix de perfis e publicações no mesmo batch
- Cada item é tracked em `pending-ids` localStorage pra E2-S6 detectar conclusão

## Arquivos modificados

- `trilhas.html` — checkbox toggle, textarea, preview live, `addReference()` reescrito com loop, helpers `buildPayload()` e `trackPending()`

## Limites assumidos

- Throttle: sem sleep entre requests (n8n + Apify gerenciam fila do lado backend)
- Sem dedup: mesmo link 2× envia 2× (responsabilidade do n8n detectar duplicata por shortcode/URL)

## Iteração futura

- Endpoint `/bulk-add` único no n8n (1 request com array) — atualmente envia N requests separados
- Detecção de duplicata client-side antes de enviar
