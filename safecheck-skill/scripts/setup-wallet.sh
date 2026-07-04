#!/usr/bin/env bash
# Generate a THROWAWAY testnet wallet for deploying SafeRegistry on Pharos Atlantic testnet.
# This key is for testnet only. Never send mainnet funds to it.
set -euo pipefail
cd "$(dirname "$0")/.."

ENV_FILE=".env.testnet"
if [ -f "$ENV_FILE" ]; then
  echo "$ENV_FILE already exists — refusing to overwrite. Delete it first to regenerate."
  ADDR=$(grep -oP '(?<=DEPLOYER=).*' "$ENV_FILE" || true)
  echo "Existing deployer: ${ADDR:-unknown}"
  exit 0
fi

echo "Generating throwaway testnet wallet..."
OUT=$(cast wallet new)
PK=$(echo "$OUT"  | grep -oiP '(?<=Private key: ).*')
ADDR=$(echo "$OUT" | grep -oiP '(?<=Address: ).*')

cat > "$ENV_FILE" <<EOF
# THROWAWAY Pharos Atlantic testnet wallet — testnet only, do not fund with real assets.
PRIVATE_KEY=$PK
DEPLOYER=$ADDR
EOF
chmod 600 "$ENV_FILE"

echo "Wallet created (saved to $ENV_FILE, gitignored, chmod 600)."
echo "Deployer address: $ADDR"
echo ""
echo "NEXT: fund this address with testnet PHRS from the Pharos faucet, then run scripts/deploy.sh"
