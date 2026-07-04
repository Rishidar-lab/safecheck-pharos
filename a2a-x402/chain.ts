// Shared Pharos Atlantic testnet chain + client helpers.
import { createPublicClient, createWalletClient, http, defineChain } from "viem";
import { privateKeyToAccount } from "viem/accounts";

export const pharosAtlantic = defineChain({
  id: 688689,
  name: "Pharos Atlantic Testnet",
  nativeCurrency: { name: "Pharos", symbol: "PHRS", decimals: 18 },
  rpcUrls: { default: { http: ["https://atlantic.dplabs-internal.com"] } },
  blockExplorers: { default: { name: "PharosScan", url: "https://atlantic.pharosscan.xyz" } },
  testnet: true,
});

export const NETWORK = "eip155:688689" as const;
export const USDC_ADDRESS = "0xE0BE08c77f415F577A1B3A9aD7a1Df1479564ec8" as `0x${string}`;

export function publicClient() {
  return createPublicClient({ chain: pharosAtlantic, transport: http() });
}

export function walletFromKey(pk: `0x${string}`) {
  const account = privateKeyToAccount(pk);
  const wallet = createWalletClient({ account, chain: pharosAtlantic, transport: http() });
  return { account, wallet };
}
