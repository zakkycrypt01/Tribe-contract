// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/TribeLeaderRegistry.sol";
import "../src/TribeVaultFactory.sol";
import "../src/TribeLeaderTerminal.sol";
import "../src/TribeLeaderboard.sol";
import "../src/TribePerformanceTracker.sol";
import "../src/TribeUniswapV3Adapter.sol";
import "../src/TribeCopyVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title TestAllContracts
 * @notice Comprehensive test of all Tribe protocol contract interfaces
 */
contract TestAllContracts is Script {
    // Contract addresses on Base Sepolia - set via env after deployment
    address immutable LEADER_REGISTRY = vm.envAddress("LEADER_REGISTRY");
    address immutable VAULT_FACTORY = vm.envAddress("VAULT_FACTORY");
    address immutable LEADER_TERMINAL = vm.envAddress("LEADER_TERMINAL");
    address immutable LEADERBOARD = vm.envAddress("LEADERBOARD");
    address immutable PERFORMANCE_TRACKER = vm.envAddress("PERFORMANCE_TRACKER");
    address immutable UNISWAP_V3_ADAPTER = vm.envAddress("UNISWAP_V3_ADAPTER");

    // Protocol addresses
    address constant UNISWAP_V3_POSITION_MANAGER = 0x27F971cb582BF9E50F397e4d29a5C7A34f11faA2;

    // Test tokens on Base Sepolia
    address constant USDC = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;
    address constant WETH = 0x4200000000000000000000000000000000000006;

    // Test leader address (deployer)
    address testLeader;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        testLeader = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        console.log("=== COMPREHENSIVE CONTRACT INTERFACE TEST ===");
        console.log("Test Leader Address:", testLeader);
        console.log("");

        // Test 1: Leader Registry
        testLeaderRegistry();

        // Test 2: Vault Factory
        testVaultFactory();

        // Test 3: Leader Terminal
        testLeaderTerminal();

        // Test 4: Leaderboard
        testLeaderboard();

        // Test 5: Performance Tracker
        testPerformanceTracker();

        // Test 6: Uniswap V3 Adapter
        testUniswapV3Adapter();

        // Test 7: Real Uniswap Position Creation
        testRealUniswapPosition();

        vm.stopBroadcast();

        console.log("");
        console.log("=== ALL TESTS COMPLETED ===");
    }

    function testLeaderRegistry() internal {
        console.log("--- Testing TribeLeaderRegistry ---");

        TribeLeaderRegistry registry = TribeLeaderRegistry(LEADER_REGISTRY);

        // Test: Check if leader is registered
        bool isRegistered = registry.isRegisteredLeader(testLeader);
        console.log("Is Leader Registered:", isRegistered);

        if (isRegistered) {
            // Test: Get leader details
            TribeLeaderRegistry.Leader memory leader = registry.getLeader(testLeader);
            console.log("Strategy Name:", leader.strategyName);
            console.log("Description:", leader.description);
            console.log("Is Active:", leader.isActive);
            console.log("Performance Fee (bps):", leader.performanceFeePercent);
            console.log("Total Followers:", leader.totalFollowers);
            console.log("Total TVL:", leader.totalTvl);

            // Test: Get historical positions
            TribeLeaderRegistry.HistoricalPosition[] memory history = registry.getLeaderHistory(testLeader);
            console.log("Historical Positions Count:", history.length);

            // Test: Calculate profitability
            uint256 profitability = registry.calculateProfitability(testLeader);
            console.log("Profitability Percentage:", profitability);
        }

        // Test: Get all leaders
        address[] memory allLeaders = registry.getAllLeaders();
        console.log("Total Leaders in System:", allLeaders.length);

        console.log("");
    }

    function testVaultFactory() internal {
        console.log("--- Testing TribeVaultFactory ---");

        TribeVaultFactory factory = TribeVaultFactory(VAULT_FACTORY);

        // Test: Get vault for leader-follower pair
        address vault = factory.getVault(testLeader, testLeader);
        console.log("Vault Address:", vault);

        if (vault != address(0)) {
            // Test: Check if valid vault
            bool isValid = factory.isValidVault(vault);
            console.log("Is Valid Vault:", isValid);

            // Test: Get vault details
            TribeCopyVault copyVault = TribeCopyVault(vault);
            console.log("Vault Follower:", copyVault.FOLLOWER());
            console.log("Vault Leader:", copyVault.LEADER());
            console.log("Vault Terminal:", copyVault.TERMINAL());
            console.log("Performance Fee %:", copyVault.performanceFeePercent());
            console.log("Deposited Capital:", copyVault.depositedCapital());
            console.log("High Water Mark:", copyVault.highWaterMark());
            console.log("Emergency Mode:", copyVault.emergencyMode());

            // Test: Get vault value
            uint256 usdcBalance = copyVault.getVaultValue(USDC);
            uint256 wethBalance = copyVault.getVaultValue(WETH);
            console.log("USDC Balance:", usdcBalance);
            console.log("WETH Balance:", wethBalance);

            // Test: Get active positions
            uint256 activePositions = copyVault.getActivePositionCount();
            console.log("Active Positions:", activePositions);
        }

        // Test: Get leader vaults
        address[] memory leaderVaults = factory.getLeaderVaults(testLeader);
        console.log("Leader's Follower Vaults Count:", leaderVaults.length);

        // Test: Get leader follower count
        uint256 followerCount = factory.getLeaderFollowerCount(testLeader);
        console.log("Leader Follower Count:", followerCount);

        // Test: Get all vaults
        address[] memory allVaults = factory.getAllVaults();
        console.log("Total Vaults in System:", allVaults.length);

        // Test: Get leader TVL
        uint256 tvl = factory.getLeaderTvl(testLeader, USDC);
        console.log("Leader TVL (USDC):", tvl);

        console.log("");
    }

    function testLeaderTerminal() internal {
        console.log("--- Testing TribeLeaderTerminal ---");

        TribeLeaderTerminal terminal = TribeLeaderTerminal(LEADER_TERMINAL);

        // Test: Get protocol addresses
        console.log("Uniswap V3 Position Manager:", terminal.uniswapV3PositionManager());
        console.log("Aerodrome Router:", terminal.aerodromeRouter());

        // Test: Get leader actions
        TribeLeaderTerminal.Action[] memory actions = terminal.getLeaderActions(testLeader);
        console.log("Total Leader Actions:", actions.length);

        if (actions.length > 0) {
            // Test: Get latest action
            TribeLeaderTerminal.Action memory latestAction = terminal.getLatestAction(testLeader);
            console.log("Latest Action Type:", uint256(latestAction.actionType));
            console.log("Latest Action Protocol:", latestAction.protocol);
            console.log("Latest Action Token0:", latestAction.token0);
            console.log("Latest Action Token1:", latestAction.token1);
            console.log("Latest Action Amount0:", latestAction.amount0);
            console.log("Latest Action Amount1:", latestAction.amount1);
            console.log("Latest Action Timestamp:", latestAction.timestamp);
            console.log("Latest Action Gas Used:", latestAction.gasUsed);

            // Test: Get total gas used
            uint256 totalGas = terminal.getTotalGasUsed(testLeader);
            console.log("Total Gas Used by Leader:", totalGas);
        }

        console.log("");
    }

    function testLeaderboard() internal {
        console.log("--- Testing TribeLeaderboard ---");

        TribeLeaderboard leaderboard = TribeLeaderboard(LEADERBOARD);

        // Test: Get leader profile
        TribeLeaderboard.LeaderProfile memory profile = leaderboard.getLeaderProfile(testLeader);
        console.log("Profile - Strategy Name:", profile.strategyName);
        console.log("Profile - Net APR (bps):", profile.netApr);
        console.log("Profile - Total Fees Earned:", profile.totalFeesEarned);
        console.log("Profile - Total TVL:", profile.totalTvl);
        console.log("Profile - Risk Score:", profile.riskScore);
        console.log("Profile - Max Drawdown:", profile.maxDrawdown);
        console.log("Profile - Total Followers:", profile.totalFollowers);
        console.log("Profile - Performance Fee %:", profile.performanceFeePercent);
        console.log("Profile - Is Active:", profile.isActive);
        console.log("Profile - Registration Time:", profile.registrationTime);

        // Test: Get all leader profiles
        TribeLeaderboard.LeaderProfile[] memory allProfiles = leaderboard.getAllLeaderProfiles();
        console.log("Total Leader Profiles:", allProfiles.length);

        // Test: Get top leaders by Net APR (limit 5)
        TribeLeaderboard.LeaderProfile[] memory topByApr =
            leaderboard.getTopLeaders(TribeLeaderboard.RankingCriteria.NET_APR, 5);
        console.log("Top Leaders by APR:", topByApr.length);

        // Test: Get top leaders by TVL
        TribeLeaderboard.LeaderProfile[] memory topByTvl =
            leaderboard.getTopLeaders(TribeLeaderboard.RankingCriteria.TOTAL_TVL, 5);
        console.log("Top Leaders by TVL:", topByTvl.length);

        // Test: Filter by risk level
        TribeLeaderboard.LeaderProfile[] memory lowRisk = leaderboard.filterByRiskLevel(TribeLeaderboard.RiskLevel.LOW);
        console.log("Low Risk Leaders:", lowRisk.length);

        // Test: Filter by minimum APR (10% = 1000 bps)
        TribeLeaderboard.LeaderProfile[] memory highApr = leaderboard.filterByMinApr(1000);
        console.log("Leaders with APR > 10%:", highApr.length);

        // Test: Calculate risk-adjusted return
        uint256 riskAdjusted = leaderboard.calculateRiskAdjustedReturn(testLeader);
        console.log("Risk-Adjusted Return:", riskAdjusted);

        // Test: Get leader stats (skipping due to struct return complexity)
        console.log("Stats - Available via getLeaderProfile() above");

        console.log("");
    }

    function testPerformanceTracker() internal {
        console.log("--- Testing TribePerformanceTracker ---");

        TribePerformanceTracker tracker = TribePerformanceTracker(PERFORMANCE_TRACKER);

        // Test: Get leader metrics
        TribePerformanceTracker.PerformanceMetrics memory metrics = tracker.getLeaderMetrics(testLeader);
        console.log("Metrics - Total Fees Earned:", metrics.totalFeesEarned);
        console.log("Metrics - Net APR (bps):", metrics.netApr);
        console.log("Metrics - Total Volume:", metrics.totalVolume);
        console.log("Metrics - Max Drawdown:", metrics.maxDrawdown);
        console.log("Metrics - Risk Score:", metrics.riskScore);
        console.log("Metrics - Last Updated:", metrics.lastUpdated);

        // Test: Get leader snapshots
        TribePerformanceTracker.Snapshot[] memory snapshots = tracker.getLeaderSnapshots(testLeader);
        console.log("Total Snapshots:", snapshots.length);

        if (snapshots.length > 0) {
            console.log("Latest Snapshot - Timestamp:", snapshots[snapshots.length - 1].timestamp);
            console.log("Latest Snapshot - Total Value:", snapshots[snapshots.length - 1].totalValue);
            console.log("Latest Snapshot - Fees Collected:", snapshots[snapshots.length - 1].feesCollected);
        }

        // Test: Calculate APR
        uint256 apr = tracker.calculateLeaderApr(testLeader);
        console.log("Calculated APR:", apr);

        // Test: Calculate 30-day APR
        uint256 apr30d = tracker.calculate30DayApr(testLeader);
        console.log("30-Day APR:", apr30d);

        // Test: Calculate max drawdown
        uint256 maxDrawdown = tracker.calculateMaxDrawdown(testLeader);
        console.log("Max Drawdown:", maxDrawdown);

        // Test: Calculate risk score
        uint256 riskScore = tracker.calculateRiskScore(testLeader);
        console.log("Risk Score:", riskScore);

        console.log("");
    }

    function testUniswapV3Adapter() internal {
        console.log("--- Testing TribeUniswapV3Adapter ---");

        TribeUniswapV3Adapter adapter = TribeUniswapV3Adapter(UNISWAP_V3_ADAPTER);

        // Test: Get position manager address
        console.log("Position Manager:", address(adapter.POSITION_MANAGER()));

        // Test: Calculate proportional amounts
        (uint256 amount0, uint256 amount1) = adapter.calculateProportionalAmounts(
            1000000, // total liquidity
            100000, // vault share (10%)
            5000000, // amount0
            2000000 // amount1
        );
        console.log("Proportional Amount0:", amount0);
        console.log("Proportional Amount1:", amount1);

        console.log("");
    }

    function testRealUniswapPosition() internal {
        console.log("--- Testing Real Uniswap V3 Position Creation ---");

        uint24 FEE = 3000; // 0.3%
        int24 TICK_LOWER = -887220; // Full range
        int24 TICK_UPPER = 887220; // Full range
        uint256 AMOUNT_USDC = 3e6; // 3 USDC
        uint256 AMOUNT_WETH = 0.001 ether; // 0.001 WETH

        // Check balances
        uint256 usdcBalance = IERC20(USDC).balanceOf(testLeader);
        uint256 wethBalance = IERC20(WETH).balanceOf(testLeader);
        console.log("USDC Balance:", usdcBalance);
        console.log("WETH Balance:", wethBalance);

        if (usdcBalance < AMOUNT_USDC || wethBalance < AMOUNT_WETH) {
            console.log("Insufficient balance for real position test. Skipping...");
            console.log("");
            return;
        }

        // Determine token order (token0 < token1)
        address token0 = USDC < WETH ? USDC : WETH;
        address token1 = USDC < WETH ? WETH : USDC;
        uint256 amount0Desired = token0 == USDC ? AMOUNT_USDC : AMOUNT_WETH;
        uint256 amount1Desired = token1 == USDC ? AMOUNT_USDC : AMOUNT_WETH;

        console.log("");
        console.log("Token0:", token0);
        console.log("Token1:", token1);
        console.log("Amount0:", amount0Desired);
        console.log("Amount1:", amount1Desired);

        // Approve Uniswap Position Manager
        IERC20(token0).approve(UNISWAP_V3_POSITION_MANAGER, amount0Desired);
        IERC20(token1).approve(UNISWAP_V3_POSITION_MANAGER, amount1Desired);
        console.log("");
        console.log("Approved tokens");

        // Mint position
        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: token0,
            token1: token1,
            fee: FEE,
            tickLower: TICK_LOWER,
            tickUpper: TICK_UPPER,
            amount0Desired: amount0Desired,
            amount1Desired: amount1Desired,
            amount0Min: 0,
            amount1Min: 0,
            recipient: testLeader,
            deadline: block.timestamp + 300
        });

        (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) =
            INonfungiblePositionManager(UNISWAP_V3_POSITION_MANAGER).mint(params);

        console.log("");
        console.log("=== POSITION CREATED ===");
        console.log("Token ID:", tokenId);
        console.log("Liquidity:", liquidity);
        console.log("Amount0 Used:", amount0);
        console.log("Amount1 Used:", amount1);

        // Query the position
        (
            ,
            ,
            address posToken0,
            address posToken1,
            uint24 posFee,
            int24 posTickLower,
            int24 posTickUpper,
            uint128 posLiquidity,
            ,
            ,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        ) = INonfungiblePositionManager(UNISWAP_V3_POSITION_MANAGER).positions(tokenId);

        console.log("");
        console.log("=== POSITION DETAILS ===");
        console.log("Token0:", posToken0);
        console.log("Token1:", posToken1);
        console.log("Fee Tier:", posFee);
        console.log("Tick Lower:", uint256(int256(posTickLower)));
        console.log("Tick Upper:", uint256(int256(posTickUpper)));
        console.log("Liquidity:", posLiquidity);
        console.log("Tokens Owed0:", tokensOwed0);
        console.log("Tokens Owed1:", tokensOwed1);

        console.log("");
        console.log("SUCCESS: Real Uniswap V3 position created on-chain!");
        console.log("View on BaseScan:");
        console.log("https://sepolia.basescan.org/nft/", UNISWAP_V3_POSITION_MANAGER, "/", tokenId);

        console.log("");
    }
}
