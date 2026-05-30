# Repository Guide — case-refs

Este guia padroniza a operação deste repositório para passagem de bastão, manutenção segura e evolução sem quebrar interface ou produção.

## Identidade

- **Tipo:** `static-vercel-app`
- **Branch analisada:** `main`
- **Arquivos versionados detectados:** 725
- **Deploy/infra detectado:** Vercel/config estático ou frontend detectado.

## Setup Local

Instalação sugerida:

```bash
Sem instalação padrão detectada; ver README do repo.
```

Comandos conhecidos:

- Ver `README.md` e `docs/REPOSITORY_GUIDE.md` antes de rodar comandos.

## Estrutura de Configuração

Configs detectados:

`vercel.json`

Variáveis esperadas por exemplo/local:

Nenhuma variável declarada em `.env.example` foi detectada.

> Nunca coloque valores reais de segredos neste arquivo, no README, em screenshots ou em exemplos versionados. Documente apenas o nome da variável e guarde o valor no cofre oficial.

## Rotas e Pontos de Atenção

Arquivos de rota/API detectados no scan:

- `scripts/whisper-server/whisper_server.py`
- `supabase/functions/case-refs-mutate/index.ts`

## Regra de Ouro para Frontend

Para não quebrar front-end durante organização ou handoff:

- Não altere `src/`, `app/`, `pages/`, `components/`, `public/`, CSS, assets, `package.json`, lockfiles ou configs de build em PRs de organização.
- PRs de organização devem tocar apenas documentação, templates GitHub, ignores, metadados e guias.
- Qualquer mudança visual precisa de screenshot antes/depois, teste mobile/desktop e validação do fluxo principal.
- Se o repo usa Vercel/Lovable/Vite/Next, confirme que o build local continua passando antes de pedir review.

## Checklist de Pull Request

- [ ] Mudança classificada como docs/meta, frontend, backend, dados ou infra.
- [ ] Nenhum segredo real foi adicionado.
- [ ] Arquivos de runtime foram evitados quando a intenção era só organização.
- [ ] Build/test/lint aplicável foi rodado ou a impossibilidade foi documentada.
- [ ] Deploy e rollback foram considerados para mudanças de produção.
- [ ] Handoff atualizado quando a mudança altera operação, envs, deploy ou dados.

## Handoff

Antes de entregar este repo a outra pessoa, confirme:

- [ ] README indica o que o sistema faz e quem usa.
- [ ] `docs/REPOSITORY_GUIDE.md` está atual.
- [ ] Variáveis estão no cofre, não em docs.
- [ ] Deploy canônico está documentado.
- [ ] Owner de produto e owner técnico estão definidos.
- [ ] Riscos conhecidos estão em issue aberta ou documento de backlog.
