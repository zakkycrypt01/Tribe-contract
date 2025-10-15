// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface INonfungiblePositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    function mint(MintParams calldata params)
        external
        payable
        returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
}

/**
 * @title TestRealUniswapPosition
 * @notice Test creating an ACTUAL Uniswap V3 liquidity position on-chain
 */
contract TestRealUniswapPosition is Script {
    address constant UNISWAP_V3_POSITION_MANAGER = 0x27F971cb582BF9E50F397e4d29a5C7A34f11faA2;
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant USDC = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;

    uint24 constant FEE = 3000; // 0.3%
    int24 constant TICK_LOWER = -887220; // Full range
    int24 constant TICK_UPPER = 887220; // Full range
    uint256 constant AMOUNT_USDC = 3e6; // 3 USDC
    uint256 constant AMOUNT_WETH = 0.001 ether; // 0.001 WETH

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(pk);

        console.log("=== CREATING REAL UNISWAP V3 POSITION ===");
        console.log("Deployer:", deployer);
        console.log("");

        vm.startBroadcast(pk);

        // Check balances
        uint256 usdcBalance = IERC20(USDC).balanceOf(deployer);
        uint256 wethBalance = IERC20(WETH).balanceOf(deployer);
        console.log("USDC Balance:", usdcBalance);
        console.log("WETH Balance:", wethBalance);

        require(usdcBalance >= AMOUNT_USDC, "Insufficient USDC");
        require(wethBalance >= AMOUNT_WETH, "Insufficient WETH");

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
            recipient: deployer,
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

        vm.stopBroadcast();
    }
}
