# Copy Trading Flow - Complete Guide

## Overview

This document explains the complete copy trading flow in the Tribe Protocol, demonstrating how funds are deposited into vaults and how the system works.

## ✅ Successful Test Results

**Vault Created:** `0xc8c309E34ef4fd87d869dd6E856934E3497A8965`  
**Network:** Base Sepolia  
**Block:** 32,440,222

### Deposits Made:
- **USDC:** 1 unit (smallest possible)
- **WETH:** 10000000000000 wei (0.00001 WETH)

### Vault Configuration:
- **Follower:** 0x73D43dd9Ac2C0Fd004286F7a13F51bec163efB2C
- **Leader:** 0x73D43dd9Ac2C0Fd004286F7a13F51bec163efB2C
- **Performance Fee:** 10% (1000 basis points)
- **Emergency Mode:** false

---

## ✅ Correct Copy Trading Flow

### High-Level Flow:
```
1. User clicks "Copy Trade" on UI
2. User enters amount to invest
3. User approves token spending (ERC20 approval transaction)
4. Backend/Frontend calls:
   a) VaultFactory.createVault(leaderAddress) ← NOTE: Only leader address
   b) Vault.deposit(token, amount) - Transfer funds from user to vault
5. Vault now has capital to mirror leader's trades
```

**Key Point:** The performance fee is NOT passed to `createVault()`. It's automatically retrieved from the leader's registration in the LeaderRegistry.

---

## Detailed Step-by-Step Flow

### Step 1: User Initiates Copy Trade (UI)
```
User clicks "Copy Trade" on a leader's profile
├── Selects amount to invest (e.g., 100 USDC)
├── Chooses tokens to deposit (USDC, WETH, etc.)
└── Reviews performance fee (already set by leader during registration)
```

### Step 2: Frontend Pre-Checks
```javascript
// Check if leader is registered
const isRegistered = await leaderRegistry.isRegisteredLeader(leaderAddress);
if (!isRegistered) throw new Error("Leader not registered");

// Check user's token balances
const usdcBalance = await usdc.balanceOf(userAddress);
const wethBalance = await weth.balanceOf(userAddress);

// Verify sufficient balance
if (usdcBalance < depositAmount) throw new Error("Insufficient balance");
```

### Step 3: Check if Vault Exists
```javascript
// Check if follower already has a vault for this leader
const vaultAddress = await vaultFactory.getVault(followerAddress, leaderAddress);

if (vaultAddress === ZERO_ADDRESS) {
    // Vault doesn't exist, needs to be created
    needsVaultCreation = true;
}
```

### Step 4: User Approves Token Spending
```javascript
// User must approve vault to spend their tokens
// This is a separate transaction that user signs
await usdc.approve(vaultAddress, depositAmount);
await weth.approve(vaultAddress, depositAmount);
```

### Step 5: Create Vault (if needed)
```solidity
// Called by follower
// Performance fee is NOT passed - it's automatically fetched from leader's registration
vaultFactory.createVault(leaderAddress);

// Internally:
// 1. Verifies leader is registered and active
// 2. Fetches leader's performanceFeePercent from LeaderRegistry
// 3. Creates vault with that fee
// 4. Returns new vault address
```

### Step 6: Deposit Funds into Vault
```solidity
// Called by follower
// Transfers tokens FROM follower TO vault
vault.deposit(tokenAddress, amount);

// Internal vault accounting:
// 1. Transfer tokens from follower to vault
// 2. Update depositedCapital += amount
// 3. Set highWaterMark (for first deposit)
// 4. Emit Deposited event
```

### Step 7: Vault is Ready
```
Vault State:
├── Has capital (USDC/WETH/etc)
├── Linked to leader
├── Ready to mirror trades
└── Follower can withdraw anytime
```

---

## Smart Contract Flow

