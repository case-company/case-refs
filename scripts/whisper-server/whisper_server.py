#!/usr/bin/env python3
"""
Whisper HTTP server — recebe POST /transcribe com URL de áudio/vídeo,
baixa via ffmpeg, transcreve com Whisper, devolve JSON.

Uso (instalar na Hetzner ao lado do n8n):
    pip install openai-whisper fastapi uvicorn[standard]
    # ffmpeg system: apt install ffmpeg
    uvicorn whisper_server:app --host 127.0.0.1 --port 9999

Endpoint:
    POST http://localhost:9999/transcribe
    Content-Type: application/json
    Body: {"url": "https://...", "language": "pt", "model": "small"}

    Response:
        200 {"text": "...", "language": "pt", "duration_s": 60.2, "segments": [...]}
        4xx/5xx {"error": "..."}

n8n config: já vem apontado pra http://127.0.0.1:9999/transcribe.

Modelo carregado em memória na primeira request (lazy). Pra n8n cron
semanal isso é OK (1x na semana acorda o modelo). Pra warm sempre,
adicionar uvicorn --workers 1 + um warmup request no startup.
"""

import os, tempfile, subprocess, time, logging, threading
from typing import Optional
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import whisper

logging.basicConfig(level=logging.INFO, format='%(asctime)s %(levelname)s %(message)s')
log = logging.getLogger('whisper-server')

app = FastAPI(title='case-refs whisper server', version='1.0')

# Cache do modelo Whisper — só uma instancia por processo
_model_cache = {}
_model_lock = threading.Lock()

def get_model(name: str = 'small'):
    with _model_lock:
        if name not in _model_cache:
            log.info(f'Carregando Whisper modelo "{name}" pela primeira vez (pode demorar 30-60s)...')
            t0 = time.time()
            _model_cache[name] = whisper.load_model(name)
            log.info(f'Modelo "{name}" carregado em {time.time()-t0:.1f}s')
        return _model_cache[name]

class TranscribeRequest(BaseModel):
    url: str
    language: Optional[str] = 'pt'
    model: Optional[str] = 'small'  # tiny | base | small | medium | large

@app.get('/health')
def health():
    return {'ok': True, 'models_loaded': list(_model_cache.keys())}

@app.post('/transcribe')
def transcribe(req: TranscribeRequest):
    if not req.url or not (req.url.startswith('http://') or req.url.startswith('https://')):
        raise HTTPException(400, detail='invalid url')
    if req.model not in ('tiny', 'base', 'small', 'medium', 'large'):
        raise HTTPException(400, detail='invalid model')

    audio_path = None
    try:
        with tempfile.NamedTemporaryFile(suffix='.m4a', delete=False) as f:
            audio_path = f.name

        log.info(f'baixando {req.url[:80]}...')
        t0 = time.time()
        r = subprocess.run(
            ['ffmpeg', '-y', '-loglevel', 'error', '-i', req.url,
             '-vn', '-c:a', 'aac', audio_path],
            capture_output=True, timeout=180
        )
        if r.returncode != 0 or not os.path.exists(audio_path) or os.path.getsize(audio_path) < 1024:
            err = r.stderr.decode()[:300] if r.stderr else 'no audio produced'
            raise HTTPException(502, detail=f'ffmpeg failed: {err}')
        log.info(f'baixado em {time.time()-t0:.1f}s, tamanho {os.path.getsize(audio_path)} bytes')

        model = get_model(req.model)
        log.info(f'transcrevendo com Whisper {req.model}, lang={req.language}...')
        t0 = time.time()
        result = model.transcribe(audio_path, language=req.language, fp16=False, verbose=False)
        elapsed = time.time() - t0
        log.info(f'transcricao OK em {elapsed:.1f}s')

        dur = result.get('segments', [{}])[-1].get('end', 0) if result.get('segments') else 0

        return {
            'text': (result.get('text') or '').strip(),
            'language': result.get('language'),
            'duration_s': round(dur, 1),
            'transcribe_time_s': round(elapsed, 1),
            'segments': [
                {'start': s.get('start'), 'end': s.get('end'), 'text': s.get('text')}
                for s in result.get('segments', [])
            ]
        }
    except subprocess.TimeoutExpired:
        raise HTTPException(504, detail='ffmpeg timeout (>180s)')
    except HTTPException:
        raise
    except Exception as e:
        log.exception('erro inesperado')
        raise HTTPException(500, detail=str(e))
    finally:
        if audio_path and os.path.exists(audio_path):
            try: os.remove(audio_path)
            except: pass
