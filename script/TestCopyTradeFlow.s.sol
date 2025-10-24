// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {TribeVaultFactory} from "../src/TribeVaultFactory.sol";
import {TribeCopyVault} from "../src/TribeCopyVault.sol";
import {TribeLeaderRegistry} from "../src/TribeLeaderRegistry.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title TestCopyTradeFlow
 * @notice Demonstrates the complete copy trading flow:
 * 1. Check if leader is registered
 * 2. Approve tokens
 * 3. Create vault (if not exists)
 * 4. Deposit funds into vault
 * 5. Verify vault balance
 */
contract TestCopyTradeFlow is Script {
    // Environment variables
    address immutable VAULT_FACTORY = vm.envAddress("VAULT_FACTORY");
    address immutable LEADER_REGISTRY = vm.envAddress("LEADER_REGISTRY");

    // Base Sepolia token addresses
    address constant USDC = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;
    address constant WETH = 0x4200000000000000000000000000000000000006;

    function run() external {
        uint256 followerPk = vm.envUint("PRIVATE_KEY");
        address follower = vm.addr(followerPk);
        
        // For this demo, follower is copying themselves as leader
        // In production, this would be a different leader address
        address leader = follower;

        vm.startBroadcast(followerPk);

        console.log("=== COPY TRADE FLOW TEST ===");
        console.log("Follower Address:", follower);
        console.log("Leader Address:", leader);
        console.log("");

        // Step 1: Verify leader is registered
        console.log("Step 1: Checking if leader is registered...");
        bool isRegistered = TribeLeaderRegistry(LEADER_REGISTRY).isRegisteredLeader(leader);
        require(isRegistered, "Leader is not registered");
        console.log("[OK] Leader is registered");
        console.log("");

        // Step 2: Check follower's token balances
        console.log("Step 2: Checking follower balances...");
        uint256 usdcBalance = IERC20(USDC).balanceOf(follower);
        uint256 wethBalance = IERC20(WETH).balanceOf(follower);
        console.log("USDC Balance:", usdcBalance);
        console.log("WETH Balance:", wethBalance);
        console.log("");

        // For this test, let's use available amounts
        uint256 depositAmountUSDC = usdcBalance > 0 ? 1 : 0; // Use 1 unit if available
        uint256 depositAmountWETH = 0.00001 ether; // 0.00001 WETH

        require(wethBalance >= depositAmountWETH, "Insufficient WETH balance");
        if (depositAmountUSDC > 0) {
            require(usdcBalance >= depositAmountUSDC, "Insufficient USDC balance");
        }

        // Step 3: Check if vault exists, create if not
        console.log("Step 3: Checking/Creating vault...");
        address vaultAddress = TribeVaultFactory(VAULT_FACTORY).getVault(follower, leader);
        
        if (vaultAddress == address(0)) {
            console.log("Vault does not exist. Creating vault...");
            // Note: Performance fee is automatically taken from leader's registration
            TribeVaultFactory(VAULT_FACTORY).createVault(leader);
            vaultAddress = TribeVaultFactory(VAULT_FACTORY).getVault(follower, leader);
            console.log("[OK] Vault created at:", vaultAddress);
        } else {
            console.log("[OK] Vault already exists at:", vaultAddress);
        }
        console.log("");

        TribeCopyVault vault = TribeCopyVault(vaultAddress);

        // Step 4: Approve vault to spend tokens
        console.log("Step 4: Approving tokens for vault...");
        if (depositAmountUSDC > 0) {
            IERC20(USDC).approve(vaultAddress, depositAmountUSDC);
            console.log("[OK] USDC approved:", depositAmountUSDC);
        }
        IERC20(WETH).approve(vaultAddress, depositAmountWETH);
        console.log("[OK] WETH approved:", depositAmountWETH);
        console.log("");

        // Step 5: Deposit USDC into vault (if available)
        if (depositAmountUSDC > 0) {
            console.log("Step 5a: Depositing USDC into vault...");
            uint256 vaultUsdcBefore = IERC20(USDC).balanceOf(vaultAddress);
            console.log("Vault USDC balance before:", vaultUsdcBefore);
            
            vault.deposit(USDC, depositAmountUSDC);
            
            uint256 vaultUsdcAfter = IERC20(USDC).balanceOf(vaultAddress);
            console.log("Vault USDC balance after:", vaultUsdcAfter);
            console.log("[OK] USDC deposited:", depositAmountUSDC);
            console.log("");
        } else {
            console.log("Step 5a: Skipping USDC deposit (insufficient balance)");
            console.log("");
        }

        // Step 6: Deposit WETH into vault
        console.log("Step 5b: Depositing WETH into vault...");
        uint256 vaultWethBefore = IERC20(WETH).balanceOf(vaultAddress);
        console.log("Vault WETH balance before:", vaultWethBefore);
        
        vault.deposit(WETH, depositAmountWETH);
        
        uint256 vaultWethAfter = IERC20(WETH).balanceOf(vaultAddress);
        console.log("Vault WETH balance after:", vaultWethAfter);
        console.log("[OK] WETH deposited:", depositAmountWETH);
        console.log("");

        // Step 7: Verify vault accounting
        console.log("Step 7: Verifying vault accounting...");
        uint256 depositedCapital = vault.depositedCapital();
        uint256 highWaterMark = vault.highWaterMark();
        console.log("Deposited Capital:", depositedCapital);
        console.log("High Water Mark:", highWaterMark);
        console.log("Total USDC in Vault:", vault.getVaultValue(USDC));
        console.log("Total WETH in Vault:", vault.getVaultValue(WETH));
        console.log("Active Positions:", vault.getActivePositionCount());
        console.log("");

        // Step 8: Display vault details
        console.log("Step 8: Vault configuration...");
        console.log("Follower:", vault.FOLLOWER());
        console.log("Leader:", vault.LEADER());
        console.log("Terminal:", vault.TERMINAL());
        console.log("Performance Fee %:", vault.performanceFeePercent());
        console.log("Emergency Mode:", vault.emergencyMode());
        console.log("");

        vm.stopBroadcast();

        console.log("=== COPY TRADE SETUP COMPLETE ===");
        console.log("");
        console.log("Summary:");
        console.log("- Vault created and funded successfully");
        console.log("- USDC deposited (in wei):", depositAmountUSDC);
        console.log("- WETH deposited (in wei):", depositAmountWETH);
        console.log("- Vault is now ready to mirror leader's trades");
        console.log("");
        console.log("Next Steps:");
        console.log("1. Leader creates positions via TribeLeaderTerminal");
        console.log("2. Vault automatically mirrors positions proportionally");
        console.log("3. Follower can withdraw anytime via vault.withdraw()");
    }
}
