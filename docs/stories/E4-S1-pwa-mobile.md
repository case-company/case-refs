# E4-S1 — PWA mobile instalável

**Epic:** EPIC-04 — AI & Mobile
**Status:** ✅ Done (instalação + cache offline básico)
**Concluído em:** 2026-04-30

## Implementação

### Web App Manifest (`manifest.json`)
- Nome: case-refs
- `display: standalone` (abre como app, sem chrome do browser)
- Theme color brand: `#554d33`
- Background: `#faf9f7`
- 2 ícones (192×192 + 512×512)
- 3 shortcuts (long-press no ícone do app):
  - "Adicionar referência" → `/trilhas#open-form`
  - "Últimas (24h)" → `/live`
  - "Dashboard" → `/dashboard`

### Service Worker (`sw.js`)
- **Install**: pré-cacheia rotas estáticas (`/`, `/trilhas`, `/posts`, `/live`, `/dashboard`, `_auth.js`)
- **Activate**: limpa caches antigos (versionamento `case-refs-v1`)
- **Fetch strategies**:
  - Thumbs (`/thumbs/*`) → cache-first
  - HTML/JS/CSS → stale-while-revalidate (UI rápida + atualização em background)
  - Supabase + webhook → bypass total (always network)
- **NÃO intercepta POST** (writes vão direto pro webhook)

### Ícones
- Gerados via SVG → PNG (sips/macOS)
- Letra "r" estilizada em accent-500 sobre fundo brand-700
- 192×192 e 512×512 (covers all iOS/Android density)

### Registro automático
- `_auth.js` registra Service Worker e injeta `<link rel="manifest">` + `<meta name="theme-color">` + apple-touch-icon em todas as páginas

## Como instalar

### iOS (Safari)
1. Abre `https://refs.casein.com.br`
2. Tap no botão "Compartilhar" (quadradinho com seta)
3. "Adicionar à Tela de Início"
4. Confirma → ícone case-refs aparece na home

### Android (Chrome)
1. Abre o site
2. Menu (⋮) → "Instalar app" (aparece automaticamente após critério Chrome)
3. Confirma → app instalado

## Verificação

```bash
curl -sI https://refs.casein.com.br/manifest.json   # 200 application/json
curl -sI https://refs.casein.com.br/sw.js           # 200 application/javascript
curl -sI https://refs.casein.com.br/icons/icon-512.png  # 200 image/png
```

Lighthouse PWA audit roda direto em `chrome://inspect` ou DevTools.

## Não implementado (iteração futura)

- **Background sync** pra envio offline — sem isso, refs adicionadas offline não vão pra fila quando voltar online
- **Web Share Target API** (compartilhar do IG abre o app pra cadastrar)
- **Push notifications** (precisaria backend FCM/APNs)
- **Install prompt customizado** (banner persuasivo) — usa default do browser
- **Offline mode robusto** com fallback page

## Arquivos modificados/criados

- `manifest.json` — novo
- `sw.js` — novo
- `icons/icon-192.png`, `icons/icon-512.png`, `icons/icon.svg` — novos
- `_auth.js` — register SW + inject manifest link
