# SafeCheck Reference

Pre-transaction security analysis for the Pharos network. All operations read network
config from `assets/networks.json` (default network `atlantic-testnet`) and known token
addresses from `assets/tokens.json`.

Set up once per session:

```bash
RPC=$(jq -r '.networks[] | select(.name=="atlantic-testnet") | .rpcUrl' assets/networks.json)
```

Risk scoring convention used across every operation:

| Verdict | Score | Meaning |
|---------|-------|---------|
| Safe    | 0-19  | No material risks found. |
| Caution | 20-59 | Non-critical risks (mintable, pausable, active owner). |
| Danger  | 60-100| Critical risks (honeypot pattern, unlimited-approval exposure, blacklist). |

---

## Audit Address

### Overview
Inspect any contract or token address for dangerous capabilities *before* a user interacts
with it. The audit is fully read-only (free) — it fetches deployed bytecode and probes for
the 4-byte function selectors of privileged/abusive functions, then reads owner state.

### Command Template
```bash
TARGET=0x<address>

# 1. Is there contract code at all? (EOAs and self-destructed contracts return "0x")
CODE=$(cast code "$TARGET" --rpc-url "$RPC")
[ "$CODE" = "0x" ] && echo "No contract code (EOA or destroyed)" 

# 2. Probe for dangerous function selectors in the bytecode.
#    A selector present in bytecode means the function likely exists.
declare -A SEL=(
  [8da5cb5b]="owner()"
  [f2fde38b]="transferOwnership(address)"
  [715018a6]="renounceOwnership()"
  [40c10f19]="mint(address,uint256)"
  [8456cb59]="pause()"
  [3f4ba83a]="unpause()"
  [f9f92be4]="blacklist(address)"
  [fe575a87]="isBlacklisted(address)"
  [42966c68]="burn(uint256)"
  [a9059cbb]="transfer(address,uint256)"
  [dd62ed3e]="allowance(address,address)"
)
for sel in "${!SEL[@]}"; do
  echo "$CODE" | grep -qi "$sel" && echo "PRESENT: ${SEL[$sel]}"
done

# 3. Read owner state (if owner() present).
cast call "$TARGET" "owner()(address)" --rpc-url "$RPC" 2>/dev/null
```

### Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| TARGET | address | Yes | Contract/token address to audit (0x + 40 hex). |

### Output Parsing
| Signal | Interpretation | Risk contribution |
|--------|----------------|-------------------|
| `owner()` returns non-zero | Active owner can exert control | +20 (Caution) |
| `owner()` returns `0x000…000` | Ownership renounced | reduces risk |
| `mint(address,uint256)` present | Supply can be inflated | +25 |
| `pause()` present | Transfers can be frozen | +20 |
| `blacklist(address)` present | Addresses can be blocked (honeypot enabler) | +40 (Danger) |
| No `transfer(address,uint256)` on a "token" | Not a standard ERC20 / suspicious | +30 |
| Contract code == `0x` | EOA or self-destructed | report, do not treat as contract |

Combine contributions, cap at 100, map to the verdict table above. Always list *which*
signals fired so the user sees the reasoning, not just a number.

### Error Handling
| Error Signature | Cause | Suggested Action |
|-----------------|-------|------------------|
| `invalid address` | Malformed target | Check 0x + 40 hex chars. |
| empty / `0x` from `cast code` | No contract at address | Report as EOA; skip contract checks. |
| `execution reverted` on `owner()` | Function absent or non-standard | Treat owner as unknown; note it. |

> **Agent Guidelines**:
> 1. Always run `cast code` first; branch on EOA vs contract.
> 2. Report every selector that fired, with its plain-English risk, before giving a score.
> 3. Never claim a contract is "safe" — say "no dangerous patterns detected in this scan"
>    and remind the user that bytecode probing is heuristic, not a full audit.
> 4. Offer to record the verdict on-chain via the Attest flow.

---

## Scan Wallet Approvals

### Overview
List a wallet's ERC20 allowances across all known Pharos tokens and flag **unlimited**
approvals — the single most common drain vector. Read-only.

### Command Template
```bash
WALLET=0x<wallet>
MAX_UINT=115792089237316195423570985008687907853269984665640564039457584007913129639935

jq -r '."atlantic-testnet"[] | "\(.symbol) \(.address)"' assets/tokens.json | while read SYM TOKEN; do
  # allowance(owner, spender) — here we check a specific spender the user is about to approve,
  # or iterate over spenders the user provides. Example checks a given SPENDER:
  ALLOW=$(cast call "$TOKEN" "allowance(address,address)(uint256)" "$WALLET" "$SPENDER" --rpc-url "$RPC")
  if [ "$ALLOW" = "$MAX_UINT" ]; then
    echo "⚠️ UNLIMITED approval: $SYM ($TOKEN) -> $SPENDER"
  elif [ "$ALLOW" != "0" ]; then
    echo "approval: $SYM $ALLOW -> $SPENDER"
  fi
done
```

### Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| WALLET | address | Yes | Wallet whose approvals are checked. |
| SPENDER | address | Yes | Spender/contract to check allowance against. |

### Output Parsing
| Field | Description |
|-------|-------------|
| `UNLIMITED approval` | allowance == 2^256-1; highest priority to revoke. |
| numeric approval | finite allowance; note amount vs. decimals from tokens.json. |
| `0` | no approval; safe. |

### Error Handling
| Error Signature | Cause | Suggested Action |
|-----------------|-------|------------------|
| `execution reverted` | Address is not an ERC20 | Skip token; note it. |
| `invalid address` | Bad wallet/spender | Re-check inputs. |

