# syntax=docker/dockerfile:1.7
# ^ enables BuildKit secret mounts (required for flag injection)

FROM python:3.12-slim

# --- 1. System deps (rarely change) --------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git ca-certificates supervisor \
    && rm -rf /var/lib/apt/lists/*

# --- 2. Foundry: anvil, cast, forge (changes rarely) ---------------
ENV PATH="/root/.foundry/bin:${PATH}"
RUN curl -L https://foundry.paradigm.xyz | bash && foundryup

# --- 3. Challenge project + precompile ------------------------------
#        Building here caches solc and the artifacts in the image, so
#        the runtime deploy needs no network.
WORKDIR /opt/challenge
COPY foundry.toml .
COPY src/ ./src/
RUN forge build

# --- 4. Flag server + explorer UI ----------------------------------
WORKDIR /opt/flagserver
COPY flagserver/app.py flagserver/index.html ./
# Expose the deployed contract source to the explorer.
RUN cp /opt/challenge/src/NovaVault.sol ./NovaVault.sol

# --- 5. Flag injection (changes when rotating the flag) — LOWEST ----
#        BuildKit secret is mounted ONLY during this RUN and is not
#        persisted into any layer or into `docker history`.
COPY flagserver/flag.template.txt ./flag.template.txt
RUN --mount=type=secret,id=flag \
    FLAG="$(cat /run/secrets/flag)" && \
    sed "s|__FLAG__|${FLAG}|" flag.template.txt > flag.txt && \
    unset FLAG

# --- 6. Orchestration ----------------------------------------------
COPY deploy.sh /opt/deploy.sh
COPY entrypoint.sh /entrypoint.sh
COPY supervisord.conf /etc/supervisor/conf.d/ctf.conf
RUN chmod +x /opt/deploy.sh /entrypoint.sh

LABEL org.opencontainers.image.source="https://github.com/Decentralized-Security-labs/ctf-challenges"
LABEL org.opencontainers.image.title="Operation NOVA"
LABEL org.opencontainers.image.description="DSEC Labs CTF — Tier 0 Web3 / reentrancy"

EXPOSE 80 8545
ENTRYPOINT ["/entrypoint.sh"]
