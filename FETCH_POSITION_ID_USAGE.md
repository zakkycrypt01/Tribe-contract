# FetchPositionId Script

This script fetches all position token IDs associated with a user address in the Tribe protocol.

## Overview

The `FetchPositionId.s.sol` script can:

1. Check if a user is a registered leader
2. Find all vaults associated with the user (as a follower)
3. List all active positions in those vaults
4. For leaders, scan for directly owned NFT positions 

## Prerequisites

- Foundry (Forge) installed
- Access to a Base Sepolia RPC URL
- A private key (for broadcasting the script, though no state changes are made)

## Usage

Run the script using the provided helper script:

```bash
USER_ADDRESS=0xYourAddress PRIVATE_KEY=your_private_key ./run_fetch_positions.sh
```

### Required Environment Variables

- `USER_ADDRESS`: The address to check for positions
- `PRIVATE_KEY`: Required for broadcasting (no state changes are made)

### Optional Environment Variables

- `BASE_SEPOLIA_RPC_URL`: Custom RPC URL (default: https://sepolia.base.org)
- `START_TOKEN_ID`: First token ID to check (default: 1)
- `END_TOKEN_ID`: Last token ID to check (default: 10000)
- `SCAN_TYPE`: Scanning strategy (`range` or `list`, default: range)

## Examples

### Check positions for a follower

```bash
USER_ADDRESS=0x123... PRIVATE_KEY=abc... ./run_fetch_positions.sh
```

### Check positions for a leader with custom scanning range

```bash
USER_ADDRESS=0x456... PRIVATE_KEY=def... START_TOKEN_ID=5000 END_TOKEN_ID=15000 ./run_fetch_positions.sh
```

### Use custom RPC URL

```bash
USER_ADDRESS=0x789... PRIVATE_KEY=ghi... BASE_SEPOLIA_RPC_URL="https://your-custom-rpc.com" ./run_fetch_positions.sh
```

## Script Output

The script outputs detailed information about:

1. Follower vaults and their active positions
2. Leader-owned NFT positions (if the user is a leader)
3. Summary of findings

For each position, it provides:
- Token IDs
- Protocol used
- Token pair information
- Liquidity amount
- Position status (active/inactive)