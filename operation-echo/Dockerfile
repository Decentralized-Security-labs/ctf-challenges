# syntax=docker/dockerfile:1.7
# ^ enables BuildKit secret mounts (required for flag injection)

FROM ollama/ollama:latest

# --- 1. System deps (rarely change) --------------------------------
RUN apt-get update && apt-get install -y \
    python3 python3-pip \
    nginx supervisor curl \
    && rm -rf /var/lib/apt/lists/*

# --- 2. Model (huge, almost never changes) — kept HIGH so app -------
#        edits below never invalidate this ~2GB cached layer.
RUN ollama serve & \
    sleep 5 && \
    ollama pull llama3.2:3b && \
    pkill ollama

# --- 3. Python deps (change occasionally) --------------------------
WORKDIR /opt/app
COPY app/requirements.txt .
RUN pip3 install --no-cache-dir --break-system-packages -r requirements.txt

# --- 4. App code + frontend (change often) -------------------------
COPY app/ .
COPY frontend/ /var/www/html/
COPY nginx.conf /etc/nginx/sites-available/default

# --- 5. Flag injection (changes when rotating the flag) — LOWEST ----
#        BuildKit secret is mounted ONLY during this RUN and is not
#        persisted into any layer or into `docker history`.
RUN --mount=type=secret,id=flag \
    FLAG="$(cat /run/secrets/flag)" && \
    sed "s|__FLAG__|${FLAG}|" \
        /opt/app/system_prompt.template.txt \
        > /opt/app/system_prompt.txt && \
    unset FLAG

# --- 6. Process management ------------------------------------------
COPY supervisord.conf /etc/supervisor/conf.d/ctf.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

LABEL org.opencontainers.image.source="https://github.com/Decentralized-Security-labs/ctf-challenges"
LABEL org.opencontainers.image.title="Operation ECHO"
LABEL org.opencontainers.image.description="DSEC Labs CTF — Tier 0 AI / prompt injection"

EXPOSE 80
ENTRYPOINT ["/entrypoint.sh"]
