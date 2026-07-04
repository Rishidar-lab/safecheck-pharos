# SafeCheck — DoraHacks demo recording script

Target length **~2:45**. Format: screen recording of a terminal (and one browser tab for the
block explorer), with voiceover. Everything below is real and reproducible — no mockups.

---

## Pre-flight checklist (do before hitting record)
- [ ] `cd ~/pharos-carnival`
- [ ] `a2a-x402/` deps installed (`cd a2a-x402 && npm install`)
- [ ] Terminal font large (18–20pt), window ~120 cols, dark theme.
- [ ] For the **full** A2A settlement shot: facilitator wallet funded with PHRS gas, caller
      wallet funded with testnet USDC, `a2a-x402/.env` filled. If not funded, use the
      "paywall-only" variant of Scene 4 (still shows the real 402 + audit).
- [ ] Optional: `SafeRegistry` deployed (`bash safecheck-skill/scripts/run-all.sh`) so the
      explorer shows real attestation transactions.
- [ ] Recorder: OBS or `asciinema rec` for the terminal; browser tab open to
      `https://atlantic.pharosscan.xyz`.

Legend: **SAY** = voiceover · **SCREEN** = what's visible · **RUN** = command to type.

---

## Scene 1 — The problem (0:00–0:18)
**SCREEN:** Title card: "SafeCheck — an on-chain security guard for Pharos".
**SAY:**
> "Most wallet drains don't come from bad luck — they come from signing one transaction you
> didn't understand: an unlimited approval, a honeypot token, a contract that can freeze or
> mint at will. SafeCheck is an AI agent that checks *before* you sign."

## Scene 2 — What it is (0:18–0:38)
**SCREEN:** GitHub repo page `github.com/Rishidar-lab/safecheck-pharos`, scroll the README.
**SAY:**
> "It's built as a Pharos Skill — a SKILL.md package that Claude plus Foundry execute — plus
> an on-chain attestation registry, and it's exposed as a paid, agent-to-agent service over
> x402. Let me show it working against the live testnet."

## Scene 3 — Live audit + the contract (0:38–1:18)
**SCREEN:** Terminal in `a2a-x402/`.
**RUN:**
```bash
npx tsx audit-cli.ts 0xE0BE08c77f415F577A1B3A9aD7a1Df1479564ec8   # test USDC
```
**SAY (while it prints):**
> "SafeCheck pulls the deployed bytecode, probes for privileged function selectors, and reads
> owner state. Here it flags this token *Caution* — it found a live mint function. That's a
> real finding, not a canned response."

**RUN:**
```bash
npx tsx audit-cli.ts 0x838800b758277CC111B2d48Ab01e5E164f8E9471   # WPHRS
```
**SAY:**
> "Wrapped PHRS comes back clean — Safe, score zero. Note it never says 'definitely safe';
> it reports the signals and calls itself a heuristic, not a full audit."

**SCREEN:** switch to `safecheck-skill/` terminal.
**RUN:**
```bash
forge test
```
**SAY:**
> "The verdicts get written on-chain to a SafeRegistry contract — append-only, so history is
> auditable. Six passing Foundry tests cover it."

**SCREEN (optional):** browser → `atlantic.pharosscan.xyz/address/<SafeRegistry>` showing
`attest` transactions.
**SAY (if shown):**
> "Here are real attestations recorded on Pharos Atlantic testnet."

## Scene 4 — Agent-to-agent x402 payments (1:18–2:20)
**SCREEN:** three stacked terminal panes in `a2a-x402/`.

**Pane 1 — facilitator:**
```bash
npx tsx facilitator.ts
```
**Pane 2 — SafeCheck seller:**
```bash
npx tsx server.ts
```
**SAY:**
> "Now the agent-to-agent part. One agent sells SafeCheck audits; a facilitator settles
> payment on Pharos. First, what happens if you call the audit endpoint *without* paying?"

**Pane 3 — show the paywall:**
```bash
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://localhost:4021/audit/0xE0BE08c77f415F577A1B3A9aD7a1Df1479564ec8
```
**SCREEN:** `HTTP 402`.
**SAY:**
> "402 — Payment Required. The x402 protocol. Now the paying client agent."

**Pane 3 — run the paying caller:**
```bash
npx tsx client.ts
```
**SAY (while it runs):**
> "The client signs a USDC payment, the facilitator settles it on-chain, and only then does
> the audit come back — verdict, score, and the settlement transaction hash. That's two
> autonomous agents transacting for a real service, on Pharos."

> **If wallets aren't funded yet:** stop after the 402 + `npm run audit` output and say:
> "Payment settlement runs the moment the caller wallet holds testnet USDC — the loop itself
> is built and verified." Do not fake a tx hash.

## Scene 5 — Close (2:20–2:45)
**SCREEN:** back to the repo README; overlay the three verified checkmarks.
**SAY:**
> "SafeCheck is live: a security Skill, an on-chain registry, and a working x402 payment
> loop — targeting the Steward first-deployment and invocation tracks of the Pharos Agent
> Carnival. Code's open-source at github.com/Rishidar-lab/safecheck-pharos. Thanks for
> watching."
**SCREEN:** end card with repo URL + Anvita Flow Service Agent link.

---

## One-take command sequence (copy/paste order)
```bash
# Scene 3
cd ~/pharos-carnival/a2a-x402
npx tsx audit-cli.ts 0xE0BE08c77f415F577A1B3A9aD7a1Df1479564ec8
npx tsx audit-cli.ts 0x838800b758277CC111B2d48Ab01e5E164f8E9471
(cd ../safecheck-skill && forge test)

# Scene 4 (3 panes)
npx tsx facilitator.ts        # pane 1
npx tsx server.ts             # pane 2
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://localhost:4021/audit/0xE0BE08c77f415F577A1B3A9aD7a1Df1479564ec8   # pane 3
npx tsx client.ts             # pane 3
```

## Recording tips
- `asciinema rec demo.cast` captures a crisp, lightweight terminal recording you can embed;
  OBS if you need the browser/explorer in-frame.
- Keep each command on screen ~2s after output before moving on.
- Caption the key beats: "real testnet", "HTTP 402", "settled on-chain".
- Total runtime target 2:30–3:00 (DoraHacks demos are short).
