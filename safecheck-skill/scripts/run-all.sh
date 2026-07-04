#!/usr/bin/env bash
# Master automation. After you fund the wallet from a faucet, this single command:
#   1. checks the seller wallet has gas
#   2. deploys + verifies SafeRegistry
#   3. seeds genuine on-chain attestations
# Then prints next steps for the x402 A2A loop and the manual publish.
set -euo pipefail
cd "$(dirname "$0")/.."

[ -f .env.testnet ] && set -a && . ./.env.testnet && set +a
: "${PRIVATE_KEY:?Run scripts/setup-wallet.sh first}"

RPC=$(jq -r '.networks[] | select(.name=="atlantic-testnet") | .rpcUrl' assets/networks.json)
ADDR=$(cast wallet address --private-key "$PRIVATE_KEY")
BAL=$(cast balance "$ADDR" --rpc-url "$RPC")

echo "Seller/agent wallet: $ADDR"
echo "Balance: $BAL wei"
if [ "$BAL" = "0" ]; then
  echo ""
  echo "❌ Wallet has no PHRS. Fund it first (the only manual step):"
  echo "   Faucet: https://testnet.pharosnetwork.xyz/  (also stakely.io / faucet.trade / zan.top)"
  echo "   Address to fund: $ADDR"
  exit 1
fi

echo "== 1/3 deploy + verify ==" && bash scripts/deploy.sh
echo "== 2/3 seed attestations ==" && bash scripts/seed-attestations.sh
echo "== 3/3 package ==" && bash scripts/package.sh

REGISTRY=$(jq -r '.SafeRegistry' assets/safecheck/deployment.json)
EXPL=$(jq -r '.networks[] | select(.name=="atlantic-testnet") | .explorerUrl' assets/networks.json)
cat <<EOF

✅ On-chain footprint live.
   SafeRegistry: $REGISTRY
   Explorer:     ${EXPL}address/$REGISTRY

NEXT:
  • Agent-to-agent x402 loop:   cd ../a2a-x402 && bash run-a2a.sh
  • Manual publish (copy/paste): see PUBLISH.md (Anvita Flow + CertiK + DoraHacks)
EOF
