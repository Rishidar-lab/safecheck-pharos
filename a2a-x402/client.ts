// Caller/buyer agent: pays USDC to invoke the SafeCheck seller's /audit endpoint.
// Loops over target addresses to generate real agent-to-agent payment volume.
import { config } from "dotenv";
import { x402Client, wrapFetchWithPayment, decodePaymentResponseHeader } from "@x402/fetch";
import { ExactEvmScheme } from "@x402/evm/exact/client";
import { toClientEvmSigner } from "@x402/evm";
import { publicClient, walletFromKey, NETWORK } from "./chain.js";

config();

const pk = process.env.CALLER_PRIVATE_KEY as `0x${string}` | undefined;
const serverUrl = process.env.SERVER_URL || "http://localhost:4021";
if (!pk || !pk.startsWith("0x")) {
  console.error("Set CALLER_PRIVATE_KEY (buyer agent key).");
  process.exit(1);
}

// Targets to audit — default to the known Pharos testnet tokens.
const targets = (process.env.TARGETS ||
  "0xE0BE08c77f415F577A1B3A9aD7a1Df1479564ec8,0xE7E84B8B4f39C507499c40B4ac199B050e2882d5,0x0c64F03EEa5c30946D5c55B4b532D08ad74638a4"
).split(",").map((s) => s.trim());

const rounds = Number(process.env.ROUNDS || 1);

async function main() {
  const pub = publicClient();
  const { account } = walletFromKey(pk!);
  const signer = toClientEvmSigner(account, {
    readContract: (args) => pub.readContract(args as any),
  });

  const client = new x402Client();
  client.register(NETWORK, new ExactEvmScheme(signer));
  const fetchPaid = wrapFetchWithPayment(fetch, client);

  console.log(`Caller ${account.address} -> ${serverUrl} (${rounds} round(s), ${targets.length} targets)`);
  let paidCalls = 0;
  for (let r = 0; r < rounds; r++) {
    for (const t of targets) {
      const resp = await fetchPaid(`${serverUrl}/audit/${t}`);
      const body = await resp.json();
      const payResp = resp.headers.get("PAYMENT-RESPONSE");
      const settled = payResp ? decodePaymentResponseHeader(payResp) : null;
      paidCalls++;
      console.log(
        `[${paidCalls}] ${t} -> ${body?.safecheck?.verdict ?? "?"} (score ${body?.safecheck?.score ?? "?"})` +
          (settled ? ` | settled tx ${(settled as any)?.transaction ?? (settled as any)?.tx_hash ?? "n/a"}` : "")
      );
    }
  }
  console.log(`Done. ${paidCalls} paid agent-to-agent audits.`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
