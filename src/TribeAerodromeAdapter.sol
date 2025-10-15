// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IAerodromeRouter {
    function addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function pairFor(address tokenA, address tokenB, bool stable) external view returns (address pair);
}

interface IAerodromePair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function stable() external view returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function getReserves() external view returns (uint256 reserve0, uint256 reserve1, uint256 blockTimestampLast);
    function claimFees() external returns (uint256 claimed0, uint256 claimed1);
}

/**
 * @title TribeAerodromeAdapter
 * @notice Adapter for interacting with Aerodrome Finance V2-style liquidity pools
 * @dev Handles fungible LP token management for Aerodrome
 */
contract TribeAerodromeAdapter {
    using SafeERC20 for IERC20;

    // Aerodrome interfaces

    IAerodromeRouter public immutable ROUTER;

    constructor(address _router) {
        require(_router != address(0), "Invalid router");
        ROUTER = IAerodromeRouter(_router);
    }

    /**
     * @notice Add liquidity to an Aerodrome pool
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address recipient
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        // Approve tokens
        IERC20(tokenA).approve(address(ROUTER), amountADesired);
        IERC20(tokenB).approve(address(ROUTER), amountBDesired);

        return ROUTER.addLiquidity(
            tokenA, tokenB, stable, amountADesired, amountBDesired, amountAMin, amountBMin, recipient, block.timestamp
        );
    }

    /**
     * @notice Remove liquidity from an Aerodrome pool
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address recipient
    ) external returns (uint256 amountA, uint256 amountB) {
        // Get pair address
        address pair = ROUTER.pairFor(tokenA, tokenB, stable);

        // Approve LP tokens
        IERC20(pair).approve(address(ROUTER), liquidity);

        return ROUTER.removeLiquidity(
            tokenA, tokenB, stable, liquidity, amountAMin, amountBMin, recipient, block.timestamp
        );
    }

    /**
     * @notice Swap tokens through Aerodrome
     */
    function swapTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address recipient)
        external
        returns (uint256[] memory amounts)
    {
        // Approve input token
        IERC20(path[0]).approve(address(ROUTER), amountIn);

        return ROUTER.swapExactTokensForTokens(amountIn, amountOutMin, path, recipient, block.timestamp);
    }

    /**
     * @notice Claim accumulated fees from a pool
     */
    function claimFees(address tokenA, address tokenB, bool stable)
        external
        returns (uint256 claimed0, uint256 claimed1)
    {
        address pair = ROUTER.pairFor(tokenA, tokenB, stable);
        return IAerodromePair(pair).claimFees();
    }

    /**
     * @notice Get pair address for tokens
     */
    function getPair(address tokenA, address tokenB, bool stable) external view returns (address) {
        return ROUTER.pairFor(tokenA, tokenB, stable);
    }

    /**
     * @notice Get reserves for a pair
     */
    function getReserves(address tokenA, address tokenB, bool stable)
        external
        view
        returns (uint256 reserve0, uint256 reserve1)
    {
        address pair = ROUTER.pairFor(tokenA, tokenB, stable);
        (reserve0, reserve1,) = IAerodromePair(pair).getReserves();
    }

    /**
     * @notice Get LP token balance
     */
    function getLpBalance(address tokenA, address tokenB, bool stable, address account)
        external
        view
        returns (uint256)
    {
        address pair = ROUTER.pairFor(tokenA, tokenB, stable);
        return IAerodromePair(pair).balanceOf(account);
    }

    /**
     * @notice Calculate proportional LP tokens for vault
     */
    function calculateProportionalLp(uint256 totalLpTokens, uint256 vaultShare, uint256 totalShares)
        external
        pure
        returns (uint256)
    {
        if (totalShares == 0) return 0;
        return (totalLpTokens * vaultShare) / totalShares;
    }

    /**
     * @notice Get quote for adding liquidity
     */
    function quoteLiquidity(address tokenA, address tokenB, bool stable, uint256 amountA)
        external
        view
        returns (uint256 amountB)
    {
        address pair = ROUTER.pairFor(tokenA, tokenB, stable);
        (uint256 reserve0, uint256 reserve1,) = IAerodromePair(pair).getReserves();

        address token0 = IAerodromePair(pair).token0();

        if (tokenA == token0) {
            amountB = (amountA * reserve1) / reserve0;
        } else {
            amountB = (amountA * reserve0) / reserve1;
        }
    }

    /**
     * @notice Get expected output for swap
     */
    function getAmountOut(uint256 amountIn, address[] calldata path) external view returns (uint256) {
        uint256[] memory amounts = ROUTER.getAmountsOut(amountIn, path);
        return amounts[amounts.length - 1];
    }
}
