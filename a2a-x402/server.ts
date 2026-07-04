// SafeCheck seller agent: exposes a paid /audit/:address endpoint over x402.
// A caller agent pays USDC per audit; the handler runs the real SafeCheck analysis.
import express from "express";
import { config } from "dotenv";
import { paymentMiddleware, x402ResourceServer } from "@x402/express";
import { HTTPFacilitatorClient } from "@x402/core/server";
import { ExactEvmScheme } from "@x402/evm/exact/server";
import { publicClient, NETWORK, USDC_ADDRESS } from "./chain.js";
import { auditAddress } from "./audit.js";

config();

const payTo = process.env.PAY_TO_ADDRESS as `0x${string}` | undefined;
const facilitatorUrl = process.env.FACILITATOR_URL;
const port = Number(process.env.PORT || 4021);
const price = process.env.AUDIT_PRICE || "0.001";

if (!payTo || !/^0x[0-9a-fA-F]{40}$/.test(payTo)) {
  console.error("Set PAY_TO_ADDRESS (seller receiving address).");
  process.exit(1);
}
if (!facilitatorUrl) {
  console.error("Set FACILITATOR_URL (self-hosted facilitator or a hosted one).");
  process.exit(1);
}

const facilitator = new HTTPFacilitatorClient({ url: facilitatorUrl });
const resourceServer = new x402ResourceServer(facilitator);

const evmScheme = new ExactEvmScheme();
evmScheme.registerMoneyParser(async (amount: number, network: string) =>
  network === NETWORK
    ? { amount: Math.round(amount * 1e6).toString(), asset: USDC_ADDRESS, extra: { name: "USDC", version: "2" } }
    : null
);
resourceServer.register(NETWORK, evmScheme);

const pub = publicClient();
const app = express();
app.use(express.json());

app.use(
  paymentMiddleware(
    {
      "GET /audit/:address": {
        accepts: { scheme: "exact", price, network: NETWORK, payTo },
        description: "SafeCheck on-chain security audit of an address",
        mimeType: "application/json",
      },
    },
    resourceServer
  )
);

app.get("/health", (_req, res) => res.json({ status: "healthy", service: "SafeCheck", network: NETWORK }));

app.get("/audit/:address", async (req, res) => {
  const addr = req.params.address;
  if (!/^0x[0-9a-fA-F]{40}$/.test(addr)) return res.status(400).json({ error: "invalid address" });
  try {
    const result = await auditAddress(pub, addr as `0x${string}`);
    res.json({ safecheck: result, paid: `${price} USDC`, network: NETWORK });
  } catch (e: any) {
    res.status(500).json({ error: "audit failed", message: e?.message });
  }
});

app.listen(port, () => console.log(`SafeCheck seller listening on http://localhost:${port} (audit price ${price} USDC)`));
