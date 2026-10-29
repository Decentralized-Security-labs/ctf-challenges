# syntax=docker/dockerfile:1.7
#
# LEDGER app image: nginx chat UI + FastAPI text-to-SQL agent + local Ollama.
# Build context is the challenge root (see docker-compose.yml) so this can
# COPY both app/ and frontend/. No flag is injected here; the flag lives on
# the db image.

FROM ollama/ollama:latest

# --- 1. System deps (rarely change) --------------------------------
RUN apt-get update && apt-get install -y \
    python3 python3-pip \
    nginx supervisor curl \
    && rm -rf /var/lib/apt/lists/*

# --- 2. Model (huge, almost never changes), kept HIGH so app -------
#        edits below never invalidate this cached layer.
#        MODEL_NAME must match the runtime MODEL_NAME env in compose.
ARG MODEL_NAME=qwen2.5-coder:1.5b
RUN ollama serve & \
    sleep 5 && \
    ollama pull ${MODEL_NAME} && \
    pkill ollama

# --- 3. Python deps (change occasionally) --------------------------
WORKDIR /opt/app
COPY app/requirements.txt .
RUN pip3 install --no-cache-dir --break-system-packages -r requirements.txt

# --- 4. App code + frontend + config (change often) ----------------
COPY app/ .
COPY frontend/ /var/www/html/
COPY app/nginx.conf /etc/nginx/sites-available/default

# --- 5. Process management ------------------------------------------
COPY app/supervisord.conf /etc/supervisor/conf.d/ctf.conf
COPY app/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

LABEL org.opencontainers.image.source="https://github.com/Decentralized-Security-labs/ctf-challenges"
LABEL org.opencontainers.image.title="Operation LEDGER"
LABEL org.opencontainers.image.description="DSEC Labs CTF - Tier 1 AI / text-to-SQL file read"

EXPOSE 80
ENTRYPOINT ["/entrypoint.sh"]
