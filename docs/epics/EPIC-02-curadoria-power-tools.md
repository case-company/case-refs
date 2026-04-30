# EPIC-02 — Curadoria Power Tools

**Status:** Ready
**Horizonte:** Curto prazo (horas por story)
**Prioridade:** P1
**Owner:** Kaique Rodrigues
**Estimate:** 2-3 dias total (6 stories × 2-4h cada)

---

## Goal

Reduzir fricção do uso diário com 6 power tools que transformam o banco de "lista de refs" em ferramenta de trabalho. Foco: time gasta tempo USANDO refs, não procurando/copiando/colando.

## Stories

- [ ] [E2-S1: Compartilhamento de card via deep-link](../stories/E2-S1-deep-link-card.md)
- [ ] [E2-S2: Cópia de transcrição com 1 clique](../stories/E2-S2-copia-transcricao.md)
- [ ] [E2-S3: Filtro por data customizada (range)](../stories/E2-S3-filtro-data-custom.md)
- [ ] [E2-S4: Tag livre por card](../stories/E2-S4-tag-livre.md)
- [ ] [E2-S5: Bulk add (20 links de uma vez)](../stories/E2-S5-bulk-add.md)
- [ ] [E2-S6: Notificação quando processamento termina](../stories/E2-S6-notificacao-processamento.md)

## Critérios de Sucesso

- Compartilhar uma ref específica vira ato de 1 clique (botão → link copiado)
- Transcrição de qualquer ref vai pro clipboard sem abrir modal
- Curador filtra por data específica ("entre 15/04 e 20/04") em <5s
- Tags humanas convivem com classificações automáticas
- Adicionar 20 perfis ao mesmo tempo sem repetir 20× o formulário
- Curador sabe quando processo terminou sem ficar dando F5

## Não inclui

- Edição em massa de tags (bulk tag edit) — fica em E3
- Sugestão automática de tags — fica em E4 (chat-to-search)
- Compartilhamento por email/WhatsApp direto — usuário copia link

## Dependências externas

- Endpoint n8n `/bulk-add` (criar)
- Coluna `tags` (jsonb[]) na tabela `referencias_conteudo` (Supabase migration)
- Browser Notifications API (suportado em todos navegadores modernos)
