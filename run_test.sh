#!/bin/bash

# Source environment variables
export $(cat .env | xargs)

# Run the forge script
forge script script/TestCopyTradingFlow.s.sol \
  --fork-url $BASE_SEPOLIA_RPC_URL \
  -vvv \
  --broadcast \
  --private-key $PRIVATE_KEY