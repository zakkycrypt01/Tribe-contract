#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/verify_all.sh [deployments-file]
# Default deployments file: deployments/base-sepolia.txt

DEP_FILE=${1:-deployments/base-sepolia.txt}
CHAIN_ID=84532

if [[ ! -f "$DEP_FILE" ]]; then
  echo "Deployments file not found: $DEP_FILE" >&2
  exit 1
fi

if [[ -z "${BASESCAN_API_KEY:-}" ]]; then
  echo "Missing BASESCAN_API_KEY in env. Export it first." >&2
  exit 1
fi

# Load addresses
set -a
source "$DEP_FILE"
set +a

# Foundry verify helper
verify() {
  local addr="$1";
  local fqcn="$2";
  echo "Verifying $fqcn at $addr";
  forge verify-contract \
    --chain "$CHAIN_ID" \
    --num-of-optimizations 200 \
    --watch \
    "$addr" \
    "$fqcn";
}

# Contracts and their FQCNs
verify "$LEADER_REGISTRY" src/TribeLeaderRegistry.sol:TribeLeaderRegistry
verify "$VAULT_FACTORY" src/TribeVaultFactory.sol:TribeVaultFactory
verify "$LEADER_TERMINAL" src/TribeLeaderTerminal.sol:TribeLeaderTerminal
verify "$LEADERBOARD" src/TribeLeaderboard.sol:TribeLeaderboard
verify "$PERFORMANCE_TRACKER" src/TribePerformanceTracker.sol:TribePerformanceTracker
verify "$UNISWAP_V3_ADAPTER" src/TribeUniswapV3Adapter.sol:TribeUniswapV3Adapter

echo "All verifications submitted."