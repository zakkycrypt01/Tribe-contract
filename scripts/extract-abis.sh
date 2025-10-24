#!/bin/bash

# Create the abis directory if it doesn't exist
mkdir -p abis

# Extract ABIs from the out directory
echo "Extracting TribeVaultFactory ABI..."
jq .abi out/TribeVaultFactory.sol/TribeVaultFactory.json > abis/TribeVaultFactory.json

echo "Extracting TribeCopyVault ABI..."
jq .abi out/TribeCopyVault.sol/TribeCopyVault.json > abis/TribeCopyVault.json

echo "Extracting IERC20 ABI..."
jq .abi out/IERC20.sol/IERC20.json > abis/IERC20.json

echo "Done extracting ABIs"