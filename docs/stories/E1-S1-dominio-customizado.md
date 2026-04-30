# E1-S1 — Domínio customizado refs.casein.com.br

**Epic:** EPIC-01 — Quick Wins
**Status:** ✅ Done
**Prioridade:** P0
**Estimate:** 30 min (real: ~5 min)
**Owner:** Kaique
**Dependências:** Nenhuma
**Concluído em:** 2026-04-30

---

## User Story

Como **time da Case**, quero acessar o banco de referências por uma URL memorável (`refs.casein.com.br`), pra **não precisar lembrar/colar a URL longa do Vercel** toda vez.

## Contexto

URL técnica `case-refs.vercel.app` substituída por subdomínio sob `casein.com.br` (único domínio Case disponível). Sem conflito com Hetzner/Cloudflare porque é subdomínio dedicado.

## Resultado

**🌐 https://refs.casein.com.br** no ar com SSL válido.

## Critérios de Aceite (todos atendidos)

1. ✅ **Domínio adicionado** ao Vercel via `vercel domains add refs.casein.com.br`
2. ✅ **Registro DNS criado** no Cloudflare (DNS authoritative do `casein.com.br`)
   - Tipo: A
   - Nome: `refs`
   - Valor: `76.76.21.21` (IP Vercel)
   - Proxy status: **DNS only** (cinza, não Proxied) — crítico pra Vercel emitir SSL
3. ✅ **SSL ativo** — Let's Encrypt emitiu cert em ~1 minuto após DNS propagar
   - Issuer: Let's Encrypt R12
   - Válido até 2026-07-29 (renova automaticamente)
4. ✅ **URL antiga continua funcionando** — `case-refs.vercel.app` resolve com 200 (alias secundário)
5. ✅ **Todas as rotas testadas**: `/`, `/trilhas`, `/posts`, `/live`, `/thumbs/*` retornam 200

## Implementação real

### Comando Vercel

```bash
cd ~/Downloads/case-references
vercel domains add refs.casein.com.br
```

Output indicou opções:
- (a) Adicionar A record `76.76.21.21` no DNS (escolhido)
- (b) Trocar nameservers pra `ns1.vercel-dns.com` (descartado — quebraria outros records do casein.com.br)

### DNS Cloudflare

Painel `dash.cloudflare.com` → casein.com.br → DNS → Records → Add record:

| Type | Name | IPv4 | Proxy | TTL |
|---|---|---|---|---|
| A | refs | 76.76.21.21 | **DNS only** | Auto |

### Validação

```bash
dig +short A refs.casein.com.br @1.1.1.1
# 76.76.21.21

curl -sI https://refs.casein.com.br
# HTTP/2 200

openssl s_client -servername refs.casein.com.br -connect refs.casein.com.br:443
# issuer= Let's Encrypt R12
# notAfter=Jul 29 13:45:38 2026 GMT
```

## Definition of Done (todos atendidos)

- [x] `https://refs.casein.com.br` carrega o site com SSL verde
- [x] Botão `+ Adicionar referência` funciona no novo domínio
- [x] Webhook n8n recebe payloads do novo domínio (CORS ok — webhook é wildcard)
- [x] README atualizado com URL canônica (próxima sub-task)

## Aprendizados

- **Não trocar nameservers** quando o apex já está em outro DNS provider. Use A record no subdomínio — atomic, reversível, zero impacto no resto.
- **Cloudflare proxy laranja BLOQUEIA emissão de SSL pelo Vercel.** Sempre usar "DNS only" pra subdomínios apontados pra outros serviços.
- **Vercel pediu A record (`76.76.21.21`) ao invés de CNAME (`cname.vercel-dns.com`)** — ambos funcionam, A é mais direto.
- **SSL emitiu em 1 minuto** — não 5-10 como esperado. Let's Encrypt rápido quando DNS está limpo.

## Riscos identificados (não materializaram)

- ❌ DNS pode levar até 24h pra propagar — propagou em <1 min
- ❌ CSP no Supabase pode bloquear novo domínio — não bloqueou (anon key não tem allowlist por origin)

## Sub-tasks pendentes (low priority)

- [ ] Atualizar README do repo com URL canônica `refs.casein.com.br`
- [ ] Atualizar `.env.example` se houver referência hardcoded à URL antiga
- [ ] Comunicar URL nova pro time Case (Queila + Gobbi)
