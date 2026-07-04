#!/usr/bin/env bash
# Seed SafeRegistry with GENUINE attestations: for each known Pharos testnet token, probe
# its bytecode for dangerous function selectors, derive a real verdict, and record it
# on-chain. This gives the read-attestation flow real content and creates legitimate
# on-chain agent activity (not wash/spam — each attestation reflects an actual audit).
set -euo pipefail
cd "$(dirname "$0")/.."

[ -f .env.testnet ] && set -a && . ./.env.testnet && set +a
: "${PRIVATE_KEY:?Set PRIVATE_KEY (run scripts/setup-wallet.sh)}"

RPC=$(jq -r '.networks[] | select(.name=="atlantic-testnet") | .rpcUrl' assets/networks.json)
REGISTRY=$(jq -r '.SafeRegistry' assets/safecheck/deployment.json 2>/dev/null || true)
[ -z "${REGISTRY:-}" ] || [ "$REGISTRY" = "null" ] && { echo "No deployment.json — run scripts/deploy.sh first."; exit 1; }

# selector -> capability, with a risk weight
audit_token() {
  local TARGET="$1"
  local CODE SCORE=0 NOTES=""
  CODE=$(cast code "$TARGET" --rpc-url "$RPC" 2>/dev/null || echo "0x")
  if [ "$CODE" = "0x" ] || [ -z "$CODE" ]; then echo "EOA|0|no contract code"; return; fi
  # dangerous capability probes
  echo "$CODE" | grep -qi "40c10f19" && { SCORE=$((SCORE+25)); NOTES="$NOTES mint;"; }         # mint(address,uint256)
  echo "$CODE" | grep -qi "8456cb59" && { SCORE=$((SCORE+20)); NOTES="$NOTES pause;"; }        # pause()
  echo "$CODE" | grep -qi "f9f92be4" && { SCORE=$((SCORE+40)); NOTES="$NOTES blacklist;"; }    # blacklist(address)
  echo "$CODE" | grep -qi "fe575a87" && { SCORE=$((SCORE+15)); NOTES="$NOTES isBlacklisted;"; }  # isBlacklisted
  # active owner?
  local OWNER
  OWNER=$(cast call "$TARGET" "owner()(address)" --rpc-url "$RPC" 2>/dev/null || echo "")
  if [ -n "$OWNER" ] && [ "$OWNER" != "0x0000000000000000000000000000000000000000" ]; then
    SCORE=$((SCORE+20)); NOTES="$NOTES active-owner;"
  elif [ "$OWNER" = "0x0000000000000000000000000000000000000000" ]; then
    NOTES="$NOTES ownership-renounced;"
  fi
  [ "$SCORE" -gt 100 ] && SCORE=100
  # verdict: 1 Safe (<20), 2 Caution (20-59), 3 Danger (>=60)
  local V=1; [ "$SCORE" -ge 20 ] && V=2; [ "$SCORE" -ge 60 ] && V=3
  echo "${V}|${SCORE}|$(echo "$NOTES" | sed 's/^ *//;s/  */ /g' | cut -c1-200)"
}

echo "Seeding attestations from $(cast wallet address --private-key "$PRIVATE_KEY") -> $REGISTRY"
jq -r '."atlantic-testnet"[] | "\(.symbol) \(.address)"' assets/tokens.json | while read -r SYM TOKEN; do
  RESULT=$(audit_token "$TOKEN")
  V=$(echo "$RESULT" | cut -d'|' -f1); S=$(echo "$RESULT" | cut -d'|' -f2); N=$(echo "$RESULT" | cut -d'|' -f3)
  [ "$V" = "EOA" ] && { echo "skip $SYM (EOA)"; continue; }
  NOTE="${SYM}: ${N:-no dangerous patterns detected}"
  echo "attest $SYM ($TOKEN) verdict=$V score=$S note='$NOTE'"
  cast send "$REGISTRY" "attest(address,uint8,uint8,string)" "$TOKEN" "$V" "$S" "$NOTE" \
    --private-key "$PRIVATE_KEY" --rpc-url "$RPC" >/dev/null \
    && echo "  ok" || echo "  FAILED"
done
echo "Seed complete. Total attestations: $(cast call "$REGISTRY" "totalAttestations()(uint256)" --rpc-url "$RPC")"
