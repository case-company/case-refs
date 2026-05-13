---
title: Pipeline de Retroalimentação Semanal
type: spec-tech
status: design-complete
date: 2026-05-13
owner: Kaique Rodrigues
related:
  - fase-2-monitoramento-apis.md
  - 02-spec-tech.md
---

# Pipeline de Retroalimentação Semanal

> Cron semanal automatizado que coleta novas referências de top players, transcreve, classifica via LLM e enfileira em `/inbox` pra Queila aprovar. **Apify só coleta. LLM só sugere. Aprovação humana é obrigatória.**

## 1. Arquitetura

```
┌─────────────────────────────────────────────────────────────────────┐
│  CRON SEMANAL (n8n — domingo 06:00 BRT)                             │
└──────────────────┬──────────────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│  1. SEED — Lista de top players (DB + manual)                       │
│     SELECT perfil FROM v_referencias_promovidas                     │
│      WHERE perfil != 'desconhecido' AND quality_score >= 80         │
│      GROUP BY perfil ORDER BY count(*) DESC LIMIT 30                │
└──────────────────┬──────────────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│  2. APIFY — apify/instagram-profile-scraper                         │
│     Pra cada perfil: pega os 10 posts mais recentes                 │
│     + posts fixados + destaques (se houver)                         │
└──────────────────┬──────────────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│  3. FILTRO BRUTO — descarta lixo cedo                               │
│     - shortcode já existe no banco? → skip                          │
│     - timestamp_post > 365 dias atrás? → skip                       │
│     - likes < 500? → skip                                           │
│     - perfil + caption não bate keyword da trilha? → skip           │
└──────────────────┬──────────────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│  4. ENRICH — pra cada candidato sobrevivente:                       │
│     a. Baixa audio (apify videoUrl ou audioUrl)                     │
│     b. Whisper local (Mac mini Tailscale ou MacBook) transcreve     │
│     c. Calcula quality_score (heurística — ver §3)                  │
└──────────────────┬──────────────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│  5. CLASSIFICADOR LLM (Claude via subprocess `claude -p`)           │
│     Input: caption + transcricao + perfil + linha do método         │
│     Output JSON: {                                                  │
│       trilha: clinic | scale,                                       │
│       etapa_funil: DESCOBERTA | CONFIANCA | ACAO,                   │
│       tipo_estrategico: <uma das 10 linhas oficiais>,               │
│       objetivo: Atrair | Identificar | Desejo | Confiar | Vender,   │
│       quando_usar: "...",                                           │
│       por_que_funciona: "...",                                      │
│       como_adaptar: "...",                                          │
│       quality_score_editorial: 0-100                                │
│     }                                                               │
└──────────────────┬──────────────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│  6. POST → RPC public.case_refs_inbox_submit(p_items: JSONB[])      │
│     Servidor faz 4 validações finais (qualidade ≥ 60,               │
│     dedup, classificação obrigatória, conteúdo mínimo) e            │
│     insere os que passam como status='inbox'.                       │
└──────────────────┬──────────────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│  7. NOTIFICAÇÃO — Telegram/email pra Queila:                        │
│     "X novas refs no inbox (Y rejeitadas, ver /inbox-admin)"        │
└─────────────────────────────────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│  8. APROVAÇÃO HUMANA (Queila no /inbox-admin)                       │
│     - Aprovar → status: 'inbox' → 'publicado' (sai pra /trilhas)    │
│     - Descartar → status: 'descartado' (sai de tudo)                │
│     - Editar Guia de uso antes de aprovar (opcional)                │
└─────────────────────────────────────────────────────────────────────┘
```

## 2. Critérios pra entrar no inbox (filtros)

### 2.1 Filtros brutos (passo 3 — pré-LLM, barato)

| Critério | Threshold |
|---|---|
| Shortcode duplicado | reject |
| Idade do post | > 365 dias → reject |
| Engajamento mínimo | `likes >= 500` OU `views >= 10000` |
| Match de trilha | perfil ou caption precisa ter pelo menos 1 keyword de uma trilha |

**Keywords clinic** (para clínica/consultório): clinica, consultorio, paciente, medico, dermatologia, estetica, harmonizacao, lifting, botox, pele, tratamento, procedimento, dentista, odonto

**Keywords scale** (para mentoria): mentoria, mentorada, empreendedor, ticket, agenda, vendas, oferta, posicionamento, autoridade, lancamento, conteudo, instagram

### 2.2 Filtros server-side (passo 6 — case_refs_inbox_submit)

