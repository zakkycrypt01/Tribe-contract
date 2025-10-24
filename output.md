# Copy Trading Flow Test Results

## Test Overview
Test completed successfully on October 24, 2025, on Base Sepolia testnet.

## Test Steps Results

### 1. Vault Setup
- User Address: `0x73D43dd9Ac2C0Fd004286F7a13F51bec163efB2C`
- Vault Address: `0xc8c309E34ef4fd87d869dd6E856934E3497A8965` (existing vault)

### 2. Initial Deposits
#### Token Balances Before
- USDC Balance: 5,899,993
- WETH Balance: 10,000,000,009,992

#### Successful Deposits
- USDC Deposited: 1,000,000 (1 USDC)
- WETH Deposited: 10,000,000,000 (0.00001 WETH)

#### Vault State After Deposits
- Total Deposited Capital: 60,010,002,000,009
- High Water Mark: 1
- WETH Balance After: 9,990,000,009,992

### 3. Leader Liquidity Addition
#### Setup
- Leader Registration Status: ✅ Registered
- Token Order:
  - Token0: `0x036CbD53842c5426634e7929541eC2318f3dCF7e` (USDC)
  - Token1: `0x4200000000000000000000000000000000000006` (WETH)

#### Liquidity Parameters
- Amount0 (USDC): 500,000 (0.5 USDC)
- Amount1 (WETH): 5,000,000,000 (0.000005 WETH)
- WETH-only Mode: false

#### Balance Verification
- Token0 (USDC):
  - Required: 500,000
  - Available: 4,899,993 ✅
- Token1 (WETH):
  - Required: 5,000,000,000
  - Available: 9,990,000,009,992 ✅

### 4. Position Creation Results
#### Leader Position
- Position Token ID: 71265
- Liquidity Amount: 9,413

#### Follower Vault Position
- Active Positions Before: 1
- Active Positions After: 2
- New Positions Created: 1

#### Last Position Details
- Protocol: `0x27F971cb582BF9E50F397e4d29a5C7A34f11faA2` (Uniswap V3 Position Manager)
- Token0: `0x036CbD53842c5426634e7929541eC2318f3dCF7e` (USDC)
- Token1: `0x4200000000000000000000000000000000000006` (WETH)
- Liquidity: 56,487,897
- Status: Active ✅

## Transaction Details
### Gas Usage and Costs
- Total Transactions: 7
- Total Gas Used: 1,431,382
- Average Gas Price: 0.001000075 gwei
- Total Cost: 0.00000143148935365 ETH

### Transaction Hashes
1. `0x211065eb891b9c97183da89f586a1d1a7d3b110d38595187d3daa2253fb4992a`
2. `0x3418adf932071431c7dacdf88525c25bfffd75dd063777fb8dfb1d54682e7148`
3. `0x8bb06310899064724a73c8e841a2857503f09a70cba8ce316e19e937ade2667a`
4. `0x5934070d7912b600f6246a455a0f5f28fb7a531f70068e6aefb820b62ebfb3ed`
5. `0x28e1c6d7bd9385c4d88fb9d091bb19bff8e44fdd5ef6d757991ad44a3d3feaee`
6. `0xf579b5fd724029ef797e028eb79a66ed7dc1c153ac57680b92f23daec8a1ab99`
7. `0x0d6916be87c25b9048792051d881954069e60dbd12714c5f3b9d3c08be6f54a9`

### Block Information
- Block Number: 32771094
- Network: Base Sepolia (Chain ID: 84532)

## Conclusion
✅ COPY TRADING SUCCESSFUL - Leader position created and mirrored to follower vault!

The test demonstrates successful:
1. Vault deposits
2. Leader position creation
3. Automatic position mirroring to follower vault
4. Gas-efficient transaction execution