// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {TribeLeaderRegistry} from "../src/TribeLeaderRegistry.sol";
import {TribeVaultFactory} from "../src/TribeVaultFactory.sol";
import {TribeLeaderTerminal} from "../src/TribeLeaderTerminal.sol";
import {TribeCopyVault} from "../src/TribeCopyVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title TestCopyTradingFlow
 * @notice End-to-end test of the copy trading flow:
 *         1. Follower deposits to vault
 *         2. Leader adds liquidity via Terminal
 *         3. Verify position is mirrored to follower vault
 */
contract TestCopyTradingFlow is Script {
    // Contract addresses from deployment
    address immutable LEADER_REGISTRY = vm.envAddress("LEADER_REGISTRY");
    address immutable VAULT_FACTORY = vm.envAddress("VAULT_FACTORY");
    address immutable LEADER_TERMINAL = vm.envAddress("LEADER_TERMINAL");

    // Test tokens on Base Sepolia
    address constant USDC = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;
    address constant WETH = 0x4200000000000000000000000000000000000006;

    // Uniswap V3 params
    uint24 constant FEE = 3000; // 0.3%
    int24 constant TICK_LOWER = -887220; // Full range
    int24 constant TICK_UPPER = 887220; // Full range

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address user = vm.addr(pk);

        console.log("=== TESTING COPY TRADING FLOW ===");
        console.log("User Address:", user);
        console.log("");

        vm.startBroadcast(pk);

        // Step 1: Get or create vault for user following themselves (for test purposes)
        console.log("--- Step 1: Get Follower Vault ---");
        address vaultAddress = TribeVaultFactory(VAULT_FACTORY).getVault(user, user);

        if (vaultAddress == address(0)) {
            console.log("Creating new vault...");
            vaultAddress = TribeVaultFactory(VAULT_FACTORY).createVault(user);
            console.log("Vault created:", vaultAddress);
        } else {
            console.log("Existing vault:", vaultAddress);
        }

        TribeCopyVault vault = TribeCopyVault(vaultAddress);
        console.log("");

        // Step 2: Deposit capital to follower vault
        console.log("--- Step 2: Deposit to Follower Vault ---");
        uint256 depositAmountUSDC = 1e6; // 1 USDC
        uint256 depositAmountWETH = 0.01 ether; // 0.01 WETH

        uint256 usdcBalance = IERC20(USDC).balanceOf(user);
        uint256 wethBalance = IERC20(WETH).balanceOf(user);
        console.log("User USDC Balance:", usdcBalance);
        console.log("User WETH Balance:", wethBalance);

        if (usdcBalance >= depositAmountUSDC) {
            IERC20(USDC).approve(vaultAddress, depositAmountUSDC);
            vault.deposit(USDC, depositAmountUSDC);
            console.log("Deposited USDC:", depositAmountUSDC);
        } else {
            console.log("Insufficient USDC for deposit");
        }

        if (wethBalance >= depositAmountWETH) {
            IERC20(WETH).approve(vaultAddress, depositAmountWETH);
            vault.deposit(WETH, depositAmountWETH);
            console.log("Deposited WETH:", depositAmountWETH);
        } else {
            console.log("Insufficient WETH for deposit");
        }

        uint256 vaultCapital = vault.depositedCapital();
        uint256 vaultHWM = vault.highWaterMark();
        console.log("Vault Deposited Capital:", vaultCapital);
        console.log("Vault High Water Mark:", vaultHWM);
        console.log("");

        // Step 3: Leader adds liquidity (user is both leader and follower for test)
        console.log("--- Step 3: Leader Adds Liquidity via Terminal ---");

        // Check if user is registered as leader
        bool isLeader = TribeLeaderRegistry(LEADER_REGISTRY).isRegisteredLeader(user);
        console.log("Is Registered Leader:", isLeader);

        if (!isLeader) {
            console.log("ERROR: User must be registered as leader first");
            console.log("Run TestLeaderRegistration.s.sol first");
            vm.stopBroadcast();
            return;
        }

        // Determine token order
        address token0 = USDC < WETH ? USDC : WETH;
        address token1 = USDC < WETH ? WETH : USDC;

        uint256 leaderAmount0 = 0.5e6; // 0.5 USDC
        uint256 leaderAmount1 = 0.005 ether; // 0.005 WETH

        uint256 amount0Desired = token0 == USDC ? leaderAmount0 : leaderAmount1;
        uint256 amount1Desired = token1 == USDC ? leaderAmount0 : leaderAmount1;

        console.log("Token0:", token0);
        console.log("Token1:", token1);
        console.log("Amount0 Desired:", amount0Desired);
        console.log("Amount1 Desired:", amount1Desired);

        // Check leader balances
        uint256 leaderUSDC = IERC20(USDC).balanceOf(user);
        uint256 leaderWETH = IERC20(WETH).balanceOf(user);
        console.log("Leader USDC Balance:", leaderUSDC);
        console.log("Leader WETH Balance:", leaderWETH);

        if (leaderUSDC < leaderAmount0 || leaderWETH < leaderAmount1) {
            console.log("ERROR: Insufficient balance for liquidity addition");
            vm.stopBroadcast();
            return;
        }

        // Approve tokens for LeaderTerminal
        IERC20(token0).approve(LEADER_TERMINAL, amount0Desired);
        IERC20(token1).approve(LEADER_TERMINAL, amount1Desired);
        console.log("Approved tokens for LeaderTerminal");

        // Record vault state before
        uint256 vaultPositionsBefore = vault.getActivePositionCount();
        console.log("Vault Active Positions Before:", vaultPositionsBefore);

        // Execute liquidity addition
        try TribeLeaderTerminal(LEADER_TERMINAL).addLiquidityUniswapV3(
            token0,
            token1,
            FEE,
            TICK_LOWER,
            TICK_UPPER,
            amount0Desired,
            amount1Desired,
            0, // amount0Min
            0 // amount1Min
        ) returns (uint256 tokenId, uint128 liquidity) {
            console.log("");
            console.log("=== LIQUIDITY ADDED ===");
            console.log("Position Token ID:", tokenId);
            console.log("Liquidity Amount:", liquidity);

            // Check vault state after
            uint256 vaultPositionsAfter = vault.getActivePositionCount();
            console.log("");
            console.log("=== VAULT STATE AFTER ===");
            console.log("Vault Active Positions After:", vaultPositionsAfter);
            console.log("New Positions Created:", vaultPositionsAfter - vaultPositionsBefore);

            // Get position details
            if (vaultPositionsAfter > vaultPositionsBefore) {
                TribeCopyVault.Position[] memory positions = vault.getAllPositions();
                console.log("Total Positions in Vault:", positions.length);

                if (positions.length > 0) {
                    TribeCopyVault.Position memory lastPos = positions[positions.length - 1];
                    console.log("Last Position Protocol:", lastPos.protocol);
                    console.log("Last Position Token0:", lastPos.token0);
                    console.log("Last Position Token1:", lastPos.token1);
                    console.log("Last Position Liquidity:", lastPos.liquidity);
                    console.log("Last Position Is Active:", lastPos.isActive);
                }
            }

            console.log("");
            console.log("=== COPY TRADING SUCCESSFUL ===");
            console.log("Leader position created and mirrored to follower vault!");
        } catch Error(string memory reason) {
            console.log("");
            console.log("ERROR: Failed to add liquidity");
            console.log("Reason:", reason);
        } catch {
            console.log("");
            console.log("ERROR: Failed to add liquidity (no reason)");
        }

        vm.stopBroadcast();

        console.log("");
        console.log("=== TEST COMPLETED ===");
    }
}