### 1. VaultFactory.createVault()
```solidity
function createVault(address leader) external returns (address vault) {
    // Verify leader is registered and active
    require(LEADER_REGISTRY.isRegisteredLeader(leader), "Leader not registered");
    
    // ✅ IMPORTANT: Performance fee is fetched from leader's registration
    // NOT passed as a parameter!
    Leader memory leaderData = LEADER_REGISTRY.getLeader(leader);
    require(leaderData.isActive, "Leader not active");
    
    // Deploy new vault with leader's fee from registry
    TribeCopyVault newVault = new TribeCopyVault(
        msg.sender,                      // follower
        leader,                          // leader
        Terminal,                        // terminal contract
        leaderData.performanceFeePercent // ← Fee from leader's registration
    );
    
    // Store mapping: follower => leader => vault
    followerVaults[msg.sender][leader] = vault;
    
    return vault;
}
```

### 2. TribeCopyVault.deposit()
```solidity
function deposit(address token, uint256 amount) external onlyFollower {
    // Transfer tokens FROM follower TO vault
    IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    
    // Update accounting
    depositedCapital += amount;
    
    // Set high water mark on first deposit
    if (highWaterMark == 0) {
        highWaterMark = depositedCapital;
    }
    
    emit Deposited(msg.sender, amount);
}
```

---

## Mirroring Trades (How Copy Trading Works)

### When Leader Creates a Position:

```solidity
// 1. Leader calls Terminal to add liquidity
terminal.addLiquidityUniswapV3(token0, token1, fee, amount0, amount1, ...);

// 2. Terminal creates position for leader
//    AND mirrors to all follower vaults

// 3. For each follower vault:
for (vault in leaderVaults) {
    // Calculate proportional amounts based on vault capital
    proportionalAmount0 = (amount0 * vaultCapital) / leaderCapital;
    proportionalAmount1 = (amount1 * vaultCapital) / leaderCapital;
    
    // Mirror position in vault
    vault.mirrorPosition(protocol, token0, token1, liquidity, data);
}
```

### Vault Mirroring:
```solidity
function mirrorPosition(
    address protocol,
    address token0,
    address token1,
    uint256 liquidity,
    bytes calldata data
) external onlyTerminal {
    // Record position metadata
    positions.push(Position({
        protocol: protocol,
        token0: token0,
        token1: token1,
        liquidity: liquidity,
        tokenId: 0, // Set for Uniswap V3
        isActive: true
    }));
    
    // Track as active
    activePositions[positionId] = true;
    
    emit PositionMirrored(protocol, token0, token1, liquidity);
}
```

---

## Withdrawal Flow

### User Withdraws from Vault:

```solidity
function withdraw(address token, uint256 amount) external onlyFollower {
    uint256 vaultBalance = IERC20(token).balanceOf(address(this));
    require(vaultBalance >= amount, "Insufficient balance");
    
    // Calculate performance fee (FIXED - proportional to withdrawal)
    uint256 performanceFee = 0;
    if (vaultBalance > highWaterMark) {
        uint256 totalProfit = vaultBalance - highWaterMark;
        uint256 realizedProfit = (totalProfit * amount) / vaultBalance;
        performanceFee = (realizedProfit * performanceFeePercent) / 10000;
        
        // Transfer fee to leader
        IERC20(token).safeTransfer(LEADER, performanceFee);
    }
    
    // Transfer remaining to follower
    uint256 followerAmount = amount - performanceFee;
    IERC20(token).safeTransfer(FOLLOWER, followerAmount);
    
    // Update accounting
    depositedCapital -= followerAmount;
    highWaterMark -= (amount - performanceFee);
}
```

---

## Frontend Integration Example

