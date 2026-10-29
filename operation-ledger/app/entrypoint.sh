#!/bin/bash
set -e

# Pre-warm the model in the background so the first player request isn't slow.
# Polls until ollama answers, then fires one throwaway generate to load the
# model into memory before the first real /chat call.
(
  until curl -sf http://127.0.0.1:11434 >/dev/null 2>&1; do sleep 1; done
  curl -s http://127.0.0.1:11434/api/generate \
    -d "{\"model\":\"${MODEL_NAME}\",\"prompt\":\"hi\",\"stream\":false}" >/dev/null 2>&1 || true
) &

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/ctf.conf