> **Agent Guidelines**:
> 1. Convert raw allowance to human units using the token's `decimals` from tokens.json.
> 2. Rank unlimited approvals first; recommend revoking any the user no longer uses.
> 3. Chain into the Revoke Approval flow for anything flagged.

---

## Revoke Approval

### Overview
Build and send an `approve(spender, 0)` transaction to remove an allowance. This is a
**write** operation — run the SKILL.md Write Operation Pre-checks first (private key,
derived address, network confirmation, balance).

### Command Template
```bash
cast send "$TOKEN" "approve(address,uint256)" "$SPENDER" 0 \
  --private-key $PRIVATE_KEY --rpc-url "$RPC"
```

### Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| TOKEN | address | Yes | ERC20 whose approval is being revoked. |
| SPENDER | address | Yes | Spender to set allowance to 0. |

### Output Parsing
| Field | Description |
|-------|-------------|
| transactionHash | Revocation tx; confirm on explorer. |
| status | `1` = success, `0` = failed. |

### Error Handling
| Error Signature | Cause | Suggested Action |
|-----------------|-------|------------------|
| `insufficient funds` | No gas | Fund wallet with testnet PHRS. |
| Command missing `--private-key` | Key not configured | `export PRIVATE_KEY=...`. |

> **Agent Guidelines**:
> 1. Confirm the exact token+spender with the user before sending.
> 2. After success, re-run the approvals check to prove allowance is now 0.

---

## Simulate Transaction

### Overview
Dry-run a call before signing to see whether it would revert and what it returns — catches
honeypots and failing interactions without spending gas.

### Command Template
```bash
# Static simulation of a call from the user's address:
cast call "$TARGET" "$SIG" $ARGS --from "$WALLET" --rpc-url "$RPC"

# Trace an existing tx hash to decode what happened:
cast run "$TXHASH" --rpc-url "$RPC"
```

### Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| TARGET | address | Yes (for call) | Contract to simulate against. |
| SIG | string | Yes (for call) | Function signature, e.g. `"transfer(address,uint256)"`. |
| ARGS | list | No | Function arguments. |
| TXHASH | bytes32 | Yes (for run) | Existing tx to trace. |

### Output Parsing
| Field | Description |
|-------|-------------|
| return data | Decoded return value on success. |
| `execution reverted` | Would fail — surface the revert reason to the user. |
| trace | Call tree from `cast run`; highlight failed subcalls. |

### Error Handling
| Error Signature | Cause | Suggested Action |
|-----------------|-------|------------------|
| `execution reverted: <reason>` | Call would fail | Report reason; treat honeypot-like reverts on sells as Danger. |

> **Agent Guidelines**:
> 1. For a suspected honeypot token, simulate a `transfer` from the holder — if buys work
>    but transfers/sells revert, flag Danger.

---

## Attest Verdict (on-chain)

### Overview
Record a security verdict about a target on the **SafeRegistry** contract so future callers
(and other Steward Agents) can read it. Write operation — run Pre-checks first.

### Command Template
```bash
REGISTRY=0x<deployed SafeRegistry address>   # see assets/safecheck/deployment.json
# verdict: 1=Safe 2=Caution 3=Danger ; riskScore 0-100 ; note <=280 chars
cast send "$REGISTRY" "attest(address,uint8,uint8,string)" \
  "$TARGET" "$VERDICT" "$SCORE" "$NOTE" \
  --private-key $PRIVATE_KEY --rpc-url "$RPC"
```

### Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| TARGET | address | Yes | Address the verdict is about. |
| VERDICT | uint8 | Yes | 1=Safe, 2=Caution, 3=Danger. |
| SCORE | uint8 | Yes | 0-100 risk score. |
| NOTE | string | Yes | ≤280-char summary of findings. |

### Output Parsing
| Field | Description |
|-------|-------------|
| transactionHash | Attestation tx; links to Attested event. |
| Attested event | Emitted with target/auditor/verdict/score. |

### Error Handling
| Error Signature | Cause | Suggested Action |
|-----------------|-------|------------------|
| `Verdict out of range` | verdict not 1-3 | Use 1/2/3. |
| `Risk score over 100` | score > 100 | Clamp to 0-100. |
| `Note too long` | note > 280 chars | Shorten summary. |

> **Agent Guidelines**:
> 1. Only attest after actually running the Audit flow; put the concrete findings in the note.
> 2. Report the tx hash and explorer link so the attestation is verifiable.

---

## Read Attestation (on-chain)

### Overview
Look up the latest community verdict for a target before interacting — read-only.

### Command Template
```bash
REGISTRY=0x<deployed SafeRegistry address>
cast call "$REGISTRY" "attestationCount(address)(uint256)" "$TARGET" --rpc-url "$RPC"
cast call "$REGISTRY" "getLatest(address)(address,uint8,uint8,uint64,string)" "$TARGET" --rpc-url "$RPC"
```

### Output Parsing
| Field | Description |
|-------|-------------|
| count == 0 | Never audited — verdict Unknown. |
| getLatest tuple | (auditor, verdict, riskScore, timestamp, note) — present to the user. |

### Error Handling
| Error Signature | Cause | Suggested Action |
|-----------------|-------|------------------|
| `No attestations for target` | count is 0 | Report "Unknown / never audited"; offer to run Audit. |

> **Agent Guidelines**:
> 1. Always check attestation count first; a revert on getLatest just means Unknown.
> 2. Show the timestamp so the user knows how fresh the verdict is.
