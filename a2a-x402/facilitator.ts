// Self-hosted x402 facilitator: verifies signed payments and settles USDC on Pharos.
// Exposed as POST /verify and POST /settle for the resource server to call.
// The facilitator wallet pays gas to submit settlement transactions.
import express from "express";
import { config } from "dotenv";
import { x402Facilitator } from "@x402/core/facilitator";
import { registerExactEvmScheme } from "@x402/evm/exact/facilitator";
import { toFacilitatorEvmSigner } from "@x402/evm";
import { publicClient, walletFromKey, pharosAtlantic, NETWORK } from "./chain.js";

config();

const pk = process.env.FACILITATOR_PRIVATE_KEY as `0x${string}` | undefined;
const port = Number(process.env.FACILITATOR_PORT || 4022);
if (!pk || !pk.startsWith("0x")) {
  console.error("Set FACILITATOR_PRIVATE_KEY (funded with PHRS gas).");
  process.exit(1);
}

const pub = publicClient();
const { account, wallet } = walletFromKey(pk!);

// Adapter: satisfy FacilitatorEvmSigner by delegating to viem wallet + public clients.
const baseSigner = {
  address: account.address,
  signTypedData: (msg: any) => wallet.signTypedData({ account, ...msg }),
  readContract: (args: any) => pub.readContract(args),
  writeContract: (args: any) => wallet.writeContract({ account, chain: pharosAtlantic, ...args }),
  sendTransaction: (args: any) => wallet.sendTransaction({ account, chain: pharosAtlantic, ...args }),
  waitForTransactionReceipt: (args: any) => pub.waitForTransactionReceipt(args),
  getCode: (args: any) => pub.getCode(args),
};
const signer = toFacilitatorEvmSigner(baseSigner as any);

const facilitator = new x402Facilitator();
registerExactEvmScheme(facilitator, { networks: NETWORK, signer });

const app = express();
app.use(express.json());

app.get("/health", (_req, res) => res.json({ status: "healthy", facilitator: account.address, network: NETWORK }));

app.post("/verify", async (req, res) => {
  try {
    const { paymentPayload, paymentRequirements } = req.body;
    res.json(await facilitator.verify(paymentPayload, paymentRequirements));
  } catch (e: any) {
    res.status(400).json({ error: e?.message });
  }
});

app.post("/settle", async (req, res) => {
  try {
    const { paymentPayload, paymentRequirements } = req.body;
    res.json(await facilitator.settle(paymentPayload, paymentRequirements));
  } catch (e: any) {
    res.status(400).json({ error: e?.message });
  }
});

app.get("/supported", async (_req, res) => res.json(await facilitator.getSupported()));

app.listen(port, () => console.log(`Facilitator ${account.address} listening on http://localhost:${port}`));
