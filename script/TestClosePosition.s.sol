// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {TribeVaultFactory} from "../src/TribeVaultFactory.sol";
import {TribeCopyVault} from "../src/TribeCopyVault.sol";
import {TribeLeaderTerminal} from "../src/TribeLeaderTerminal.sol";

interface INPM {
    function balanceOf(address owner) external view returns (uint256);
}

contract TestClosePosition is Script {
    address immutable VAULT_FACTORY = vm.envAddress("VAULT_FACTORY");
    address immutable LEADER_TERMINAL = vm.envAddress("LEADER_TERMINAL");

    // Base Sepolia addresses
    address constant UNISWAP_V3_POSITION_MANAGER = 0x27F971cb582BF9E50F397e4d29a5C7A34f11faA2;
    address constant USDC = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;
    address constant WETH = 0x4200000000000000000000000000000000000006;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address user = vm.addr(pk);
        vm.startBroadcast(pk);

        console.log("=== TEST: CLOSE POSITION & REDEEM ===");

        address vaultAddr = TribeVaultFactory(VAULT_FACTORY).getVault(user, user);
        require(vaultAddr != address(0), "Vault not found");
        TribeCopyVault vault = TribeCopyVault(vaultAddr);

        // Pre-check: NFT balance and active positions
        uint256 activeBefore = vault.getActivePositionCount();
        uint256 nftBalBefore = INPM(UNISWAP_V3_POSITION_MANAGER).balanceOf(vaultAddr);
        console.log("Active Positions Before:", activeBefore);
        console.log("Vault NFT Balance Before:", nftBalBefore);

        // Close by pair via Terminal (will close in vault)
        uint256 amount0Min = 0; // for test no slippage protection
        uint256 amount1Min = 0;
        TribeLeaderTerminal(LEADER_TERMINAL).closeUniswapV3PositionByPair(USDC, WETH, amount0Min, amount1Min);
        console.log("Close command sent via Terminal");

        // Post-check
        uint256 activeAfter = vault.getActivePositionCount();
        uint256 nftBalAfter = INPM(UNISWAP_V3_POSITION_MANAGER).balanceOf(vaultAddr);
        console.log("Active Positions After:", activeAfter);
        console.log("Vault NFT Balance After:", nftBalAfter);

        // Optional: print balances
        uint256 usdcBal = vault.getVaultValue(USDC);
        uint256 wethBal = vault.getVaultValue(WETH);
        console.log("Vault USDC Balance:", usdcBal);
        console.log("Vault WETH Balance:", wethBal);

        console.log("=== CLOSE TEST DONE ===");
        vm.stopBroadcast();
    }
}
