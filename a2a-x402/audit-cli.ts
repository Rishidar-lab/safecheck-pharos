// Standalone SafeCheck audit — read-only, no wallet/funds needed.
// Usage: npx tsx audit-cli.ts 0x<address>
import { publicClient } from "./chain.js";
import { auditAddress } from "./audit.js";

const target = process.argv[2];
if (!target || !/^0x[0-9a-fA-F]{40}$/.test(target)) {
  console.error("Usage: npx tsx audit-cli.ts 0x<address>");
  process.exit(1);
}

const badge = (v: string) => (v === "Danger" ? "🔴 DANGER" : v === "Caution" ? "🟡 CAUTION" : "🟢 SAFE");

const pub = publicClient();
const r = await auditAddress(pub, target as `0x${string}`);
console.log(`\n  SafeCheck audit — ${r.target}`);
console.log(`  Network: Pharos Atlantic testnet | contract: ${r.isContract}`);
console.log(`  Verdict: ${badge(r.verdict)}   Risk score: ${r.score}/100`);
console.log(`  Signals:`);
for (const s of r.signals) console.log(`    • ${s}`);
console.log(`  Note: ${r.disclaimer}\n`);
