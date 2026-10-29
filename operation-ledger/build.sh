#!/bin/bash
set -e

# Build Operation LEDGER from source locally (authors), with the flag injected
# into the db image as a BuildKit secret. Players do not need this: they run
# docker-compose.yml, which pulls prebuilt images.

cd "$(dirname "$0")"

if [ ! -f ./.flag.secret ]; then
  echo "ERROR: ./.flag.secret not found."
  echo "Create it with ./gen-flag.sh (or echo -n '<12 words>' > .flag.secret)."
  exit 1
fi

echo "[*] Building app + db from source via docker-compose.build.yml ..."
DOCKER_BUILDKIT=1 COMPOSE_DOCKER_CLI_BUILD=1 \
  docker compose -f docker-compose.build.yml build

echo "[+] Done."
echo "    Start with: docker compose -f docker-compose.build.yml up"
echo "    Then open:  http://localhost"
