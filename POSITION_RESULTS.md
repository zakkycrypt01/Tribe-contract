# Position Fetching Results

## User: 0x109260B1e1b907C3f2CC4d55e9e7AB043CB82D17

### Status
- ✅ Registered Leader in the Tribe protocol
- ❌ Not a follower (no follower vaults found)

### Positions Summary
Found **4 Uniswap V3 NFT positions** owned directly by this user.

### Position Details

#### Position 1
- Token ID: 71193
- Pair: 0x036CbD53842c5426634e7929541eC2318f3dCF7e / 0xcbB7C0006F23900c38EB856149F799620fcb8A4a
- Fee Tier: 500
- Liquidity: 290
- Status: Active
- Price Range: -887220 to 887220

#### Position 2
- Token ID: 71195
- Pair: 0x036CbD53842c5426634e7929541eC2318f3dCF7e / 0xcbB7C0006F23900c38EB856149F799620fcb8A4a
- Fee Tier: 500
- Liquidity: 290
- Status: Active
- Price Range: -887220 to 887220

#### Position 3
- Token ID: 71196
- Pair: 0x036CbD53842c5426634e7929541eC2318f3dCF7e / 0xcbB7C0006F23900c38EB856149F799620fcb8A4a
- Fee Tier: 500
- Liquidity: 290
- Status: Active
- Price Range: -887220 to 887220

#### Position 4
- Token ID: 71201
- Pair: 0x036CbD53842c5426634e7929541eC2318f3dCF7e / 0xcbB7C0006F23900c38EB856149F799620fcb8A4a
- Fee Tier: 500
- Liquidity: 290
- Status: Active
- Price Range: -887220 to 887220

## Notes
All positions are identical in terms of token pair, fee tier, liquidity amount, and price range. This suggests they might have been created as part of a batch or testing process.

## How to Run the Script
```bash
# Run for the default address
./script/run_fetch_positions.sh

# Run for a specific address
./script/run_fetch_positions.sh 0xYourAddressHere

# Run with custom token ID range
./script/run_fetch_positions.sh 0xYourAddressHere 1000 5000
```

The script supports:
- Checking if an address is a registered leader
- Finding leader positions (directly owned NFTs)
- Finding follower positions (in copy vaults)
- Scanning specific token ID ranges