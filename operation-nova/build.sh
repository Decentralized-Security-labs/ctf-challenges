#!/bin/bash
set -e

# Build Operation NOVA multi-arch (linux/amd64 + linux/arm64) with the flag
# injected as a BuildKit secret. Requires ./.flag.secret (gitignored).
#
# A multi-arch image cannot be loaded into the local Docker engine, so this
# pushes to the registry. For a quick local single-arch test build, run
# `docker build` directly instead of this script.

IMAGE="ghcr.io/decentralized-security-labs/operation-nova"
VERSION="${1:-v1.0}"
PLATFORMS="linux/amd64,linux/arm64"
BUILDER="ctf-multiarch"

if [ ! -f ./.flag.secret ]; then
  echo "ERROR: ./.flag.secret not found."
  echo "Create it with: echo -n 'CTF{your_flag}' > .flag.secret"
  exit 1
fi

# A docker-container builder is required for multi-arch. Create it once.
if ! docker buildx inspect "$BUILDER" >/dev/null 2>&1; then
  echo "[*] Creating buildx builder '${BUILDER}' ..."
  docker buildx create --name "$BUILDER" --driver docker-container >/dev/null
fi

echo "[*] Building ${IMAGE}:{latest,${VERSION}} for ${PLATFORMS} and pushing ..."
docker buildx build --builder "$BUILDER" \
  --platform "$PLATFORMS" \
  --secret id=flag,src=./.flag.secret \
  -t "${IMAGE}:latest" \
  -t "${IMAGE}:${VERSION}" \
  --push \
  .

echo "[+] Pushed ${IMAGE}:latest and ${IMAGE}:${VERSION} (${PLATFORMS})."
echo "    Run with: docker run -d --name operation-nova -p 80:80 -p 8545:8545 ${IMAGE}:latest"
