---
title: "E03 — Onboarding do Cliente"
type: epic
status: code-complete (3 stories Done, S3 com placeholders aguardando Queila)
priority: P0
depends_on: [E01, E02]
estimated_stories: 4
date: 2026-05-12
owner: Kaique Rodrigues
---

# E03 — Onboarding do Cliente

## Objetivo

Criar a experiência de primeiro acesso para clientes da CASE, entregando a página `/como-usar.html` com explicação do método DECIDA, tour guiado do site e exemplos práticos de uso do banco de referências — eliminando a necessidade de onboarding verbal da Queila para cada novo cliente.

## Por que esse epic

Atualmente não existe nenhuma página cliente-facing explicando o método ou como navegar o site. Clientes entram e se perdem: não sabem filtrar por etapa DECIDA, não sabem o que o "Guia de uso" do card significa, não sabem quando pedir ao Agente 01 ou ao Agente 02. O custo disso é recaindo sobre a Queila em calls de onboarding repetitivas. O handoff Gobbi listou "Como usar" como P0 justamente porque sem essa página o banco de referências não é autossuficiente.

## Escopo

- Página estática `/como-usar.html` com: visão geral do método DECIDA (3 blocos + regra de mix), explicação do fluxo de curadoria, guia de uso de cada seção do site (`/trilhas`, `/live`, `/dashboard`)
- Componente de "tour do site": sequência de tooltips ou banners explicativos na primeira visita (baseado em localStorage flag, sem backend)
- Seção de exemplos práticos: ao menos 2 exemplos de post reais por bloco DECIDA (D+E, C+I+D, A), com screenshot ou descrição do conteúdo e anotação dos 3 campos editoriais
- Link "Como usar" adicionado no menu/navegação principal do site
- Referência ao `guia-decida.md` (E01) linkado na página

## Fora de escopo

- Autenticação ou área logada para clientes
- Vídeo tutorial (possível fase 2)
- Localização em outro idioma
- Integração com qualquer agente editorial

## Stories propostas

| ID | Título | Descrição |
|----|--------|-----------|
| S3.1-pagina-como-usar | Criar /como-usar.html | Página estática com estrutura: (1) O que é DECIDA, (2) Regra de mix 70/30/0-10, (3) Como navegar /trilhas, (4) O que são os campos editoriais, (5) Links para ferramentas. CSS consistente com o restante do site. |
| S3.2-tour-primeira-visita | Tour de primeira visita via localStorage | Implementar sequência de tooltips/banners que aparece uma vez para visitantes novos (flag `caso-ref-toured` no localStorage). Tour cobre: filtro por etapa, card expandido, badge de curadoria. |
| S3.3-exemplos-praticos | Seção de exemplos práticos na /como-usar | Adicionar ao menos 6 exemplos (2 por bloco DECIDA) mostrando: tipo de post, etapa, e como os 3 campos editoriais seriam preenchidos. Usar referências reais já presentes no banco. |
| S3.4-nav-link-como-usar | Adicionar link "Como usar" na navegação | Inserir link para `/como-usar.html` no menu presente em todas as páginas do site. |

## Critérios de aceite do Epic

1. `/como-usar.html` acessível e responsiva em mobile e desktop.
2. Tour aparece na primeira visita (localStorage limpo) e não reaparece após fechar (flag setada).
3. Pelo menos 6 exemplos práticos presentes, 2 por bloco DECIDA.
4. Link "Como usar" visível na navegação de todas as páginas.
5. Página referencia `guia-decida.md` com link funcional.
6. Nenhuma chamada de API ou Supabase na `/como-usar.html` — conteúdo 100% estático.

## Dependências técnicas

- E01 concluído (guia-decida.md disponível para linkar, vocabulário DECIDA travado)
- E02 concluído (campos editoriais existem para mostrar nos exemplos)
- CSS/design system existente do site (reutilizar classes e variáveis já em uso)
- localStorage (sem backend)

## Riscos

1. **Exemplos desatualizados**: se o banco mudar (itens removidos) os exemplos da página ficam desatualizados. Mitigação: usar screenshots/descrições estáticas em vez de fetch dinâmico de itens reais.
2. **Tour intrusivo**: tooltip mal posicionado pode quebrar UX em telas pequenas. Mitigação: testar em 375px (iPhone SE) antes de marcar story como concluída.
3. **Conteúdo escrito sem revisão da Queila**: exemplos e descrições do método precisam validação de quem ensina. Mitigação: incluir revisão da Queila como AC explícito da S3.3.

## Métrica de sucesso

Próximos 3 clientes onboardados não fazem perguntas básicas sobre "o que é DECIDA" ou "como filtrar" em call com a Queila (feedback coletado em call pós-acesso).
