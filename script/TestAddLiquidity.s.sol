// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {TribeLeaderTerminal} from "../src/TribeLeaderTerminal.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TestAddLiquidity is Script {
    // Set via environment: export LEADER_TERMINAL=0x...
    address immutable LEADER_TERMINAL = vm.envAddress("LEADER_TERMINAL");
    // Base Sepolia token addresses
    address constant WETH = 0x4200000000000000000000000000000000000006; // WETH on Base Sepolia
    address constant USDC = 0x036CbD53842c5426634e7929541eC2318f3dCF7e; // USDC on Base Sepolia
    uint24 constant FEE = 3000; // 0.3% fee tier
    int24 constant TICK_LOWER = -887220; // Full range for safety
    int24 constant TICK_UPPER = 887220; // Full range for safety
    uint256 constant AMOUNT_WETH_DESIRED = 0.001 ether; // 0.001 WETH
    uint256 constant AMOUNT_USDC_DESIRED = 3e6; // 3 USDC (6 decimals)
    uint256 constant AMOUNT0_MIN = 0;
    uint256 constant AMOUNT1_MIN = 0;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);

        // Determine token order (Uniswap requires token0 < token1)
        address token0 = USDC < WETH ? USDC : WETH;
        address token1 = USDC < WETH ? WETH : USDC;
        uint256 amount0Desired = token0 == USDC ? AMOUNT_USDC_DESIRED : AMOUNT_WETH_DESIRED;
        uint256 amount1Desired = token1 == USDC ? AMOUNT_USDC_DESIRED : AMOUNT_WETH_DESIRED;

        console.log("Adding liquidity with:");
        console.log("Token0:", token0);
        console.log("Token1:", token1);
        console.log("Amount0:", amount0Desired);
        console.log("Amount1:", amount1Desired);

        // Approve tokens for LeaderTerminal
        IERC20(token0).approve(LEADER_TERMINAL, amount0Desired);
        console.log("Approved token0");
        IERC20(token1).approve(LEADER_TERMINAL, amount1Desired);
        console.log("Approved token1");

        // Call addLiquidityUniswapV3
        try TribeLeaderTerminal(LEADER_TERMINAL).addLiquidityUniswapV3(
            token0, token1, FEE, TICK_LOWER, TICK_UPPER, amount0Desired, amount1Desired, AMOUNT0_MIN, AMOUNT1_MIN
        ) returns (uint256 tokenId, uint128 liquidity) {
            console.log("Liquidity position created. TokenId:", tokenId, "Liquidity:", liquidity);
        } catch {
            console.log("Failed to create liquidity position. Check token balances and approvals.");
        }

        vm.stopBroadcast();
    }
}
