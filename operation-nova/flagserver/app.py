#!/usr/bin/env python3
"""Operation NOVA - flag server and NovaVault explorer.

Serves a small block-explorer-style UI, live vault state, the deployed
contract source, and the flag. The flag is released only once the vault
balance has been drained to exactly 0, which is reachable only through the
intended cross-function reentrancy exploit.

Only stdlib is used, so the image needs no Python dependencies.
"""
import json
import os
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

RPC_URL = os.environ.get("RPC_URL", "http://127.0.0.1:8545")
PORT = int(os.environ.get("PORT", "80"))
STATE_PATH = Path(os.environ.get("STATE_PATH", "/opt/flagserver/state.json"))
FLAG_PATH = Path(os.environ.get("FLAG_PATH", "/opt/flagserver/flag.txt"))
CONTRACT_PATH = Path(
    os.environ.get("CONTRACT_PATH", "/opt/flagserver/NovaVault.sol")
)
HERE = Path(__file__).resolve().parent

# Well-known anvil dev account #0, handed to the player so they never need
# to generate or fund a wallet. It is a throwaway local key by design and
# holds none of the seeded vault funds.
PLAYER_ADDRESS = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
PLAYER_KEY = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
CHAIN_ID = 31337


def rpc(method, params):
    payload = json.dumps(
        {"jsonrpc": "2.0", "id": 1, "method": method, "params": params}
    ).encode()
    req = urllib.request.Request(
        RPC_URL, data=payload, headers={"Content-Type": "application/json"}
    )
    with urllib.request.urlopen(req, timeout=10) as resp:
        return json.load(resp).get("result")


def load_state():
    try:
        return json.loads(STATE_PATH.read_text())
    except (OSError, ValueError):
        return {"ready": False}


def vault_balance(vault):
    return int(rpc("eth_getBalance", [vault, "latest"]), 16)


def is_solved(state):
    if not state.get("ready"):
        return False
    try:
        return vault_balance(state["vault"]) == 0
    except Exception:
        return False


def build_info():
    state = load_state()
    info = {
        "challenge": "Operation NOVA",
        "ready": bool(state.get("ready")),
        "rpc": "http://localhost:8545",
        "chainId": CHAIN_ID,
        "flagEndpoint": "http://localhost/flag",
        "player": {"address": PLAYER_ADDRESS, "privateKey": PLAYER_KEY},
    }
    if not info["ready"]:
        return info
    try:
        current = vault_balance(state["vault"])
        info.update(
            {
                "vault": state["vault"],
                "initialBalanceWei": str(state["initialBalanceWei"]),
                "currentBalanceWei": str(current),
                "solved": current == 0,
            }
        )
    except Exception:
        info["ready"] = False
    return info


class Handler(BaseHTTPRequestHandler):
    server_version = "NovaVaultExplorer"

    def log_message(self, *args):
        pass  # keep the container logs quiet

    def _send(self, code, body, content_type="application/json"):
        if isinstance(body, (dict, list)):
            body = json.dumps(body)
        data = body.encode() if isinstance(body, str) else body
        self.send_response(code)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        path = self.path.split("?", 1)[0]

        if path in ("/", "/index.html"):
            try:
                html = (HERE / "index.html").read_text()
            except OSError:
                return self._send(500, "explorer UI missing", "text/plain")
            return self._send(200, html, "text/html; charset=utf-8")

        if path == "/health":
            return self._send(200, {"status": "ok"})

        if path == "/api/info":
            return self._send(200, build_info())

        if path == "/api/source":
            try:
                source = CONTRACT_PATH.read_text()
            except OSError:
                source = "// contract source unavailable"
            return self._send(200, {"name": "NovaVault.sol", "source": source})

        if path == "/flag":
            state = load_state()
            if not state.get("ready"):
                return self._send(
                    503, {"solved": False, "message": "Challenge is still deploying. Try again in a moment."}
                )
            if not is_solved(state):
                return self._send(
                    403,
                    {
                        "solved": False,
                        "message": "Vault still solvent. Drain it to exactly 0, then come back.",
                    },
                )
            try:
                flag = FLAG_PATH.read_text().strip()
            except OSError:
                flag = "CTF{flag_file_missing_build_with_the_buildkit_secret}"
            return self._send(200, {"solved": True, "flag": flag})

        return self._send(404, {"error": "not found"})


def main():
    server = ThreadingHTTPServer(("0.0.0.0", PORT), Handler)
    print(f"[flagserver] listening on :{PORT}, RPC {RPC_URL}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
