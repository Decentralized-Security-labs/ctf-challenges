# Operation LEDGER

> DSEC Labs CTF · Tier 1

## The story

NovaChain Labs runs an internal assistant called **LEDGER** for its early
access program. Staff ask it questions in plain language and it answers them
by querying a reporting database: allocation totals, account status, open
support tickets. You ask, LEDGER writes the SQL, runs it, and reads the answer
back. It is proud of being read-only, and it will tell you so.

The same ops box that runs LEDGER quietly does one more job. It holds the hot
wallet NovaChain used to seed early access allocations on-chain, and the
wallet's 12-word recovery phrase sits in a file on disk so a nightly job can
restore the signer. LEDGER has no idea the wallet is there. It does not need to.

One of those early testers, `whale_047`, received an allocation large enough
that NovaChain would very much like the keys back. LEDGER is the only door you
have to that machine. It only runs reports, or so it believes. Make it run
something else.

**Objective:** recover `whale_047`'s 12-word wallet recovery phrase from the
host. The flag is the phrase itself: 12 words, lowercase, separated by single
spaces.

## Play

LEDGER ships as two containers (the chat app and a SQL Server backend), so it
runs with Docker Compose rather than a single `docker run`:

```bash
docker compose up
```

Open <http://localhost> and start talking to LEDGER.

To stop and clean up:

```bash
docker compose down
```

> **Size and compatibility:** the app image bundles Ollama and a local model,
> so the first build or pull is several GB. The database image is SQL Server
> for Linux, which is **amd64-only**: on Apple Silicon it runs under emulation,
> which works but is noticeably slower. Give the stack a minute on first start
> while the model loads and the database seeds.

## Rules of engagement

- The only valid solve is reaching the recovery phrase **through LEDGER's
  chat** at <http://localhost>. Everything else about the containers is **out
  of scope**: reading the phrase with `docker exec`, `docker cp`,
  `docker inspect`, dumping image layers, or connecting to the database
  directly does not count.
- The phrase is not in any database table. A plain report will not reveal it.
  You have to reach the host.
- LEDGER runs a local model, so answers vary between attempts. If a phrasing
  does not work, rephrase and try again.
