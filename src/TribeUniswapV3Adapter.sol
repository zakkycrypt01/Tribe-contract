// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title TribeUniswapV3Adapter
 * @notice Adapter for interacting with Uniswap V3 concentrated liquidity positions
 * @dev Handles the complex NFT position management for Uniswap V3
 */
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

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function mint(MintParams calldata params)
        external
        payable
        returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    function burn(uint256 tokenId) external payable;

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

contract TribeUniswapV3Adapter {
    using SafeERC20 for IERC20;

    // Uniswap V3 interfaces

    INonfungiblePositionManager public immutable POSITION_MANAGER;

    constructor(address _positionManager) {
        require(_positionManager != address(0), "Invalid position manager");
        POSITION_MANAGER = INonfungiblePositionManager(_positionManager);
    }

    /**
     * @notice Mint a new Uniswap V3 position
     */
    function mintPosition(
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min,
        address recipient
    ) external returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) {
        // Approve tokens
        IERC20(token0).approve(address(POSITION_MANAGER), amount0Desired);
        IERC20(token1).approve(address(POSITION_MANAGER), amount1Desired);

        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: token0,
            token1: token1,
            fee: fee,
            tickLower: tickLower,
            tickUpper: tickUpper,
            amount0Desired: amount0Desired,
            amount1Desired: amount1Desired,
            amount0Min: amount0Min,
            amount1Min: amount1Min,
            recipient: recipient,
            deadline: block.timestamp
        });

        return POSITION_MANAGER.mint(params);
    }

    /**
     * @notice Mint a new Uniswap V3 position and refund unused tokens to a recipient
     */
    function mintPositionWithRefund(
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min,
        address recipient,
        address refundTo
    ) external returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) {
        // Approve tokens
        IERC20(token0).approve(address(POSITION_MANAGER), amount0Desired);
        IERC20(token1).approve(address(POSITION_MANAGER), amount1Desired);

        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: token0,
            token1: token1,
            fee: fee,
            tickLower: tickLower,
            tickUpper: tickUpper,
            amount0Desired: amount0Desired,
            amount1Desired: amount1Desired,
            amount0Min: amount0Min,
            amount1Min: amount1Min,
            recipient: recipient,
            deadline: block.timestamp
        });

        (tokenId, liquidity, amount0, amount1) = POSITION_MANAGER.mint(params);

        // Refund any unused tokens from adapter back to refundTo
        if (amount0Desired > amount0) {
            uint256 refund0 = amount0Desired - amount0;
            IERC20(token0).safeTransfer(refundTo, refund0);
        }
        if (amount1Desired > amount1) {
            uint256 refund1 = amount1Desired - amount1;
            IERC20(token1).safeTransfer(refundTo, refund1);
        }
    }

    /**
     * @notice Increase liquidity in an existing position
     */
    function increaseLiquidity(
        uint256 tokenId,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min
    ) external returns (uint128 liquidity, uint256 amount0, uint256 amount1) {
        // Get position details to approve correct tokens
        (,, address token0, address token1,,,,,,,,) = POSITION_MANAGER.positions(tokenId);

        IERC20(token0).approve(address(POSITION_MANAGER), amount0Desired);
        IERC20(token1).approve(address(POSITION_MANAGER), amount1Desired);

        INonfungiblePositionManager.IncreaseLiquidityParams memory params = INonfungiblePositionManager
            .IncreaseLiquidityParams({
            tokenId: tokenId,
            amount0Desired: amount0Desired,
            amount1Desired: amount1Desired,
            amount0Min: amount0Min,
            amount1Min: amount1Min,
            deadline: block.timestamp
        });

        return POSITION_MANAGER.increaseLiquidity(params);
    }

    /**
     * @notice Decrease liquidity from a position
     */
    function decreaseLiquidity(uint256 tokenId, uint128 liquidity, uint256 amount0Min, uint256 amount1Min)
        external
        returns (uint256 amount0, uint256 amount1)
    {
        INonfungiblePositionManager.DecreaseLiquidityParams memory params = INonfungiblePositionManager
            .DecreaseLiquidityParams({
            tokenId: tokenId,
            liquidity: liquidity,
            amount0Min: amount0Min,
            amount1Min: amount1Min,
            deadline: block.timestamp
        });

        return POSITION_MANAGER.decreaseLiquidity(params);
    }

    /**
     * @notice Collect fees and tokens from a position
     */
    function collectFees(uint256 tokenId, address recipient) external returns (uint256 amount0, uint256 amount1) {
        INonfungiblePositionManager.CollectParams memory params = INonfungiblePositionManager.CollectParams({
            tokenId: tokenId,
            recipient: recipient,
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max
        });

        return POSITION_MANAGER.collect(params);
    }

    /**
     * @notice Burn an NFT position (must have 0 liquidity)
     */
    function burnPosition(uint256 tokenId) external {
        POSITION_MANAGER.burn(tokenId);
    }

    /**
     * @notice Get position information
     */
    function getPositionInfo(uint256 tokenId)
        external
        view
        returns (
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        )
    {
        (,, token0, token1, fee, tickLower, tickUpper, liquidity,,, tokensOwed0, tokensOwed1) =
            POSITION_MANAGER.positions(tokenId);
    }

    /**
     * @notice Calculate proportional amounts for a given liquidity
     */
    function calculateProportionalAmounts(uint256 totalLiquidity, uint256 vaultShare, uint256 amount0, uint256 amount1)
        external
        pure
        returns (uint256 proportionalAmount0, uint256 proportionalAmount1)
    {
        if (totalLiquidity == 0) return (0, 0);

        proportionalAmount0 = (amount0 * vaultShare) / totalLiquidity;
        proportionalAmount1 = (amount1 * vaultShare) / totalLiquidity;

        return (proportionalAmount0, proportionalAmount1);
    }
}