- `quality_score < 60` → reject
- `shortcode IS NULL AND url IS NULL` → reject
- duplicate → reject
- `caption < 30 chars AND transcricao < 50 chars` → reject (sem insumo)
- `etapa_funil IS NULL OR tipo_estrategico IS NULL` → reject (LLM falhou)

## 3. Quality Score (0-100)

Heurística pra ranking + filtro mínimo:

```
score = 0
+ 20 se likes >= 5000
+ 10 se likes >= 1000
+ 20 se views >= 50000
+ 10 se views >= 10000
+ 15 se transcricao tem >= 200 chars
+ 10 se caption tem >= 150 chars
+ 10 se perfil verificado (Apify retorna `verified`)
+ 10 se duration entre 30s e 180s (sweet spot reels)
+ 5  se já tem >= 5 hashtags no caption
= max 100
```

Refs abaixo de 60 viram lixo no filtro server-side.

## 4. Seed list — onde os top players moram

V1: **derivada do próprio banco** — perfis que já têm >= 2 refs promovidas com `quality_score >= 80`.

```sql
SELECT perfil, count(*) as n, max(quality_score) as best
  FROM agente.referencias_conteudo
 WHERE deleted_at IS NULL
   AND status = 'publicado'
   AND perfil != 'desconhecido'
 GROUP BY perfil
HAVING count(*) >= 2 AND max(quality_score) >= 80
 ORDER BY n DESC, best DESC
 LIMIT 30;
```

V1.5: complementa com lista manual da Queila salva em `agente.top_players_seed` (tabela futura).

V2: descobre players novos via análise de quem aparece em mentions/colabs nas refs atuais.

## 5. Custo estimado por execução semanal

| Item | Custo |
|---|---|
| Apify (30 perfis × 10 posts = 300 itens) | ~$0.45 (plan STARTER cobre) |
| Whisper local | $0 (Mac mini ou MacBook) |
| Claude API (300 classificações × 1500 tokens) | ~$1.50 (ou $0 se rodar via `claude -p` Max) |
| n8n self-host | $0 |
| **Total mensal** (4× = $7.80 ou $1.80) | < $10/mês |

## 6. Workflow n8n (vai em arquivo separado)

Export JSON do workflow completo em `pipeline-retroalimentacao.n8n.json` — importar via n8n UI.

Inclui:
- Cron trigger (`0 6 * * 0` — domingo 06:00)
- Postgres node (seed list)
- HTTP Request → Apify run-sync
- Code node (filtros brutos)
- HTTP Request → Whisper local (`http://100.102.33.48:9999/transcribe`)
- HTTP Request → Claude classificador
- HTTP Request → Supabase RPC `case_refs_inbox_submit`
- HTTP Request → Telegram bot notif

## 7. Variáveis de ambiente necessárias (n8n)

```
APIFY_TOKEN=apify_api_...
SUPABASE_URL=https://knusqfbvhsqworzyhvip.supabase.co
SUPABASE_SERVICE_ROLE=eyJ...
WHISPER_LOCAL_URL=http://100.102.33.48:9999/transcribe   (Tailscale)
ANTHROPIC_API_KEY=sk-ant-... (opcional — se quiser Claude direto)
TELEGRAM_BOT_TOKEN=... (opcional — pra notif)
TELEGRAM_CHAT_ID=... (Queila)
```

## 8. /inbox-admin (UI pra Queila aprovar)

Página `/inbox-admin.html` — lista refs em `status='inbox'` ordenadas por `quality_score DESC`:

- Card mostra: thumb, perfil, caption, transcrição, classificação LLM, quality_score
- 3 botões: **Aprovar** (vira publicado, aparece em `/trilhas`) · **Editar** (modal pra ajustar Guia antes de aprovar) · **Descartar** (vira descartado, some)
- Filtros: por trilha, por etapa DECIDA, por linha de conteúdo, por quality_score

Implementar como página HTML standalone (sem framework, padrão do site).

## 9. Critérios de aceite do epic E10

- [ ] Schema aplicado (Dashboard)
- [ ] 76 refs existentes têm `plataforma='instagram'` + `status='publicado'`
- [ ] Workflow n8n importado e armado no cron `0 6 * * 0`
- [ ] 1 execução manual de teste → ≥ 1 ref entra no inbox
- [ ] `/inbox-admin.html` no ar
- [ ] Queila aprova/descarta ≥ 3 refs do inbox de teste
- [ ] Notificação Telegram funcional
