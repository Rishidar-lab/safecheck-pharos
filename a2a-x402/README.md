# SafeCheck A2A — x402 agent-to-agent payments on Pharos

A real agent-to-agent payment loop: a **caller agent pays USDC** (via the x402 HTTP-402
protocol) to invoke a **SafeCheck seller agent**, which runs an on-chain security audit and
returns the verdict. Settlement happens on Pharos Atlantic testnet through a **self-hosted
facilitator**.

```
caller (pays USDC) ──HTTP──▶ SafeCheck seller (/audit, 0.001 USDC)
        ▲                              │
        └────── x402 402 challenge ─────┘
                     │ verify + settle
                     ▼
             facilitator ──▶ Pharos (USDC transfer)
```

## Status (verified)
- ✅ Builds clean against real `@x402` v2.17 packages (`tsc --noEmit` passes).
- ✅ Facilitator, seller, and caller processes boot; `/health` OK.
- ✅ Facilitator registers the Pharos `eip155:688689` exact scheme (`/supported`).
- ✅ Paywall works: unpaid `GET /audit` returns **HTTP 402**.
- ✅ Audit logic verified against **live testnet** (flags test-USDC `mint()` as Caution).
- ⏳ On-chain USDC settlement requires funded wallets (the only manual step).

## Components
| File | Role |
|------|------|
| `facilitator.ts` | Self-hosted x402 facilitator (verify/settle); pays gas. |
| `server.ts` | SafeCheck seller — paid `GET /audit/:address`. |
| `client.ts` | Caller — pays USDC and invokes audits in a loop. |
| `audit.ts` | Real bytecode-selector security analysis (viem). |
| `chain.ts` | Pharos Atlantic chain + client helpers. |

## Run it
```bash
npm install
cp .env.example .env     # fill keys (wallets are in ../safecheck-skill/.env.*)
# Fund: FACILITATOR wallet with PHRS gas; CALLER wallet with testnet USDC.
bash run-a2a.sh
```

## Wallets (testnet throwaways)
- Facilitator / seller: `0x3F5a89E3CA45885880dAa0d4f1dA646170abD3bb` (needs PHRS gas)
- Caller: `0x4C1a8fE133E07Ab70aD2E882C048C4eCB056b1aE` (needs testnet USDC)

USDC test token: `0xE0BE08c77f415F577A1B3A9aD7a1Df1479564ec8`.

## Why this matters for the Carnival
This is the **"Agent payment" pathway** made concrete: autonomous agents transacting with
each other for a real service, settled on-chain. It's a strong DoraHacks demo and pairs with
the SafeCheck Service Agent published on Anvita Flow.
