// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {TribeVaultFactory} from "../src/TribeVaultFactory.sol";

interface ICopyVaultClose {
    function closeUniswapV3PositionByPair(
        address adapter,
        address positionManager,
        address token0,
        address token1,
        uint256 amount0Min,
        uint256 amount1Min
    ) external;
    function getActivePositionCount() external view returns (uint256);
}

interface INPM {
    function balanceOf(address owner) external view returns (uint256);
}

contract DirectVaultClose is Script {
    address immutable VAULT_FACTORY = vm.envAddress("VAULT_FACTORY");
    address immutable UNISWAP_V3_ADAPTER = vm.envAddress("UNISWAP_V3_ADAPTER");

    // Base Sepolia addresses
    address constant UNISWAP_V3_POSITION_MANAGER = 0x27F971cb582BF9E50F397e4d29a5C7A34f11faA2;
    address constant USDC = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;
    address constant WETH = 0x4200000000000000000000000000000000000006;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address user = vm.addr(pk);
        vm.startBroadcast(pk);

        console.log("=== DIRECT VAULT CLOSE (PAIR) ===");

        address vaultAddr = TribeVaultFactory(VAULT_FACTORY).getVault(user, user);
        require(vaultAddr != address(0), "Vault not found");

        uint256 activeBefore = ICopyVaultClose(vaultAddr).getActivePositionCount();
        uint256 nftBalBefore = INPM(UNISWAP_V3_POSITION_MANAGER).balanceOf(vaultAddr);
        console.log("Vault:", vaultAddr);
        console.log("Active Positions Before:", activeBefore);
        console.log("Vault NFT Balance Before:", nftBalBefore);

        // Attempt direct close on vault (requires vault bytecode with close function)
        try ICopyVaultClose(vaultAddr).closeUniswapV3PositionByPair(
            UNISWAP_V3_ADAPTER, UNISWAP_V3_POSITION_MANAGER, USDC, WETH, 0, 0
        ) {
            console.log("Close executed on vault.");
        } catch Error(string memory reason) {
            console.log("Close failed (string):", reason);
        } catch (bytes memory lowLevelData) {
            console.log("Close failed (low-level), data len:", lowLevelData.length);
        }

        uint256 activeAfter = ICopyVaultClose(vaultAddr).getActivePositionCount();
        uint256 nftBalAfter = INPM(UNISWAP_V3_POSITION_MANAGER).balanceOf(vaultAddr);
        console.log("Active Positions After:", activeAfter);
        console.log("Vault NFT Balance After:", nftBalAfter);
        console.log("=== DONE ===");

        vm.stopBroadcast();
    }
}
