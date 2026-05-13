# Whisper server na Hetzner (VPS do n8n)

Instalação 1-vez. Depois fica subindo no boot.

## 1. SSH na VPS

```bash
ssh root@<IP_DA_VPS_N8N>
```

## 2. Dependências sistema

```bash
apt update
apt install -y ffmpeg python3-pip python3-venv
```

## 3. Criar ambiente Python isolado

```bash
mkdir -p /opt/whisper-server
cd /opt/whisper-server
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install openai-whisper fastapi 'uvicorn[standard]'
```

> Whisper baixa ~1GB de PyTorch + ~500MB de modelo `small` na primeira chamada. Conta com ~3-4GB de espaço em disco.

## 4. Copiar o servidor

```bash
# do seu MacBook (kaiquerodrigues):
scp ~/Downloads/case-references/scripts/whisper-server/whisper_server.py root@<IP_VPS>:/opt/whisper-server/
```

## 5. Smoke test manual

```bash
cd /opt/whisper-server
source venv/bin/activate
uvicorn whisper_server:app --host 127.0.0.1 --port 9999 &
sleep 5

# em outro shell, testa:
curl -X POST http://127.0.0.1:9999/transcribe \
  -H "Content-Type: application/json" \
  -d '{"url":"https://www.instagram.com/p/<algum_shortcode_publico>/","language":"pt","model":"small"}'

# espera 30-60s na primeira chamada (carrega modelo)
```

Se voltar `{"text": "...", "language": "pt", ...}` → OK.

## 6. systemd unit (sobe no boot)

```bash
cat > /etc/systemd/system/whisper-server.service <<'EOF'
[Unit]
Description=case-refs Whisper transcription HTTP server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/whisper-server
ExecStart=/opt/whisper-server/venv/bin/uvicorn whisper_server:app --host 127.0.0.1 --port 9999
Restart=on-failure
RestartSec=10
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable whisper-server
systemctl start whisper-server
systemctl status whisper-server
```

## 7. Logs

```bash
journalctl -u whisper-server -f
```

## 8. Firewall: NÃO abrir porta 9999 pro mundo

O server escuta em `127.0.0.1:9999` (só localhost). n8n na mesma VPS bate em `http://localhost:9999/transcribe` sem expor publicamente.

Se quiser checar do MacBook por curiosidade, faz SSH tunnel:
```bash
ssh -L 9999:127.0.0.1:9999 root@<IP_VPS>
# em outra aba: curl http://localhost:9999/health
```

## 9. Custo

- CPU: a inferência Whisper small CPU usa ~2-3GB RAM e 1 core full por ~3-10s por minuto de áudio.
- Pra cron semanal com 20-50 reels × ~60s áudio cada = 20-50min de processamento.
- Roda 1x por semana. Resto do tempo o processo fica idle consumindo ~200MB RAM (modelo carregado).
- Se a VPS é compartilhada com n8n + outros, agendar o cron pra horário de menor uso (sugestão: domingo 06:00 BRT).

## 10. Teste E2E do n8n → Whisper

Quando o workflow n8n estiver importado e env vars configuradas, dispara 1 run manual e confere se:
- Apify retorna posts (n8n logs)
- Whisper devolve transcrição não-vazia
- inbox_submit retorna `inserted_count >= 1`

Pronto.
