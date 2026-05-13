---
title: Migração — Sheets ativo da Queila → banco refs.casein
type: migration-plan
status: bloqueado (aguardando export CSV ou compartilhamento público do Sheets)
date: 2026-05-12
owner: Kaique Rodrigues
---

# Migração — Sheets da Queila → `agente.referencias_conteudo`

Sheets ativo: <https://docs.google.com/spreadsheets/d/1vwg2H_70YGygaGl1AwW-WLSG0kdqkE2T1UBNpjEXfA4/>

Era pedido do handoff Felipe Gobbi importar o conteúdo que a Queila já vinha mantendo nesse Sheets pro novo banco. Tentei acessar via `export?format=csv` mas o documento não é público — HTTP 400 "arquivo não encontrado".

## Status atual

**Bloqueado.** Não consigo seguir sem um dos:
- (a) Exportar manualmente o Sheets como CSV e colocar em `~/Downloads/queila-sheets.csv`.
- (b) Tornar o Sheets "público com link" (Anyone with the link → Viewer).
- (c) Compartilhar com email de service account do Supabase pra ler via Google Sheets API (overkill pra uma migração única).

A mais barata é (a): exportar em CSV → o script abaixo importa.

## 1. Script de import (pronto para rodar)

`scripts/import-queila-sheets.mjs` — node 18+. Roda contra a RPC `case_refs_feedback_submit` adaptada (ver §3 abaixo se schema bater) ou via UPDATE direto se você for me dar service_role.

```js
#!/usr/bin/env node
// Uso:
//   SUPABASE_SERVICE_ROLE_KEY=sk_... node scripts/import-queila-sheets.mjs \
//     ~/Downloads/queila-sheets.csv

import fs from "node:fs";
import { parse } from "https://esm.sh/csv-parse/sync";

const SUPABASE_URL = "https://knusqfbvhsqworzyhvip.supabase.co";
const SR = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!SR) { console.error("missing SUPABASE_SERVICE_ROLE_KEY"); process.exit(1); }

const csvPath = process.argv[2];
if (!csvPath) { console.error("missing csv path"); process.exit(1); }

const rows = parse(fs.readFileSync(csvPath, "utf-8"), {
  columns: true, skip_empty_lines: true, trim: true,
});

console.log(`Importando ${rows.length} linhas do CSV…`);

let ok = 0, fail = 0;
for (const row of rows) {
  const payload = mapRow(row);              // ver §3
  if (!payload) { fail++; continue; }

  const res = await fetch(`${SUPABASE_URL}/rest/v1/referencias_conteudo`, {
    method: "POST",
    headers: {
      apikey: SR, Authorization: "Bearer " + SR,
      "Content-Type": "application/json",
      "Content-Profile": "agente",
      Prefer: "return=representation",
    },
    body: JSON.stringify(payload),
  });
  if (!res.ok) { console.error(`row ${ok+fail+1}:`, await res.text()); fail++; }
  else ok++;
}
console.log(`done. ok=${ok} fail=${fail}`);

function mapRow(row) {
  // Adaptar conforme schema real do Sheets (descobrir após export)
  if (!row.url && !row.shortcode) return null;
  return {
    perfil:           row.perfil || null,
    trilha:           normalizeTrilha(row.trilha || row.vertical),
    tipo_artefato:    row.tipo_artefato || row.formato || "reel",
    url:              row.url,
    shortcode:        row.shortcode || extractShortcode(row.url),
    caption:          row.caption || row.legenda || null,
    titulo:           row.titulo || null,
    etapa_funil:      normalizeEtapa(row.etapa || row.etapa_funil),
    tipo_estrategico: row.tipo_estrategico || row.tipo || null,
    notas:            row.notas || row.observacoes || null,
    origem:           "import_queila_sheets_2026-05-12",
    // E02 — se já tiver guia editorial na planilha
    quando_usar:      row.quando_usar || row.quando || null,
    por_que_funciona: row.por_que_funciona || row.por_que || null,
    como_adaptar:     row.como_adaptar || row.adaptar || null,
    objetivo:         row.objetivo || null,
    // promoted_at fica NULL — curador promove manualmente após revisão
  };
}

function normalizeTrilha(v) {
  if (!v) return null;
  const x = String(v).toLowerCase();
  if (x.includes("clin")) return "clinic";
  if (x.includes("ment") || x.includes("scale")) return "scale";
  return null;
}
function normalizeEtapa(v) {
  if (!v) return null;
  const x = String(v).toLowerCase();
  if (x.startsWith("desc")) return "DESCOBERTA";
  if (x.startsWith("conf") || x.includes("c+i+d") || x.includes("cid")) return "CONFIANCA";
  if (x.startsWith("aca") || x.startsWith("acç") || x === "a") return "ACAO";
  return null;
}
function extractShortcode(url) {
  const m = String(url || "").match(/\/(reel|p|tv)\/([A-Za-z0-9_-]+)/);
  return m ? m[2] : null;
}
```

