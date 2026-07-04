# Pharos Agent Carnival — Winning Strategy

**Deadline:** 2026-07-21 · **Pool:** 150,000 $PROS · **Submit via:** DoraHacks (`pharos-phase1`) + Anvita Flow console
**Today:** 2026-07-04 (17 days left)

## What the competition actually is
"Skills first, Agents second." A **Skill** = a `SKILL.md` package that Claude Code + Foundry read to drive on-chain actions (no SDK). An **Agent** = that Skill wrapped as a hosted **Service Agent** on **Anvita Flow**, discoverable in a marketplace and invoked by users' **Steward Agents**, billed per-call via x402 micropayments.

## Current state (as of 2026-07-04)
- Phase 1 Skill Hackathon **closed** — ~500 entries, 50 winners across 6 categories.
- We are in **Phase 2**. Live dev-side tracks (100k pool):
  - **Steward Agent First-Deployment Incentive** — reward for being an early Service Agent live on Anvita Flow.
  - **Developer-side Agent Invocation Race** — reward by how much your agent gets invoked.
  - **Caller Invocation Race** — reward for invoking/using agents.
- User-side (50k): Gravity Launch (social), Resonance Creators (content), Social & Transfer.

## Winning thesis
Deploy a **genuinely useful Service Agent early** (First-Deployment), then **drive real invocation volume** (Invocation Race). A security/on-chain-intelligence angle differentiates us — the user is a bug-bounty hunter, so we build something the 50 generic winners didn't.

## Build pipeline
1. **Contract** (`assets/<skill>/*.sol`) — deploy + verify on Atlantic testnet.
2. **Reference** (`references/<skill>.md`) — per-operation: Overview / Command Template / Parameters / Output Parsing / Error Handling / Agent Guidelines.
3. **SKILL.md** — add rows to Capability Index with natural-language synonyms; update `description` keywords.
4. **Local test** — `claude` inside the skill folder, run through every operation end-to-end.
5. **CertiK Skill Scanner** — self-scan (GitHub/URL/ZIP) before submit; fix findings.
6. **Package** — zip the whole folder (folder is top-level entry), SKILL.md at root with frontmatter `name` matching folder.
7. **Publish** — flow.anvita.xyz/service-agents → Create Managed Service Agent → upload zip → customer-service strategy → runtime config → debug via own Steward Agent → complete Agent Card → publish (price = Free during beta).
8. **DoraHacks** — submit BUIDL to pharos-phase1 with repo + demo.
9. **Drive invocations** — seed example tasks, share, self-invoke via Steward Agent, get others calling it.

## Environment (all installed)
node 22.22 · foundry 1.5.1 · claude 2.1.201 · git · jq
Networks: atlantic-testnet (chainId 688689, PHRS) default; mainnet 1672 (PROS).

## Next actions
- [ ] Pick skill concept (see decision)
- [ ] Get testnet wallet + faucet PHRS
- [ ] Write + deploy + verify contract
- [ ] Write references + SKILL.md
- [ ] Local end-to-end test harness
- [ ] CertiK self-scan
- [ ] Publish Service Agent on Anvita Flow
- [ ] Submit DoraHacks BUIDL
- [ ] Invocation-growth loop
