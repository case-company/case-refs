# case-refs

Banco de referências de conteúdo da Case — trilhas Mentoria + Clínica.

🌐 **Produção:** https://refs.casein.com.br
🔄 **Auto-deploy:** push em `main` → produção em ~30s

## Páginas

| Rota | O que tem |
|---|---|
| [`/`](https://refs.casein.com.br/) | Landing com 3 cards |
| [`/trilhas`](https://refs.casein.com.br/trilhas) | Banco organizado por etapa do funil + tipo |
| [`/posts`](https://refs.casein.com.br/posts) | Posts fixados + destaques dos perfis |
| [`/live`](https://refs.casein.com.br/live) | Refs cadastradas via formulário (filtros de data + auto-refresh) |

## Como adicionar referência

Botão **"+ Adicionar referência"** em qualquer página → cola link do Instagram (perfil ou post) → escolhe trilha → clica "Adicionar". Aparece em `/live` em alguns minutos.

## Stack

- HTML/CSS/JS puro estático
- Deploy: Vercel
- Banco de leitura: Supabase Case (view pública via REST)
- Pipeline de processamento: webhook n8n
- Sem build step, sem framework

## Desenvolvimento

```bash
git clone https://github.com/case-company/case-refs.git
cd case-refs
# abre qualquer .html no browser, edita, push
git add -u && git commit -m "fix: ..." && git push
# Vercel redeploya automaticamente
```

## Roadmap

Veja **[`docs/`](./docs/README.md)** — 4 epics, 19 stories, ~6 semanas de roadmap.

- [PRD completo](./docs/prd.md)
- [EPIC-01 Quick Wins](./docs/epics/EPIC-01-quick-wins.md) (1/4 done)
- [EPIC-02 Curadoria Power Tools](./docs/epics/EPIC-02-curadoria-power-tools.md)
- [EPIC-03 Intelligence & Integration](./docs/epics/EPIC-03-intelligence-integration.md)
- [EPIC-04 AI & Mobile](./docs/epics/EPIC-04-ai-mobile.md)

## Owner

Kaique Rodrigues — kaique@case
