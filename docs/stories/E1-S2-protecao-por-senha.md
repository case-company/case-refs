# E1-S2 — Proteção por senha

**Epic:** EPIC-01 — Quick Wins
**Status:** ✅ Done (gate client-side)
**Prioridade:** P0
**Estimate:** 15 min (Pro plan) ou 2h (DIY)
**Owner:** Kaique
**Concluído em:** 2026-04-30

---

## User Story

Como **dona da Case (Queila)**, quero que apenas o time autorizado acesse o banco de referências, pra **não vazar a curadoria estratégica** mesmo o repo sendo público.

## Decisão

Vercel plano é **Hobby** (sem Password Protection do Pro). Implementado **gate client-side simples** — não é fortaleza, mas filtra acesso casual ao link público.

## Implementação

### `/_auth.js` — gate injetado em todas as páginas

- Verifica cookie `case-refs-auth=ok` no load
- Se não tem: bloqueia render, mostra prompt de senha
- Senha confere (SHA-256) → seta cookie 30 dias → libera site
- Hash hardcoded no JS (sem segredo, repo é público)

### Senha atual

**`case2026`** — TROCAR antes de divulgar pro time.

### Como trocar a senha

1. No console do browser: `await crypto.subtle.digest('SHA-256', new TextEncoder().encode('NOVA-SENHA')).then(b => Array.from(new Uint8Array(b)).map(x=>x.toString(16).padStart(2,'0')).join(''))`
2. Copia o hash retornado
3. Edita `_auth.js` linha `PASSWORD_HASH = '...'` com o novo hash
4. Commit + push (deploy automático)
5. Comunica nova senha pro time

Ou via Node:
```bash
node -e "console.log(require('crypto').createHash('sha256').update('NOVA-SENHA').digest('hex'))"
```

## Trade-offs assumidos

- ⚠️ **Não é segurança forte.** Atacante motivado pode:
  - Inspecionar JS, ver hash, fazer brute-force em senha fraca
  - Fazer fetch direto na view Supabase (anon key também é pública no JS)
- ✅ **Cobre o caso real:** alguém com link público não vê dados sem saber a senha
- ✅ **Dados sensíveis estão protegidos no Supabase via RLS** (anon key só lê view pública filtrada)
- ✅ **Custo: zero**, sem dependências externas

## Critérios de Aceite (atendidos)

1. ✅ Acesso sem cookie redireciona pra prompt de senha
2. ✅ Auth bem-sucedido persiste 30 dias (cookie)
3. ✅ Logout disponível via clear cookies do browser
4. ✅ Webhook n8n continua funcionando server-side (não afetado)
5. ✅ API Supabase continua acessível pelo front após auth (gate é só visual)

## Arquivos modificados

- `_auth.js` — novo arquivo com lógica do gate
- `index.html`, `trilhas.html`, `posts.html`, `live.html` — `<script src="/_auth.js">` injetado no head

## Próximas iterações (opcional)

- **Migrar pra Cloudflare Access** (gratuito até 50 users, auth via email Google Workspace)
- **Vercel Pro** ($20/mês) → Password Protection nativo, 1 click no painel
- **Magic link via Supabase Auth** se quiser auth por usuário individual com audit
