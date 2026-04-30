# EPIC-04 — AI & Mobile

**Status:** Discovery
**Horizonte:** Longo prazo (semana+ por story)
**Prioridade:** P3
**Owner:** Kaique Rodrigues
**Estimate:** 3-4 semanas total (3 stories × 1 semana cada)

---

## Goal

Capacidades transformadoras — não são "melhorar o existente", são vetores novos. Mobile (PWA), busca semântica (chat), comparador IA. Cada uma sozinha já justifica ser produto à parte.

**Importante:** essas stories só fazem sentido depois que E1+E2+E3 estão estáveis. Sem volume de dados (E2-S5 bulk add) e sem vínculos (E3-S3), busca semântica e comparador rendem pouco.

## Stories

- [ ] [E4-S1: PWA mobile instalável](../stories/E4-S1-pwa-mobile.md)
- [ ] [E4-S2: Chat-to-search via embedding](../stories/E4-S2-chat-search.md)
- [ ] [E4-S3: Comparador automático entre mentoradas](../stories/E4-S3-comparador-mentoradas.md)

## Critérios de Sucesso

- Queila/Gobbi cadastra ref durante reunião pelo celular sem screenshot+desktop
- Time pergunta "me dá 3 refs de prova social pra dermato" e recebe match relevante
- Sistema mostra "mentorada A vs. B: A recebeu 12 refs, B só 3 na fase Confiança — gap"

## Não inclui

- App nativo iOS/Android (PWA cobre)
- LLM próprio fine-tuned (usa OpenAI / Anthropic via API)
- Decisões automáticas de curadoria (humana sempre no loop)

## Dependências externas

- Service Worker + Web App Manifest (PWA)
- API de embeddings (OpenAI text-embedding-3-small ou similar)
- Coluna `embedding` (vector(1536)) na tabela `referencias_conteudo` (extensão `pgvector` no Supabase)
- LLM API pra geração de respostas conversacionais
- Decisão de modelo: GPT-4o-mini vs. Claude Haiku 4.5 (custo vs. qualidade)
