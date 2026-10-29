# syntax=docker/dockerfile:1.7
#
# SQL Server for Linux with the reporting database seeded at first start and
# the wallet backup file (holds the flag) written at build time.
#
# The mssql server image does not ship sqlcmd, so we install mssql-tools18 to
# seed the database from entrypoint.sh.
#
# NOTE: this image is amd64-only (no arm64 base). It runs under emulation on
# Apple Silicon.

FROM mcr.microsoft.com/mssql/server:2022-latest

# --- tools + sqlcmd (need root) ------------------------------------
USER root
RUN apt-get update && apt-get install -y curl gnupg2 apt-transport-https \
    && curl -sSL https://packages.microsoft.com/keys/microsoft.asc \
         -o /etc/apt/trusted.gpg.d/microsoft.asc \
    && curl -sSL https://packages.microsoft.com/config/ubuntu/22.04/prod.list \
         -o /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y mssql-tools18 \
    && rm -rf /var/lib/apt/lists/*

# --- seed script + entrypoint --------------------------------------
COPY init.sql /usr/src/init.sql
COPY entrypoint.sh /usr/src/entrypoint.sh
RUN chmod +x /usr/src/entrypoint.sh

# --- flag -> wallet key file (build-time secret, never a layer) ----
COPY wallet.key.template /usr/src/wallet.key.template
RUN --mount=type=secret,id=flag \
    mkdir -p /secrets && \
    FLAG="$(cat /run/secrets/flag)" && \
    sed "s|__FLAG__|${FLAG}|" /usr/src/wallet.key.template > /secrets/whale_047.key && \
    rm -f /usr/src/wallet.key.template && \
    chown -R mssql:root /secrets && \
    chmod 700 /secrets && chmod 600 /secrets/whale_047.key && \
    unset FLAG

LABEL org.opencontainers.image.source="https://github.com/Decentralized-Security-labs/ctf-challenges"
LABEL org.opencontainers.image.title="Operation LEDGER (db)"
LABEL org.opencontainers.image.description="DSEC Labs CTF - Tier 1 AI / SQL Server backend"

# sqlservr must run as the non-root mssql user.
USER mssql
ENTRYPOINT ["/usr/src/entrypoint.sh"]
