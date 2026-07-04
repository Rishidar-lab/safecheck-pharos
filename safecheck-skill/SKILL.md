---
name: safecheck-skill
description: >
  On-chain security guard for the Pharos network. Use this skill BEFORE a user signs any
  transaction or approves any token. It audits a contract or token address for dangerous
  patterns (mintable, pausable, blacklist/honeypot, active owner), scans a wallet for risky
  unlimited ERC20 approvals and revokes them, simulates a transaction to catch reverts and
  honeypots before spending gas, and records/reads security verdicts on-chain via the
  SafeRegistry contract. Invoke whenever the user mentions "is this safe", "audit", "check
  this contract/token", "honeypot", "approvals", "revoke", "am I about to get drained",
  "simulate", "rug", "safecheck", or wants a security opinion on a Pharos ("PHRS"/"PROS",
  "atlantic-testnet") address before interacting with it.
version: 0.1.0
requires:
  anyBins:
  - cast
  - forge
---

# SafeCheck — On-chain Security Guard

A pre-transaction safety agent for the Pharos blockchain. Every operation is designed to run
*before* a user commits funds. Analysis operations are read-only and free; write operations
(revoke, attest) go through mandatory safety pre-checks.

## Prerequisites

1. **Foundry** (`cast` / `forge`). If `cast` is not found:
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   source ~/.zshenv && foundryup
   cast --version
   ```
2. **Private key** — only needed for write operations (revoke, attest), passed via
   `--private-key $PRIVATE_KEY`. Never required for audits, approval scans, simulation, or
   reading attestations.

## Network Configuration

Network info is in `assets/networks.json`; known tokens in `assets/tokens.json`.

- **Default network**: `atlantic-testnet`. Used when the user does not specify one.
- **Usage**: read the target network's `rpcUrl` into each command's `--rpc-url`.

```bash
RPC=$(jq -r '.networks[] | select(.name=="atlantic-testnet") | .rpcUrl' assets/networks.json)
```

The deployed SafeRegistry address (for attest/read) is stored in
`assets/safecheck/deployment.json` after deployment.

## Capability Index

Load `references/safecheck.md` for full command templates. Match the user's intent to a row:

| User Need | Capability | Detailed Instructions |
|-----------|------------|-----------------------|
| Is this contract/token safe? / audit / check for rug / honeypot check | Bytecode selector probe + owner state → risk report | → `references/safecheck.md#audit-address` |
| Check my approvals / what can drain my wallet / unlimited allowance | Scan ERC20 allowances, flag unlimited | → `references/safecheck.md#scan-wallet-approvals` |
| Revoke approval / remove allowance / cut off a spender | `approve(spender, 0)` | → `references/safecheck.md#revoke-approval` |
| Will this transaction work / simulate / dry-run / decode a tx | `cast call --from` / `cast run` | → `references/safecheck.md#simulate-transaction` |
| Record a verdict / attest / mark this address safe or dangerous | `attest()` on SafeRegistry | → `references/safecheck.md#attest-verdict-on-chain` |
| Has anyone audited this / community verdict / prior attestation | `getLatest()` on SafeRegistry | → `references/safecheck.md#read-attestation-on-chain` |

## General Error Handling

| Error Scenario | CLI Signature | Handling |
|----------------|---------------|----------|
| Invalid address | `invalid address` | Check 0x + 40 hex chars. |
| No contract at address | empty / `0x` from `cast code` | Report as EOA; skip contract checks. |
| Call revert | `execution reverted` | Extract and display revert reason. |
| Private key not set (writes) | missing `--private-key` | Prompt `export PRIVATE_KEY=...`. |
| Insufficient balance (writes) | `insufficient funds` | Prompt to fund with testnet PHRS. |
| Missing network config | `assets/networks.json` unreadable | Prompt that config is missing. |

## Security Reminders

- **Heuristic, not a guarantee**: bytecode selector probing detects *capabilities*, not
  intent. Never tell a user a contract is definitively "safe" — say "no dangerous patterns
  were detected in this scan" and note the limits.
- **Private key protection**: never log or echo `$PRIVATE_KEY`. Pass it explicitly via
  `--private-key $PRIVATE_KEY`; `cast`/`forge` do not read it from the environment
  automatically.
- **Network confirmation**: before any write (revoke/attest), state the target network and
  the derived signer address, and get user confirmation. Warn prominently on mainnet.

## Write Operation Pre-checks (Required for revoke and attest)

1. **Private key check** — without echoing it:
   ```bash
   [ -n "$PRIVATE_KEY" ] && echo "PRIVATE_KEY is set" || echo "PRIVATE_KEY is not set"
   ```
   If not set, prompt `export PRIVATE_KEY=<key>` and stop.
2. **Derive address**: `cast wallet address --private-key $PRIVATE_KEY`.
3. **Confirm network + address with the user** before sending. Warn loudly on mainnet.
4. **Balance check**: `cast balance <address> --rpc-url "$RPC"` to ensure gas is available.
