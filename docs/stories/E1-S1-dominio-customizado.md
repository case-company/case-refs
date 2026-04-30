# E1-S1 — Domínio customizado refs.case.com.br

**Epic:** EPIC-01 — Quick Wins
**Status:** Ready
**Prioridade:** P0
**Estimate:** 30 min
**Owner:** Kaique
**Dependências:** Nenhuma

---

## User Story

Como **time da Case**, quero acessar o banco de referências por uma URL memorável (`refs.case.com.br`), pra **não precisar lembrar/colar a URL longa do Vercel** toda vez.

## Contexto

Hoje: `case-refs.vercel.app` — URL técnica, fora da identidade visual da Case.
Queremos: `refs.case.com.br` (ou subdomínio similar dentro do domínio Case).

## Critérios de Aceite

1. **Domínio escolhido e registrado** no Vercel via `vercel domains add refs.case.com.br`
2. **Registro DNS criado** no provedor do `case.com.br` (CNAME → cname.vercel-dns.com)
3. **SSL ativo** (Vercel emite automaticamente Let's Encrypt)
4. **URL antiga continua funcionando** (`case-refs.vercel.app` resolve com 200)
5. **Redirect 301** opcional: aliases secundários redirecionam pro canônico

## Notas Técnicas

```bash
cd ~/Downloads/case-references
vercel domains add refs.case.com.br
# segue instruções de DNS, espera propagação (~5 min)
vercel alias set case-refs-PROD-HASH.vercel.app refs.case.com.br
```

DNS no provedor (Registro.br ou similar):
- Tipo: `CNAME`
- Nome: `refs`
- Valor: `cname.vercel-dns.com`
- TTL: 3600

## Definition of Done

- [ ] `https://refs.case.com.br` carrega o site com SSL verde
- [ ] Botão `+ Adicionar referência` funciona no novo domínio
- [ ] Webhook n8n recebe payloads do novo domínio (CORS ok)
- [ ] README atualizado com URL canônica

## Riscos

- **DNS pode levar até 24h pra propagar** em alguns provedores
- **CSP no Supabase pode bloquear** novo domínio se houver allowlist (validar)
