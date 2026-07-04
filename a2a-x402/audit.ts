// Shared SafeCheck audit logic — the real value the paid endpoint sells.
// Pure read-only bytecode analysis via viem, mirroring references/safecheck.md.
import type { PublicClient } from "viem";

export type Verdict = "Safe" | "Caution" | "Danger";

export interface AuditResult {
  target: `0x${string}`;
  isContract: boolean;
  verdict: Verdict;
  score: number; // 0-100
  signals: string[];
  disclaimer: string;
}

// 4-byte selectors (without 0x) of privileged / abuse-enabling functions.
const DANGER_SELECTORS: Array<{ sel: string; label: string; weight: number }> = [
  { sel: "40c10f19", label: "mint(address,uint256)", weight: 25 },
  { sel: "8456cb59", label: "pause()", weight: 20 },
  { sel: "f9f92be4", label: "blacklist(address)", weight: 40 },
  { sel: "fe575a87", label: "isBlacklisted(address)", weight: 15 },
];

const OWNER_ABI = [
  { type: "function", name: "owner", stateMutability: "view", inputs: [], outputs: [{ type: "address" }] },
] as const;

export async function auditAddress(
  client: PublicClient,
  target: `0x${string}`
): Promise<AuditResult> {
  const disclaimer =
    "Heuristic bytecode scan — detects capabilities, not intent. Not a full audit.";

  const code = await client.getCode({ address: target });
  if (!code || code === "0x") {
    return { target, isContract: false, verdict: "Safe", score: 0, signals: ["No contract code (EOA or destroyed)"], disclaimer };
  }

  const hay = code.toLowerCase();
  const signals: string[] = [];
  let score = 0;

  for (const { sel, label, weight } of DANGER_SELECTORS) {
    if (hay.includes(sel)) {
      score += weight;
      signals.push(`present: ${label}`);
    }
  }

  // Active owner check.
  try {
    const owner = (await client.readContract({
      address: target,
      abi: OWNER_ABI,
      functionName: "owner",
    })) as `0x${string}`;
    if (owner && owner !== "0x0000000000000000000000000000000000000000") {
      score += 20;
      signals.push(`active owner: ${owner}`);
    } else {
      signals.push("ownership renounced");
    }
  } catch {
    signals.push("no owner() function (or non-standard)");
  }

  if (score > 100) score = 100;
  if (signals.length === 0) signals.push("no dangerous patterns detected in this scan");

  const verdict: Verdict = score >= 60 ? "Danger" : score >= 20 ? "Caution" : "Safe";
  return { target, isContract: true, verdict, score, signals, disclaimer };
}
