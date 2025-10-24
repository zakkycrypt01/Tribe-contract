#!/bin/bash
# Script to run the FetchPositionId.s.sol script with proper parameters

# Ensure .env file exists
if [ ! -f .env ]; then
  echo "Error: .env file not found"
  exit 1
fi

# Source the .env file to get environment variables
source .env

# Define deployment file
DEPLOYMENT_FILE="deployments/base-sepolia.txt"

# Check if deployment file exists
if [ ! -f "$DEPLOYMENT_FILE" ]; then
  echo "Error: Deployment file $DEPLOYMENT_FILE not found"
  exit 1
fi

# User address from command line or default
USER_ADDRESS=${1:-"0x109260B1e1b907C3f2CC4d55e9e7AB043CB82D17"}

# Extract RPC URL from .env
RPC_URL=${BASE_SEPOLIA_RPC_URL:-"https://sepolia.base.org"}

# Configure token ID range
START_TOKEN_ID=${2:-1}
END_TOKEN_ID=${3:-100000}

echo "Fetching positions for address: $USER_ADDRESS"
echo "Scanning token IDs from $START_TOKEN_ID to $END_TOKEN_ID"
echo "Using RPC URL: $RPC_URL"

# Run the forge script
export USER_ADDRESS="$USER_ADDRESS"
export START_TOKEN_ID="$START_TOKEN_ID" 
export END_TOKEN_ID="$END_TOKEN_ID"

forge script script/FetchPositionId.s.sol \
  --fork-url "$RPC_URL" \
  -vvv \
  --broadcast \
  --slow \
  --sig "run()" \
  --private-key "$PRIVATE_KEY"

echo "Script execution completed."