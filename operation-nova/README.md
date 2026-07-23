# Operation NOVA

> DSEC Labs CTF · Tier 0

## The story

Before **NovaChain Labs** became known for its flagship protocol, it shipped
something much smaller: **NovaVault**, an early ETH staking vault with a loyalty
rewards feature. It went out to a public testnet in 2023 as a proof of concept,
the kind of thing a team builds in two weeks to show an idea works. Then the team
moved on to bigger money, and nobody ever took it down.

It is still live. It still holds real deposits from a handful of early users who
never withdrew, and it still runs the exact code that shipped that year, audited
by nobody. The withdrawal path looks careful. There is a reentrancy guard on it,
the balance is written before the transfer, all the boxes an auditor checks in the
first thirty seconds. Whoever wrote it had read the classic writeups.

They just did not read them twice. A second feature got bolted on after launch to
pay a loyalty bonus, and it was waved through as low risk because it only hands out
a small reward, not anyone's principal. Nobody looked at how it moved money.

**Your objective:** empty NovaVault. Drain every last wei of the ETH it holds. Flag
format: `CTF{...}`

## Play

```bash
docker run -d --name operation-nova \
  -p 80:80 -p 8545:8545 \
  ghcr.io/decentralized-security-labs/operation-nova:latest
```

Two ports come up:

- **`:80`** is the NovaVault explorer. Open <http://localhost> for the vault
  address, a pre-funded attacker account, the live balance, the deployed contract
  source, and a **Get flag** button.
- **`:8545`** is the anvil RPC. Point `cast`, Foundry, ethers, or any wallet at it.

Give the container a few seconds on first start. It spins up the chain, deploys the
vault, and seeds it before the explorer shows `live`.

To stop and clean up:

```bash
docker rm -f operation-nova
```

## Rules of engagement

- You do not need any privileged anvil RPCs.
- **The container is out of scope.** Reading the flag from the image or the running
  container (`docker exec`, `docker cp`, `docker inspect`, dumping image layers, and
  so on) does not count. The flag releases only when the vault balance on the RPC is 0.
