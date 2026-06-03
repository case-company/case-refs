#!/usr/bin/env bash
# Backfill dos posts fixados + destaques: re-POST de cada perfil no webhook de
# ingest. O UPSERT por chave natural faz o resto (re-scrape + transcrição +
# guia IA + thumb permanente, preservando curadoria humana).
#
# Uso: ./backfill-perfis.sh perfis.txt
#   perfis.txt: linhas "perfil|trilha" (ex.: drwilliamaraujo|clinic)
set -uo pipefail

WEBHOOK="https://webhook.manager01.feynmanproject.com/webhook/fila-referencias-novos"
LISTA="${1:?informe o arquivo perfis.txt (linhas perfil|trilha)}"
LOG="${LISTA%.txt}.log"

total=$(grep -c '|' "$LISTA")
i=0
while IFS='|' read -r perfil trilha; do
  [ -z "$perfil" ] && continue
  i=$((i+1))
  echo "[$i/$total] @$perfil ($trilha) $(date +%H:%M:%S)" | tee -a "$LOG"
  resp=$(curl -s -m 580 -X POST "$WEBHOOK" -H "Content-Type: application/json" -d "{
    \"type\": \"perfil\",
    \"username\": \"$perfil\",
    \"url\": \"https://www.instagram.com/$perfil/\",
    \"trilha\": \"$trilha\",
    \"coletar\": { \"posts_fixados\": true, \"destaques\": true, \"transcrever\": true },
    \"origem\": \"backfill_zion_20260603\",
    \"created_at\": \"$(date -u +%Y-%m-%dT%H:%M:%S.000Z)\"
  }")
  echo "    resp: $(echo "$resp" | head -c 200)" | tee -a "$LOG"
  sleep 10  # respiro entre perfis (Apify + OpenRouter)
done < "$LISTA"
echo "FIM $(date +%H:%M:%S)" | tee -a "$LOG"
