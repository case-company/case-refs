# E1-S2 — Proteção por senha (Vercel Password Protection)

**Epic:** EPIC-01 — Quick Wins
**Status:** Ready
**Prioridade:** P0
**Estimate:** 15 min (Pro plan) ou 2h (DIY auth se ficar no Hobby)
**Owner:** Kaique
**Dependências:** Nenhuma

---

## User Story

Como **dona da Case (Queila)**, quero que apenas o time autorizado acesse o banco de referências, pra **não vazar a curadoria estratégica** mesmo o repo sendo público.

## Contexto

Repo é público (decisão consciente — facilita contribuição), mas dados de curadoria são internos. Sem auth, qualquer um com a URL vê tudo.

## Opções

### Opção A — Vercel Password Protection (recomendado)
- Requer Vercel Pro ($20/mês/membro) ou Team
- 1 click no painel: Project Settings → Deployment Protection → Password
- Define senha única compartilhada com time

### Opção B — Auth via Supabase (DIY no Hobby)
- Magic link Supabase Auth
- Adiciona modal de login no `index.html`
- Persiste em localStorage
- Mais trabalho, ~2h

### Opção C — Cloudflare Access (alternativa Pro)
- Move DNS pra Cloudflare
- Free tier inclui Access pra até 50 usuários
- Auth via email (envia link de login)

## Decisão

**Opção A** se a Case já tem Vercel Pro ativo. Senão **Opção C** (gratuita até 50 users).

## Critérios de Aceite

1. **Acesso sem senha** redireciona pra tela de auth
2. **Auth bem-sucedido** persiste por 30 dias (cookie)
3. **Logout disponível** (mesmo que via clear cookies)
4. **Webhook n8n continua funcionando** sem auth (server-side)
5. **API Supabase continua acessível** pelo front após auth

## Definition of Done

- [ ] Tela de senha aparece pra usuário não-autenticado
- [ ] Time da Case recebe a senha via canal seguro (1Password / WhatsApp Queila)
- [ ] Documentação atualizada em README com instruções de acesso
- [ ] Domínio principal protegido (refs.case.com.br)

## Não cobre

- Múltiplos níveis de permissão (admin/editor/viewer)
- Auditoria de quem acessou quando
- SSO com Google Workspace
