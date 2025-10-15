// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title CheckBalances
 * @notice Check token balances and provide faucet information
 */
contract CheckBalances is Script {
    // Test tokens on Base Sepolia
    address constant USDC = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;
    address constant WETH = 0x4200000000000000000000000000000000000006;

    function run() external view {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address user = vm.addr(pk);

        console.log("=== TOKEN BALANCES ===");
        console.log("Address:", user);
        console.log("");

        uint256 ethBalance = user.balance;
        uint256 usdcBalance = IERC20(USDC).balanceOf(user);
        uint256 wethBalance = IERC20(WETH).balanceOf(user);

        console.log("ETH Balance (wei):", ethBalance);
        console.log("ETH Balance (ETH):", ethBalance / 1e18);
        console.log("USDC Balance (raw):", usdcBalance);
        console.log("USDC Balance (USDC):", usdcBalance / 1e6);
        console.log("WETH Balance (wei):", wethBalance);
        console.log("WETH Balance (WETH):", wethBalance / 1e18);
        console.log("");

        // Check if sufficient for testing
        uint256 requiredUSDC = 113e6; // 100 for vault + 10 for liquidity + buffer
        uint256 requiredWETH = 0.013 ether; // 0.01 for vault + 0.003 for liquidity + buffer

        console.log("=== REQUIREMENTS ===");
        console.log("Required USDC:", requiredUSDC / 1e6, "USDC");
        console.log("Required WETH:", requiredWETH / 1e18, "WETH");
        console.log("");

        if (usdcBalance >= requiredUSDC && wethBalance >= requiredWETH) {
            console.log("[OK] SUFFICIENT BALANCE - Ready to test copy trading flow");
        } else {
            console.log("[ERROR] INSUFFICIENT BALANCE");
            console.log("");
            console.log("=== HOW TO GET TEST TOKENS ===");
            console.log("");
            console.log("1. Base Sepolia ETH Faucet:");
            console.log("   https://www.alchemy.com/faucets/base-sepolia");
            console.log("");
            console.log("2. Wrap ETH to WETH:");
            console.log(
                "   Visit: https://sepolia.basescan.org/address/0x4200000000000000000000000000000000000006#writeContract"
            );
            console.log("   Call: deposit() with value");
            console.log("");
            console.log("3. Get USDC from Aave Faucet:");
            console.log("   Visit: https://staging.aave.com/faucet/");
            console.log("   Select Base Sepolia network");
            console.log("   Request USDC tokens");
            console.log("");
            console.log("OR use the WrapETH.s.sol script:");
            console.log("   forge script script/WrapETH.s.sol:WrapETH --rpc-url base_sepolia --broadcast");
        }
    }
}
