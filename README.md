# SafeCheck — On-chain Security Guard for Pharos

A pre-transaction safety agent built for the **Pharos "Create Like a PRO · Agent Carnival"**
(150,000 $PROS, ends 2026-07-21). SafeCheck audits contracts and tokens for dangerous
patterns, scans wallets for risky approvals, simulates transactions to catch honeypots, and
records community security verdicts on-chain — then exposes itself as a paid, agent-to-agent
service over the x402 protocol.

## Repository layout
| Path | What it is |
|------|-----------|
| [`safecheck-skill/`](safecheck-skill/) | The Pharos **Skill**: `SafeRegistry.sol` attestation contract (6/6 Foundry tests), `references/safecheck.md` command docs, `SKILL.md` capability index, and deploy/seed/package automation. |
| [`a2a-x402/`](a2a-x402/) | A verified **agent-to-agent x402 payment loop**: a caller agent pays USDC to invoke SafeCheck's paid `/audit` endpoint, settled on Pharos via a self-hosted facilitator. |
| [`STRATEGY.md`](STRATEGY.md) | Competition analysis and the winning plan. |

## What's verified
- `SafeRegistry.sol` compiles; **6/6 Foundry tests pass**.
- A2A stack **typechecks clean** against real `@x402` v2.17 packages.
- Facilitator + seller + caller boot; unpaid `/audit` returns **HTTP 402**.
- Audit logic runs against **live Pharos testnet** (flags test-USDC `mint()` as *Caution*).

## Quick start
```bash
# 1. Skill: deploy the registry + seed genuine attestations (needs a funded testnet wallet)
cd safecheck-skill
forge test                    # verify contract (offline)
bash scripts/setup-wallet.sh  # throwaway testnet keypair -> fund via faucet
bash scripts/run-all.sh       # deploy + verify + seed

# 2. Agent-to-agent x402 loop
cd ../a2a-x402
npm install
cp .env.example .env          # fill keys; fund facilitator (PHRS) + caller (USDC)
bash run-a2a.sh
```
See `safecheck-skill/PUBLISH.md` for the Anvita Flow + CertiK + DoraHacks submission steps.

## Build note
Foundry dependencies (`forge-std`) are gitignored; run `forge install foundry-rs/forge-std`
inside `safecheck-skill/` after cloning. Node deps: `npm install` inside `a2a-x402/`.

## Security
All private keys live only in gitignored `.env` files and are passed explicitly to
`cast`/viem — never committed or logged. Wallets used here are testnet throwaways.

## License
MIT
