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

/**
 * @title TestAllContracts
 * @notice Comprehensive test of all Tribe protocol contract interfaces
 */
contract TestAllContracts is Script {
    // Contract addresses on Base Sepolia
    address constant LEADER_REGISTRY = 0xB28049beA41b96B54a8dA0Ee47C8F7209e820150;
    address constant VAULT_FACTORY = 0x54e6Cb2C7da3BB683f0653D804969609711B2740;
    address constant LEADER_TERMINAL = 0xE4E9D97664f1c74aEe1E6A83866E9749D32e02CE;
    address constant LEADERBOARD = 0xe27070fd257607aB185B83652C139aE38f997cbE;
    address constant PERFORMANCE_TRACKER = 0xdFbefEcD6A35078c409fd907E0FA03a33015A48e;
    address constant UNISWAP_V3_ADAPTER = 0x36888e432d41729B0978F89e71F1e523147E7CcC;

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
}
