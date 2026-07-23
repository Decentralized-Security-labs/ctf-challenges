#!/bin/bash
set -e

# Helper to build Operation ECHO with the flag injected as a BuildKit
# secret. Requires ./.flag.secret to exist (gitignored).

IMAGE="ghcr.io/decentralized-security-labs/operation-echo"
VERSION="${1:-v1.0}"

if [ ! -f ./.flag.secret ]; then
  echo "ERROR: ./.flag.secret not found."
  echo "Create it with: echo -n 'CTF{your_flag}' > .flag.secret"
  exit 1
fi

echo "[*] Building ${IMAGE}:${VERSION} and ${IMAGE}:latest ..."
DOCKER_BUILDKIT=1 docker build \
  --secret id=flag,src=./.flag.secret \
  -t "${IMAGE}:latest" \
  -t "${IMAGE}:${VERSION}" \
  .

echo "[+] Done."
echo "    Run with: docker run -it -d --name operation-echo -p 80:80 ${IMAGE}:latest"
