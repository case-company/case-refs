#!/usr/bin/env bash
# Backfill das publicações (trilhas/live): re-POST de cada uma no webhook de
# ingest. UPSERT preserva curadoria humana e preenche transcrição/guia/thumb.
#
# Uso: ./backfill-pubs.sh pubs.txt
#   pubs.txt: linhas "shortcode|trilha|url"
set -uo pipefail

WEBHOOK="https://webhook.manager01.feynmanproject.com/webhook/fila-referencias-novos"
LISTA="${1:?informe o arquivo pubs.txt (linhas shortcode|trilha|url)}"
LOG="${LISTA%.txt}.log"

total=$(grep -c '|' "$LISTA")
i=0
while IFS='|' read -r sc trilha url; do
  [ -z "$sc" ] && continue
  i=$((i+1))
  echo "[$i/$total] $sc ($trilha) $(date +%H:%M:%S)" | tee -a "$LOG"
  resp=$(curl -s -m 400 -X POST "$WEBHOOK" -H "Content-Type: application/json" -d "{
    \"type\": \"publicacao\",
    \"url\": \"$url\",
    \"shortcode\": \"$sc\",
    \"trilha\": \"$trilha\",
    \"destino\": \"trilha\",
    \"origem\": \"backfill_zion_20260603\",
    \"created_at\": \"$(date -u +%Y-%m-%dT%H:%M:%S.000Z)\"
  }")
  echo "    resp: $(echo "$resp" | head -c 160)" | tee -a "$LOG"
  sleep 5
done < "$LISTA"
echo "FIM $(date +%H:%M:%S)" | tee -a "$LOG"
