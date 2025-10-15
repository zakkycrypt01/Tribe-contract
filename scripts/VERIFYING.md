# Contract Verification Guide (Base Sepolia)

This repo is configured to verify contracts on Base Sepolia using Foundry Forge and BaseScan.

## Prerequisites
- Foundry installed
- Deployed contracts (addresses saved in `deployments/base-sepolia.txt`)
- BaseScan API key exported to your shell as `BASESCAN_API_KEY`

## One-time: set your API key
```bash
export BASESCAN_API_KEY=your_api_key_here
```

## Verify all core contracts
Foundry deduces constructor args automatically for contracts deployed in the same build graph. Run the following commands:

```bash
# Load the latest deployment addresses
set -a; source deployments/base-sepolia.txt; set +a

# Verify TribeLeaderRegistry
forge verify-contract \
  --chain 84532 \
  --watch \
  $LEADER_REGISTRY \
  src/TribeLeaderRegistry.sol:TribeLeaderRegistry

# Verify TribeVaultFactory
forge verify-contract \
  --chain 84532 \
  --watch \
  $VAULT_FACTORY \
  src/TribeVaultFactory.sol:TribeVaultFactory

# Verify TribeLeaderTerminal
forge verify-contract \
  --chain 84532 \
  --watch \
  $LEADER_TERMINAL \
  src/TribeLeaderTerminal.sol:TribeLeaderTerminal

# Verify TribeLeaderboard
forge verify-contract \
  --chain 84532 \
  --watch \
  $LEADERBOARD \
  src/TribeLeaderboard.sol:TribeLeaderboard

# Verify TribePerformanceTracker
forge verify-contract \
  --chain 84532 \
  --watch \
  $PERFORMANCE_TRACKER \
  src/TribePerformanceTracker.sol:TribePerformanceTracker

# Verify TribeUniswapV3Adapter
forge verify-contract \
  --chain 84532 \
  --watch \
  $UNISWAP_V3_ADAPTER \
  src/TribeUniswapV3Adapter.sol:TribeUniswapV3Adapter
```

Notes:
- If any verification fails due to constructor args, append `--constructor-args <hex-encoded>` using `cast abi-encode`.
- Ensure your `foundry.toml` has the etherscan section for Base Sepolia (it does).
- If your source path or contract name differ, adjust the path after `--contract` accordingly.

## Troubleshooting
- Missing API key: ensure `echo $BASESCAN_API_KEY` prints a value.
- Different bytecode: make sure you used the same compiler version and settings (solc 0.8.26, optimizer on, runs=200, via_ir=true).
- If re-deployments occurred, verify the latest addresses saved in `deployments/base-sepolia.txt`.
