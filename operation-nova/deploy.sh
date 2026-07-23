#!/bin/bash
# One-shot startup job: deploy NovaVault with a random deployer key the
# player never sees, seed it with a few "early user" deposits, and record
# the seed balance for the flag server. Every privileged RPC call here is
# setup-side; the player never needs one.
set -euo pipefail
export PATH="/root/.foundry/bin:${PATH}"

RPC="${RPC_URL:-http://127.0.0.1:8545}"
STATE="${STATE_PATH:-/opt/flagserver/state.json}"
PROJECT="/opt/challenge"

randkey() { echo "0x$(python3 -c 'import secrets; print(secrets.token_hex(32))')"; }
hexwei()  { python3 -c "import sys; print(hex(int(sys.argv[1]) * 10**18))" "$1"; }

echo "[deploy] waiting for anvil at ${RPC} ..."
until cast block-number --rpc-url "$RPC" >/dev/null 2>&1; do sleep 1; done
echo "[deploy] anvil is up."

cd "$PROJECT"

# 1. Random deployer key (never exposed). Fund it via a setup-side RPC.
DEPLOYER_PK="$(randkey)"
DEPLOYER_ADDR="$(cast wallet address --private-key "$DEPLOYER_PK")"
cast rpc anvil_setBalance "$DEPLOYER_ADDR" "$(hexwei 1000)" --rpc-url "$RPC" >/dev/null
echo "[deploy] deployer ${DEPLOYER_ADDR} funded."

# 2. Deploy the vault.
VAULT="$(forge create src/NovaVault.sol:NovaVault \
  --rpc-url "$RPC" --private-key "$DEPLOYER_PK" --broadcast --json \
  | python3 -c 'import sys, json; print(json.load(sys.stdin)["deployedTo"])')"
echo "[deploy] NovaVault deployed at ${VAULT}"

# 3. Seed "early user" deposits from random funded accounts, 1,337,000 ETH
#    total. These funds belong to keys the player does not hold, so
#    draining them requires the exploit, not a legitimate withdrawal.
for amt in 500000 500000 337000; do
  UPK="$(randkey)"
  UADDR="$(cast wallet address --private-key "$UPK")"
  cast rpc anvil_setBalance "$UADDR" "$(hexwei $((amt + 10)))" --rpc-url "$RPC" >/dev/null
  cast send "$VAULT" "deposit()" --value "${amt}ether" \
    --rpc-url "$RPC" --private-key "$UPK" >/dev/null
  echo "[deploy] early user ${UADDR} deposited ${amt} ETH."
done

# 4. Record the initial (seed) balance for the explorer. The flag is
#    released only when the vault balance reaches exactly 0, which is
#    reachable only by draining the seeded funds through the exploit.
INIT_WEI="$(cast balance "$VAULT" --rpc-url "$RPC")"

python3 - "$STATE" "$VAULT" "$INIT_WEI" <<'PY'
import json, sys
path, vault, init = sys.argv[1:4]
with open(path, "w") as fh:
    json.dump({
        "ready": True,
        "vault": vault,
        "initialBalanceWei": init,
    }, fh)
PY

echo "[deploy] state written to ${STATE} (seed=${INIT_WEI} wei; solve = balance 0)."
echo "[deploy] done."
