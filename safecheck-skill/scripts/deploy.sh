#!/usr/bin/env bash
# Deploy + verify SafeRegistry on Pharos Atlantic testnet, then record the address.
set -euo pipefail
cd "$(dirname "$0")/.."

[ -f .env.testnet ] && set -a && . ./.env.testnet && set +a
: "${PRIVATE_KEY:?Set PRIVATE_KEY (run scripts/setup-wallet.sh or export it)}"

RPC=$(jq -r '.networks[] | select(.name=="atlantic-testnet") | .rpcUrl' assets/networks.json)
CHAIN_ID=$(jq -r '.networks[] | select(.name=="atlantic-testnet") | .chainId' assets/networks.json)
VERIFIER_URL=$(jq -r '.networks[] | select(.name=="atlantic-testnet") | .explorerApiUrl' assets/networks.json)
DEPLOYER=$(cast wallet address --private-key "$PRIVATE_KEY")

echo "Deployer : $DEPLOYER"
echo "Network  : atlantic-testnet ($CHAIN_ID)"
echo "Balance  : $(cast balance "$DEPLOYER" --rpc-url "$RPC") wei"
echo ""

echo "Deploying SafeRegistry..."
ADDR=$(forge create src/safecheck/SafeRegistry.sol:SafeRegistry \
  --rpc-url "$RPC" --private-key "$PRIVATE_KEY" --broadcast \
  --json | jq -r '.deployedTo')

echo "Deployed SafeRegistry at: $ADDR"

# Record for the skill to read at runtime.
cat > assets/safecheck/deployment.json <<EOF
{
  "network": "atlantic-testnet",
  "chainId": $CHAIN_ID,
  "SafeRegistry": "$ADDR",
  "deployer": "$DEPLOYER"
}
EOF
echo "Wrote assets/safecheck/deployment.json"

echo ""
echo "Verifying on explorer (Blockscout-compatible)..."
sleep 10
forge verify-contract "$ADDR" src/safecheck/SafeRegistry.sol:SafeRegistry \
  --verifier blockscout --verifier-url "$VERIFIER_URL" --chain-id "$CHAIN_ID" || \
  echo "Verification call returned non-zero — check explorer manually; deployment still succeeded."

echo ""
echo "Done. SafeRegistry: $ADDR"
echo "Explorer: $(jq -r '.networks[] | select(.name=="atlantic-testnet") | .explorerUrl' assets/networks.json)address/$ADDR"
