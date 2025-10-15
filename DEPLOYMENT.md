# Tribe Protocol - Base Sepolia Deployment

## Prerequisites

1. **Install Foundry** (if not already installed):
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

2. **Get Base Sepolia ETH**:
   - Visit [Base Sepolia Faucet](https://www.alchemy.com/faucets/base-sepolia)
   - Or use the [Coinbase Wallet Faucet](https://portal.cdp.coinbase.com/products/faucet)

3. **Set up your environment variables**:
```bash
cp .env.example .env
# Edit .env and add your PRIVATE_KEY and BASESCAN_API_KEY
```

## Build the Project

```bash
forge build
```

## Run Tests

```bash
forge test
```

## Deploy to Base Sepolia

1. **Simulate deployment** (dry run):
```bash
forge script script/Deploy.s.sol --rpc-url base_sepolia
```

2. **Deploy contracts**:
```bash
forge script script/Deploy.s.sol --rpc-url base_sepolia --broadcast --verify
```

If you encounter gas estimation issues, you can set a gas limit:
```bash
forge script script/Deploy.s.sol --rpc-url base_sepolia --broadcast --verify --gas-limit 30000000
```

3. **Verify contracts manually** (if auto-verification fails):
```bash
forge verify-contract <CONTRACT_ADDRESS> <CONTRACT_NAME> --chain-id 84532 --etherscan-api-key $BASESCAN_API_KEY
```

## Deployed Contracts

After deployment, contract addresses will be saved to `deployments/base-sepolia.txt`.

### Core Contracts:
- **TribeLeaderRegistry**: Leader registration and qualification
- **TribeVaultFactory**: Creates follower vaults
- **TribeLeaderTerminal**: Leader action execution hub

### Auxiliary Contracts:
- **TribeLeaderboard**: Rankings and statistics
- **TribePerformanceTracker**: Performance metrics

### Adapters:
- **TribeUniswapV3Adapter**: Uniswap V3 integration
- **TribeAerodromeAdapter**: Aerodrome integration

## Important Addresses (Base Sepolia)

- **Uniswap V3 Position Manager**: `0x27F971cb582BF9E50F397e4d29a5C7A34f11faA2`
- **Chainlink ETH/USD**: `0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1`

## Security Notes

- ⚠️ **NEVER commit your `.env` file**
- ⚠️ Keep your private key secure
- ⚠️ Use a separate wallet for testnet deployments
- ⚠️ Double-check all addresses before deploying to mainnet

## Troubleshooting

### "Insufficient funds for gas"
Make sure your wallet has enough Base Sepolia ETH from the faucet.

### "Failed to get EIP-1559 fees"
Add `--legacy` flag to use legacy transactions:
```bash
forge script script/Deploy.s.sol --rpc-url base_sepolia --broadcast --legacy
```

### Contract verification fails
Try verifying manually with the command above, or check your BASESCAN_API_KEY.

## Next Steps

After deployment:
1. Register leaders using `TribeLeaderRegistry.registerLeader()`
2. Leaders can set their strategy details
3. Followers can create vaults via `TribeVaultFactory.createVault()`
4. Leaders execute strategies through `TribeLeaderTerminal`

For more information, see the contract documentation in the `src/` directory.
