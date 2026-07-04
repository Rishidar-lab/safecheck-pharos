# SafeCheck — On-chain Security Guard (Pharos Skill)

A pre-transaction safety agent for the Pharos network, built as a Pharos Skill for the
Agent Carnival. SafeCheck audits contracts and tokens for dangerous patterns, scans wallets
for risky approvals, simulates transactions to catch honeypots, and records community
security verdicts on-chain via the `SafeRegistry` contract.

## What it does
| Capability | Read/Write | Summary |
|-----------|-----------|---------|
| Audit address | read | Bytecode selector probe + owner state → risk report + score. |
| Scan approvals | read | Flags unlimited ERC20 allowances that can drain a wallet. |
| Revoke approval | write | `approve(spender, 0)`. |
| Simulate tx | read | `cast call --from` / `cast run` to catch reverts/honeypots. |
| Attest verdict | write | Records Safe/Caution/Danger on `SafeRegistry`. |
| Read attestation | read | Latest community verdict for an address. |

## Layout
```
safecheck-skill/
├── SKILL.md                         entry point (capability index)
├── references/safecheck.md          full command templates per operation
├── assets/
│   ├── networks.json                Pharos RPC/chain config
│   ├── tokens.json                  known token addresses
│   └── safecheck/
│       ├── SafeRegistry.sol         on-chain attestation registry
│       ├── DeploySafeRegistry.s.sol deploy script
│       └── deployment.json          written after deploy (registry address)
├── src/safecheck/                   compilable sources (mirror of assets)
├── test/SafeRegistry.t.sol          Foundry tests (6 passing)
├── scripts/
│   ├── setup-wallet.sh              throwaway testnet wallet
│   ├── deploy.sh                    deploy + verify SafeRegistry
│   └── package.sh                   build submission zip
├── TESTPLAN.md                      end-to-end test checklist
└── PUBLISH.md                       Anvita Flow + CertiK + DoraHacks steps
```

## Quick start
```bash
forge test                    # verify contract logic (offline)
bash scripts/setup-wallet.sh  # make a testnet wallet, then fund via faucet
bash scripts/deploy.sh        # deploy + verify SafeRegistry
claude                        # launch the agent; see TESTPLAN.md for prompts
```

## Safety stance
Bytecode probing detects *capabilities*, not intent. SafeCheck never declares a contract
definitively "safe" — it reports "no dangerous patterns detected in this scan" and the
signals it found. Private keys are only used for writes and passed explicitly via
`--private-key $PRIVATE_KEY`; they are never logged.
