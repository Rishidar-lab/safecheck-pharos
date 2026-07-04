#!/usr/bin/env bash
# Orchestrate the full agent-to-agent x402 loop:
#   facilitator (settles) -> SafeCheck seller (paid /audit) -> caller (pays & invokes)
# Prereqs: cp .env.example .env and fill keys; fund FACILITATOR wallet with PHRS gas and
# the CALLER wallet with testnet USDC.
set -euo pipefail
cd "$(dirname "$0")"

[ -f .env ] || { echo "Create .env from .env.example first."; exit 1; }

echo "Starting facilitator..."
npx tsx facilitator.ts & FAC=$!
echo "Starting SafeCheck seller..."
npx tsx server.ts & SRV=$!
trap 'kill $FAC $SRV 2>/dev/null || true' EXIT

# wait for both health endpoints
FAC_PORT=$(grep -E '^FACILITATOR_PORT=' .env | cut -d= -f2); FAC_PORT=${FAC_PORT:-4022}
SRV_PORT=$(grep -E '^PORT=' .env | cut -d= -f2); SRV_PORT=${SRV_PORT:-4021}
for i in $(seq 1 40); do
  sleep 0.5
  curl -sf "http://localhost:$FAC_PORT/health" >/dev/null 2>&1 \
    && curl -sf "http://localhost:$SRV_PORT/health" >/dev/null 2>&1 && break
done

echo "Running caller (paid agent-to-agent audits)..."
npx tsx client.ts

echo "A2A loop complete."
