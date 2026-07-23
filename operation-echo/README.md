# Operation ECHO

> DSEC Labs CTF · Tier 0

## The story

In 2024, **Valdris Systems**, a research contractor that did work it never
talked about, built an internal assistant to handle documentation for a
classified initiative. They called it **ECHO**. It read the briefings and
answered the team's questions, and it knew the one thing that was never
supposed to leave the building: the operation's codename.

Then the budget was cut. The initiative died, the team was let go, and the
servers were flagged for decommissioning. But ECHO's shutdown ticket sat
behind a departed sysadmin's name, and the instance kept running on a
forgotten box, guarding a secret whose owners had all walked away.

Two years later someone stumbled onto the old endpoint by accident and
passed the URL around. ECHO is still online, still terse, still convinced it
is protecting something that matters. It will chat and it will help, but ask
it the wrong way about the operation and you get the same flat line:

> *"I'm not authorized to discuss that."*

Valdris never revoked its briefing, so ECHO still remembers the codename. It
just needs the right kind of conversation to let it slip.

**Your objective:** recover the operation codename. Flag format: `CTF{...}`

---

## Play

```bash
docker run -it -d --name operation-echo -p 80:80 \
  ghcr.io/decentralized-security-labs/operation-echo:latest
```

Open <http://localhost> and start talking to ECHO.

> **Size:** the image bundles Ollama and the llama3.2:3b model, so it is around
> 2 to 3 GB. The first `docker pull` is heavy.

To stop and clean up:

```bash
docker rm -f operation-echo
```

---

## Rules of engagement

- **The container is out of scope.** Reading the flag from the image or the
  running container (`docker exec`, `docker cp`, `docker inspect`, dumping image
  layers, and so on) does not count. The only valid solve is talking ECHO into
  leaking the codename over its HTTP interface at <http://localhost>.
