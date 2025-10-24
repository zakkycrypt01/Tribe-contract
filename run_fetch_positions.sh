#!/bin/bash

# This script runs the FetchPositionId.s.sol script using deployment information from base-sepolia.txt

# Load environment variables from .env file if it exists
if [ -f ".env" ]; then
    echo "Loading environment variables from .env file..."
    set -a
    source .env
    set +a
fi

# Load contract addresses from deployments file
echo "Loading contract addresses from deployments/base-sepolia.txt..."
set -a
source ./deployments/base-sepolia.txt
set +a

# Set additional required variables
export POSITION_MANAGER=0x27F971cb582BF9E50F397e4d29a5C7A34f11faA2  # Uniswap V3 Position Manager on Base Sepolia

# Check if required variables are provided
if [ -z "$USER_ADDRESS" ]; then
    echo "ERROR: USER_ADDRESS is not set!"
    echo "Please provide a user address to check for positions."
    echo "Example usage: USER_ADDRESS=0xYourAddress PRIVATE_KEY=your_private_key ./run_fetch_positions.sh"
    exit 1
fi

if [ -z "$PRIVATE_KEY" ]; then
    echo "ERROR: PRIVATE_KEY is not set!"
    echo "The script needs a private key to broadcast transactions (even though it won't make state changes)."
    echo "Example usage: USER_ADDRESS=0xYourAddress PRIVATE_KEY=your_private_key ./run_fetch_positions.sh"
    exit 1
fi

# RPC URL for Base Sepolia (use environment variable if available, otherwise use default)
RPC_URL=${BASE_SEPOLIA_RPC_URL:-"https://sepolia.base.org"}

# Scan configuration (optional)
export START_TOKEN_ID=${START_TOKEN_ID:-1}  # Default: start from token ID 1
export END_TOKEN_ID=${END_TOKEN_ID:-100}    # Default: check up to token ID 100 (reduced for faster scanning)
export SCAN_TYPE=${SCAN_TYPE:-"range"}      # Default: range-based scanning

# Print configuration
echo "========= CONFIGURATION =========="
echo "VAULT_FACTORY: $VAULT_FACTORY"
echo "LEADER_REGISTRY: $LEADER_REGISTRY"
echo "POSITION_MANAGER: $POSITION_MANAGER"
echo "USER_ADDRESS: $USER_ADDRESS"
echo "PRIVATE_KEY: [MASKED]"
echo "RPC_URL: $RPC_URL"
echo "START_TOKEN_ID: $START_TOKEN_ID"
echo "END_TOKEN_ID: $END_TOKEN_ID"
echo "SCAN_TYPE: $SCAN_TYPE"
echo "==============================="

# Run the script using Forge
echo "Running FetchPositionId script..."
forge script script/FetchPositionId.s.sol \
  --rpc-url $RPC_URL \
  --broadcast \
  --slow \
  --legacy \
  -vvv

echo "Script execution complete."