```javascript
// Complete Copy Trade Flow
async function startCopyTrading(leaderAddress, depositAmountUSDC, depositAmountWETH) {
    const follower = await signer.getAddress();
    
    // Step 1: Check leader registration
    const isRegistered = await leaderRegistry.isRegisteredLeader(leaderAddress);
    if (!isRegistered) throw new Error("Leader not registered");
    
    // Step 2: Check/Create vault
    let vaultAddress = await vaultFactory.getVault(follower, leaderAddress);
    
    if (vaultAddress === ethers.constants.AddressZero) {
        // Create vault
        const tx = await vaultFactory.createVault(leaderAddress);
        await tx.wait();
        
        // Get new vault address
        vaultAddress = await vaultFactory.getVault(follower, leaderAddress);
    }
    
    const vault = await ethers.getContractAt("TribeCopyVault", vaultAddress);
    
    // Step 3: Approve tokens
    if (depositAmountUSDC > 0) {
        const approveTx = await usdc.approve(vaultAddress, depositAmountUSDC);
        await approveTx.wait();
    }
    
    if (depositAmountWETH > 0) {
        const approveTx = await weth.approve(vaultAddress, depositAmountWETH);
        await approveTx.wait();
    }
    
    // Step 4: Deposit funds
    if (depositAmountUSDC > 0) {
        const depositTx = await vault.deposit(USDC_ADDRESS, depositAmountUSDC);
        await depositTx.wait();
    }
    
    if (depositAmountWETH > 0) {
        const depositTx = await vault.deposit(WETH_ADDRESS, depositAmountWETH);
        await depositTx.wait();
    }
    
    return {
        vaultAddress,
        deposited: {
            usdc: depositAmountUSDC,
            weth: depositAmountWETH
        }
    };
}
```

---

## Key Points

### ✅ Correct Flow:
1. User selects leader and amount on UI
2. Frontend checks leader is registered
3. Frontend creates vault (if needed)
4. User approves token spending
5. **Funds are transferred FROM user TO vault**
6. Vault is now funded and ready to mirror trades
7. Terminal mirrors leader's positions proportionally

### ❌ What Doesn't Happen Automatically:
- Vault creation does NOT automatically deposit funds
- Leader's trades do NOT automatically fund follower vaults
- Users must explicitly deposit into their vaults

### 🔐 Security Features (Post-Audit Fixes):
- ✅ Proportional performance fees (only on realized profit)
- ✅ Access control on metrics updates
- ✅ Token recovery via sweep function
- ✅ Hardened Chainlink validation
- ✅ Safe token approvals

---

## Example UI Flow

```
┌─────────────────────────────────────┐
│  Leader Profile Page                │
│  ─────────────────────────          │
│  Strategy: "Updated Strategy"       │
│  APR: 0% | Risk: Low                │
│  Performance Fee: 10%               │
│                                     │
│  [Copy Trade] Button                │
└─────────────────────────────────────┘
           ↓ (User clicks)
┌─────────────────────────────────────┐
│  Copy Trade Modal                   │
│  ─────────────────────────          │
│  Deposit Amount:                    │
│  USDC: [100] Max: 1000              │
│  WETH: [0.01] Max: 0.5              │
│                                     │
│  Performance Fee: 10%               │
│  Estimated Annual Cost: $X          │
│                                     │
│  [Approve USDC] → [Approve WETH]    │
│  [Start Copy Trading]               │
└─────────────────────────────────────┘
           ↓ (Transactions)
┌─────────────────────────────────────┐
│  Success!                           │
│  ─────────────────────────          │
│  Vault Created: 0xc8c3...           │
│  Deposited: 100 USDC, 0.01 WETH     │
│                                     │
│  You are now copying this leader    │
│  [View My Vault]                    │
└─────────────────────────────────────┘
```

---

## Deployed Contract Addresses (Base Sepolia)

- **TribeLeaderRegistry:** `0xE73Eb839A848237E53988F0d74b069763aC38fE3`
- **TribeVaultFactory:** `0xdEc456e502CB9baB4a33153206a470B65Bedcf9E`
- **TribeLeaderTerminal:** `0x5b9118131ff1F1c8f097828182E0560241CB9BA1`
- **Test Vault:** `0xc8c309E34ef4fd87d869dd6E856934E3497A8965`

---

## Next Steps for Full System Test

1. Leader creates Uniswap V3 position via Terminal
2. Vault automatically mirrors the position
3. Follower can view position details
4. Follower can withdraw funds (with performance fee if profitable)

**The copy trading fund deposit flow is now complete and tested! 🎉**
