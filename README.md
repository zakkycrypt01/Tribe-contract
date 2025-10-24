# TribeProtocol - BaseBatch 002 Buildathon

![Base](https://img.shields.io/badge/Base-Blockchain-blue)
![Solidity](https://img.shields.io/badge/Solidity-%5E0.8.20-363636)
![License](https://img.shields.io/badge/License-MIT-green)
[![Architecture](https://img.shields.io/badge/Architecture-Documented-brightgreen)](./ARCHITECTURE.md)

Key highlights:
- Non-custodial vault-per-follower model
- Modular DEX adapter layer (Uniswap V3, Aerodrome)
- LeaderRegistry + LeaderTerminal for onboarding & access control
- PerformanceTracker implements HWM and fee calculation
- VaultFactory creates isolated follower vaults for mirrored positions

---

# Architecture — TribeProtocol

## Overview
TribeProtocol is a modular, permissionless copy-trading stack designed for Base. It separates concerns into on-chain registries, factories, adapter-driven execution, and a performance accounting layer to enable trustless, proportional copying of on-chain liquidity and swaps.

## Components
- VaultFactory
    - Produces lightweight, per-follower CopyVaults.
    - Ensures isolation of funds and per-vault accounting.
- CopyVault (per follower)
    - Holds follower assets.
    - Executes adapter-driven actions to mirror leader positions proportionally.
- LeaderRegistry
    - Stores leader profiles, KYC-free identity, and eligibility flags.
    - Tracks leader metadata and performance constraints.
- LeaderTerminal
    - Governance point for leader actions (signal start/stop, withdraw, metadata updates).
    - Facilitates followers subscribing to leaders.
- DEX Adapters
    - Adapter interface implemented per DEX (Uniswap V3, Aerodrome).
    - Encapsulates protocol-specific calls: mint/burn, swap, collect, manage ticks.
- PerformanceTracker
    - Calculates High Water Mark (HWM), realized/unrealized PnL, and performance fees.
    - Emits events for fee settlement and leader eligibility checks.
- Registry Data Feeds / Oracles (optional)
    - Price oracles for fair valuation and PnL calculations when needed.

## Data & Control Flows

1. Leader Onboarding
     - Leader registers via LeaderRegistry with parameters (fee %, min performance, metadata).
     - LeaderTerminal may enforce staked deposit or reputation checks.

2. Follower Subscription
     - User creates a CopyVault via VaultFactory or reuses an existing vault.
     - Follower subscribes to a leader through LeaderTerminal; VaultFactory links the vault to the leader.

3. Leader Trade Execution
     - Leader executes actions on supported DEXes via their standard interfaces.
     - Adapters listen/verify leader actions or leader emits signed intent (on-chain or off-chain relay).

4. Mirroring Flow
     - A scheduler or caller (keeper) triggers mirroring:
         - PerformanceTracker computes proportional amounts for followers based on vault balances and leader position delta.
         - Vaults call the appropriate DEX Adapter to replicate leader actions (mint liquidity, swap, etc.).
     - All actions are executed from the follower's vault — non-custodial.

5. Performance & Fee Settlement
     - On realized profit events or periodic checkpoints, PerformanceTracker computes fees using HWM.
     - Fees are collected in-protocol and distributed to leader and protocol treasury per config.

## Adapter Interface (abstract)
- function execute(bytes actionData) external returns (uint256[] results);
- function estimateCost(bytes actionData) external view returns (uint256 gasEstimate, address[] assets);
- Implementations must:
    - Validate calldata origins and params
    - Return normalized results (asset deltas)
    - Prevent reentrancy and slippage exploits

## Security Considerations
- Least-privilege vault design: vaults only grant adapters and protocol contracts permission to operate on their funds when mirroring.
- Reentrancy guards on all state-mutating entrypoints.
- Slippage controls and deadline parameters for DEX calls.
- On-chain limits and circuit-breakers for large leader actions.
- Regular audits, fuzz testing, and property-based tests (Foundry).

## Extensibility
- New DEXs: implement Adapter interface and register with LeaderTerminal.
- New fee models: customize PerformanceTracker hooks for subscription fees, tiered splits, or profit share.
- Off-chain indexers: optional event-indexer to power dashboards and analytics.

## Deployment & Testing
- Deploy order: LeaderRegistry -> PerformanceTracker -> VaultFactory -> Adapters -> LeaderTerminal.
- Foundry tests cover:
    - Vault isolation and permissioning
    - Proportional mirroring across varying follower sizes
    - Fee calculation against HWM invariants
    - Adapter integration tests against forked DEX contracts

## Diagrams (ASCII)

Leader onboarding/update
LeaderRegistry <--- LeaderTerminal

Follower flow
Follower -> VaultFactory -> CopyVault
CopyVault --subscribe--> LeaderTerminal

Mirroring
Leader action -> Adapter interface -> CopyVault (executes replicated action)
CopyVault -> PerformanceTracker (updates PnL & fees)

## Operational Notes
- Use a keeper or cron-like relayer to trigger mirroring in near real-time.
- Monitor oracle health and pause mirroring if oracles are stale.
- Provide clear UI warning about latency and slippage risks to followers.

## References
- Adapter spec: required function signatures and event set
- Performance model: HWM algorithm and fee settlement examples (see tests)
- Testing checklist: integration, edge-cases, malicious leader scenarios

## 🌟 Project Overview

TribeProtocol is a decentralized copy trading protocol built for Base, enabling users to automatically mirror the trading positions of successful DeFi traders. Built during the BaseBatch 002 Buildathon, it introduces innovative solutions for decentralized social trading.

### 🎯 Key Features

- **Automated Position Mirroring**: Real-time copying of leader trading positions
- **Non-Custodial Design**: Each follower has their own dedicated vault
- **Multi-DEX Support**: Supports Uniswap V3 and Aerodrome
- **Performance-Based System**: Leaders must maintain profitability metrics
- **Transparent Fee Structure**: Performance fees only on realized profits

## 📋 Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Architecture](./ARCHITECTURE.md)
- [Test Results](./output.md)
- [Contract Addresses](#contract-addresses)
- [Tech Stack](#tech-stack)
- [Contributing](#contributing)
- [License](#license)

## 🛠 Installation

```bash
# Clone the repository
git clone https://github.com/zakkycrypt01/Tribe-contract.git

# Install dependencies
forge install

# Copy environment file
cp .env.example .env

# Set up your environment variables
# Edit .env with your values
```

## 🚀 Quick Start

### Deploy Contracts
```bash
# Deploy to Base Sepolia testnet
forge script script/Deploy.s.sol --rpc-url base_sepolia --broadcast

# Run comprehensive tests
forge script script/TestAllContracts.s.sol --rpc-url base_sepolia --broadcast
```

### Test Copy Trading Flow
```bash
# Run the copy trading test flow
./run_test.sh
```

## 📍 Contract Addresses (Base Sepolia)

- **LeaderRegistry**: `0xE73Eb839A848237E53988F0d74b069763aC38fE3`
- **VaultFactory**: `0xdEc456e502CB9baB4a33153206a470B65Bedcf9E`
- **LeaderTerminal**: `0x5b9118131ff1F1c8f097828182E0560241CB9BA1`
- **UniswapV3Adapter**: `0x8b1192C386A778EBD27AB0317b81d1D9DB00CccA`
- **PerformanceTracker**: `0x79733De3CbD67A434469a77c7FACE852EC1ac8A1`

## 💻 Tech Stack

- **Smart Contracts**: Solidity ^0.8.20
- **Development Framework**: Foundry
- **Networks**: Base Sepolia
- **DEX Integrations**: 
  - Uniswap V3
  - Aerodrome

## 🌟 BaseBatch 002 Submission Details

### Problem Statement
DeFi traders lack a trustless way to monetize their trading expertise, while newer users struggle to replicate successful trading strategies.

### Solution
TribeProtocol creates a permissionless, non-custodial copy trading infrastructure that:
- Allows successful traders to earn performance fees
- Enables automatic position mirroring
- Ensures fair compensation through high water mark calculations
- Provides complete transparency and on-chain verification

### Innovation Points
1. **Real NFT Position Mirroring**: True ownership of Uniswap V3 positions
2. **Proportional Copy Trading**: Automatic scaling based on follower capital
3. **Multi-DEX Architecture**: Extensible adapter system for multiple DEXs
4. **Performance-Gated Leadership**: Maintains high-quality leader pool

## 🧪 Testing

Comprehensive test results available in [output.md](./output.md)

```bash
# Run all tests
forge test -vvv

# Run specific test
forge test --match-test testCopyTradingFlow -vvv
```

## 🏗 Architecture

Detailed architecture documentation available in [architecture.md](./architecture.md)

Key components:
- Vault Factory & Copy Vaults
- Leader Registry & Terminal
- DEX Adapters (Uniswap V3, Aerodrome)
- Performance Tracking System

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏆 BaseBatch 002 Team

- **Lead Developer**: @zakkycrypt01
- **Project Track**: DeFi Infrastructure
- **Submission Date**: October 24, 2025

## 📞 Contact

- **Discord**: TribeProtocol
- **Twitter**: @TribeProtocol
- **Email**: tribe@protocol.com

## 🙏 Acknowledgments

- Base Blockchain Team
- BaseBatch 002 Organizers
- Uniswap V3 Team
- Aerodrome Team