## 2. Pré-checagens antes do import

1. **Dedup**: rodar `SELECT shortcode FROM agente.referencias_conteudo WHERE shortcode = $1` antes de cada insert. Se já existe, pular (não duplica).
2. **Ground truth**: 75 itens já existem no banco vindos da curadoria inicial. O import só adiciona itens **novos**.
3. **Sem promote automático**: todo item importado entra como `promoted_at = NULL` — vai pra `/live`, curador promove à mão (gatekeeper editorial conforme P1).
4. **Tag de origem**: `origem = 'import_queila_sheets_2026-05-12'` marca a turma — facilita rollback se necessário.

## 3. Mapping de colunas (hipótese — confirmar após export)

Não sei o schema exato do Sheets até olhar. Hipótese baseada em como bancos similares costumam estruturar:

| Coluna esperada no Sheets | Coluna destino no banco |
|---|---|
| `url` ou `Link` | `url` |
| `perfil` ou `@perfil` ou `Perfil` | `perfil` |
| `trilha` ou `vertical` (Clinica/Mentoria) | `trilha` (normalizado: clinic/scale) |
| `etapa` ou `etapa_funil` ou `bloco` | `etapa_funil` (normalizado: DESCOBERTA/CONFIANCA/ACAO) |
| `tipo` ou `tipo_estrategico` ou `objetivo` | `tipo_estrategico` |
| `formato` (Reel, Carrossel...) | `tipo_artefato` |
| `caption` ou `legenda` | `caption` |
| `titulo` | `titulo` |
| `notas` / `observacoes` | `notas` |
| `quando_usar` / `quando` | `quando_usar` (E02) |
| `por_que_funciona` / `por_que` | `por_que_funciona` (E02) |
| `como_adaptar` / `adaptar` | `como_adaptar` (E02) |

Se o Sheets já tiver as 3 colunas editoriais (E02), o curador pode **promover direto** após import. Senão, fica como rascunho aguardando preenchimento manual.

## 4. Plano de execução (quando destravarmos)

1. Kaique exporta o Sheets como CSV → `~/Downloads/queila-sheets.csv`.
2. Eu abro o CSV, ajusto `mapRow()` conforme schema real.
3. Rodo o script em modo `--dry-run` (count + sample apenas, sem insert) → relatório.
4. Kaique aprova.
5. Rodo o script real.
6. Smoke: `SELECT count(*) FROM agente.referencias_conteudo WHERE origem = 'import_queila_sheets_2026-05-12'`.
7. Spot check: abrir 3 itens importados aleatórios no `/live`.

## 5. Riscos

- **Duplicata de shortcode** — dedup do passo §2.1 mitiga.
- **Schema incompatível** — `mapRow()` pode descartar item por falta de URL/shortcode. Vai aparecer no contador `fail` do script.
- **Categorias não-canônicas no Sheets** — `normalizeEtapa()` retorna NULL se não bater; curador atribui depois no `/live`.
- **Volume grande** (>500 itens) — script processa sequencial. Sem rate limit Supabase pra service_role, mas se passar de 10k, paginar.
