# Publishing SafeCheck as a Service Agent + DoraHacks submission

## A. Package the skill
```bash
bash scripts/package.sh      # produces ../safecheck-skill.zip with the folder as root entry
```
Confirm the CertiK scan passes first (section C).

## B. Publish on Anvita Flow (Service Agent → Steward Agent First-Deployment + Invocation Race)
1. Register / log in at https://flow.anvita.xyz/home
2. Go to https://flow.anvita.xyz/service-agents → **Create A Managed Service Agent**
3. **Upload Skill Package**: upload `safecheck-skill.zip` — must pass parsing validation.
4. **Customer Service Strategy** (paste):
   > When a user asks about a contract, token, wallet, or transaction, first identify the
   > address(es) involved. If an address is missing, ask for it before proceeding. Default
   > to the atlantic-testnet network unless the user names another. Always run read-only
   > analysis first and present findings with the specific risk signals before recommending
   > any action. For revoke/attest (write) actions, confirm the target network and signer
   > address with the user before executing. Never claim a contract is definitively safe.
5. **Runtime Configuration**: Max concurrent sessions: 5. Max single execution time: 120s.
6. **Debug**: from your own Steward Agent in Anvita On (https://flow.anvita.xyz/agent/chat),
   send: *"go find SafeCheck to audit token 0xE0BE08c77f415F577A1B3A9aD7a1Df1479564ec8"* and
   confirm a correct response.
7. **Agent Card** — paste the fields from section D. Set **Unit price = Free** during beta.
8. Submit for review → wait for **Published / Running** status.
9. (Earnings) enable wallet at https://flow.anvita.xyz/dashboard.

## C. CertiK Skill Scanner (official security evaluation)
Submit the skill via GitHub repo URL, public URL, or the ZIP at CertiK's Skill Scanner.
Fix any findings (this skill is intentionally minimal-permission: read-only by default,
no network calls beyond RPC, no secrets in code, key only via `--private-key`). Keep the
scan report screenshot for the DoraHacks submission.

## D. Agent Card (copy/paste)
- **Agent name**: SafeCheck — On-chain Security Guard
- **One-sentence intro**: Audits Pharos contracts, tokens, and approvals before you sign, and records verdicts on-chain.
- **Capability description**: Contract/token risk audits (mintable, pausable, blacklist/honeypot, active owner detection), wallet approval scanning with unlimited-allowance flagging, one-click approval revocation, transaction simulation to catch reverts and honeypots, and an on-chain SafeRegistry of community security verdicts.
- **Example tasks**:
  1. "Audit token 0xE0BE08c77f415F577A1B3A9aD7a1Df1479564ec8 and tell me if it's risky."
  2. "Scan my wallet for unlimited approvals and revoke the dangerous ones."
- **Information required**: The target address (token/contract/wallet) and, for writes, a funded testnet key via `$PRIVATE_KEY`.
- **Deliverables**: A risk report with the specific signals found, a verdict (Safe/Caution/Danger) with a 0-100 score, and — on request — an on-chain attestation tx hash.
- **Range not supported**: Not a substitute for a full manual audit; bytecode probing is heuristic. Does not analyze off-chain/backend risk or private keys.
- **Estimated duration**: 10-40 seconds per audit.
- **Unit price**: Free (beta).

## E. DoraHacks BUIDL submission (pharos-phase1)
At https://dorahacks.io/hackathon/pharos-phase1 submit a BUIDL with:
- Repo link (push safecheck-skill to GitHub).
- Anvita Flow Service Agent link (Published status).
- Deployed + verified SafeRegistry explorer link.
- Short demo (2-3 min screen recording of an audit + an on-chain attest).
- CertiK Skill Scanner report screenshot.
- Sample attestation tx hashes captured during testing.

## F. Invocation-growth loop (Invocation / Caller races)
- Seed SafeRegistry with 10-20 real attestations of popular testnet tokens so the read flow
  has content from day one.
- Post the agent in Pharos community channels with the two example prompts.
- Use your own Steward Agent (Caller race) to invoke SafeCheck routinely.
