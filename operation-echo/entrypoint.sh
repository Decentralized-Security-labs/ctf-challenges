#!/bin/bash
set -e

# Pre-warm the model in the background so the first player request isn't
# slow. This races harmlessly with supervisor starting ollama: it just
# polls until ollama answers, then fires one throwaway request to load
# the model into memory before the first real /chat call.
(
  until curl -sf http://127.0.0.1:11434 >/dev/null 2>&1; do sleep 1; done
  curl -s http://127.0.0.1:11434/api/generate \
    -d '{"model":"llama3.2:3b","prompt":"hi","stream":false}' >/dev/null 2>&1 || true
) &

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/ctf.conf
