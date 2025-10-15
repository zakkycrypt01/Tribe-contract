// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {TribeCopyVault} from "../src/TribeCopyVault.sol";
import {TribeVaultFactory} from "../src/TribeVaultFactory.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface INonfungiblePositionManager {
    function balanceOf(address owner) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
}

/**
 * @title VerifyFollowerNFTs
 * @notice Verify that follower vaults own actual Uniswap V3 NFT positions
 */
contract VerifyFollowerNFTs is Script {
    address constant UNISWAP_V3_POSITION_MANAGER = 0x27F971cb582BF9E50F397e4d29a5C7A34f11faA2;
    address immutable VAULT_FACTORY = vm.envAddress("VAULT_FACTORY");

    function run() external view {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address user = vm.addr(pk);

        console.log("=== VERIFYING FOLLOWER VAULT NFT OWNERSHIP ===");
        console.log("User Address:", user);
        console.log("");

        // Get the vault address (user following themselves for test)
        address vaultAddress = TribeVaultFactory(VAULT_FACTORY).getVault(user, user);
        require(vaultAddress != address(0), "No vault found for user");

        console.log("Follower Vault:", vaultAddress);
        console.log("");

        // Check vault's position records
        TribeCopyVault vault = TribeCopyVault(vaultAddress);
        TribeCopyVault.Position[] memory positions = vault.getAllPositions();
        console.log("Positions Recorded in Vault:", positions.length);

        if (positions.length > 0) {
            for (uint256 i = 0; i < positions.length; i++) {
                console.log("");
                console.log("--- Position", i, "---");
                console.log("Protocol:", positions[i].protocol);
                console.log("Token0:", positions[i].token0);
                console.log("Token1:", positions[i].token1);
                console.log("Liquidity:", positions[i].liquidity);
                console.log("TokenId:", positions[i].tokenId);
                console.log("Is Active:", positions[i].isActive);
            }
        }
        console.log("");

        // Check if vault actually owns any Uniswap V3 NFTs
        INonfungiblePositionManager posManager = INonfungiblePositionManager(UNISWAP_V3_POSITION_MANAGER);
        uint256 nftBalance = posManager.balanceOf(vaultAddress);

        console.log("=== ACTUAL NFT OWNERSHIP ===");
        console.log("Vault's Uniswap V3 NFT Balance:", nftBalance);

        if (nftBalance > 0) {
            console.log("");
            console.log("Vault owns the following NFT token IDs:");
            for (uint256 i = 0; i < nftBalance; i++) {
                uint256 tokenId = posManager.tokenOfOwnerByIndex(vaultAddress, i);
                console.log("  NFT #", tokenId);
            }
            console.log("");
            console.log("[OK] Follower vault DOES own real Uniswap V3 NFT positions!");
        } else {
            console.log("");
            console.log("[ISSUE] Follower vault does NOT own any real Uniswap V3 NFT positions!");
            console.log("");
            console.log("Current Implementation Issue:");
            console.log("- Leader gets real NFT position");
            console.log("- Follower vault only records position metadata (no actual NFT)");
            console.log("");
            console.log("Expected Behavior:");
            console.log("- Each follower vault should mint its own proportional Uniswap V3 position");
            console.log("- Follower vault should own the NFT directly");
            console.log("- This allows follower to independently collect fees and manage position");
        }

        // Check leader's NFT balance for comparison
        console.log("");
        console.log("=== LEADER NFT OWNERSHIP (for comparison) ===");
        uint256 leaderNftBalance = posManager.balanceOf(user);
        console.log("Leader's Uniswap V3 NFT Balance:", leaderNftBalance);

        if (leaderNftBalance > 0) {
            console.log("Leader owns the following NFT token IDs:");
            for (uint256 i = 0; i < leaderNftBalance; i++) {
                uint256 tokenId = posManager.tokenOfOwnerByIndex(user, i);
                console.log("  NFT #", tokenId);
            }
        }
    }
}
