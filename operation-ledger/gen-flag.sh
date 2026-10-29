#!/bin/bash
set -e

# Generate a fresh random 12-word recovery phrase into ./.flag.secret (the
# challenge flag). Run this once before building the release image so every
# deployment ships a unique phrase. .flag.secret is gitignored.
#
# Prefers a real BIP39 mnemonic (valid checksum) if the python `mnemonic`
# package is installed; otherwise falls back to a dependency-free random pick
# from a built-in wordlist subset (still 12 lowercase words, just not a
# checksummed BIP39 phrase).

OUT="$(dirname "$0")/.flag.secret"

phrase="$(python3 - <<'PY'
try:
    from mnemonic import Mnemonic
    print(Mnemonic("english").generate(strength=128))
except Exception:
    import secrets
    words = ("abandon ability able about above absorb abstract access account "
             "accuse achieve acid acoustic across action actor adapt add adjust "
             "admit adult advance advice aerobic affair afford afraid again agent "
             "agree ahead aim air airport aisle alarm album alert alien alley allow "
             "almost alone alpha already alter always amateur amazing among amount "
             "amused anchor ancient anger angle angry animal ankle announce annual "
             "answer antenna antique anxiety apart apology appear apple april arch "
             "arctic area arena argue armor army around arrange arrest arrive arrow "
             "art artist aspect assault asset assist assume asthma athlete atom "
             "attack attend auction audit august aunt author auto autumn average "
             "avocado avoid awake aware away awesome awful awkward axis").split()
    print(' '.join(secrets.choice(words) for _ in range(12)))
PY
)"

printf '%s' "$phrase" > "$OUT"
echo "[+] Wrote recovery phrase to $OUT"
echo "    $phrase"
