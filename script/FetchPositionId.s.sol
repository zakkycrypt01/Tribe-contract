// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {TribeVaultFactory} from "../src/TribeVaultFactory.sol";
import {TribeCopyVault} from "../src/TribeCopyVault.sol";
import {TribeLeaderRegistry} from "../src/TribeLeaderRegistry.sol";
import {INonfungiblePositionManager} from "../src/TribeUniswapV3Adapter.sol";

// Additional interfaces needed for direct position checking
interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address owner) external view returns (uint256 balance);
}

// Interface for ERC721Enumerable which allows enumeration of tokens by owner
interface IERC721Enumerable is IERC721 {
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}

// Extended interface for the Position Manager
interface IExtendedPositionManager is INonfungiblePositionManager, IERC721Enumerable {
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
 * @title FetchPositionId
 * @notice Script to fetch all position token IDs associated with a user address
 * @dev Can fetch tokens both for followers (in their vaults) and for leaders (directly owned)
 */
contract FetchPositionId is Script {
    // Hardcoded contract addresses from base-sepolia.txt
    address immutable VAULT_FACTORY = 0xdEc456e502CB9baB4a33153206a470B65Bedcf9E;
    address immutable LEADER_REGISTRY = 0xE73Eb839A848237E53988F0d74b069763aC38fE3;
    address immutable POSITION_MANAGER = 0x27F971cb582BF9E50F397e4d29a5C7A34f11faA2; // Position Manager

    struct PositionInfo {
        uint256 positionId;   // Internal ID in the vault
        uint256 tokenId;      // NFT token ID (Uniswap V3)
        address protocol;
        address token0;
        address token1;
        uint256 liquidity;
        bool isActive;
    }

    function run() public view {
        // Read command line arguments
        address userAddr = vm.envAddress("USER_ADDRESS");
        
        // Set wider scanning range from env or use defaults
        uint256 startTokenId = vm.envOr("START_TOKEN_ID", uint256(1)); 
        uint256 endTokenId = vm.envOr("END_TOKEN_ID", uint256(100000));
        console.log("Scanning token range:", startTokenId, "to", endTokenId);
        
        // Fetch all positions for the user
        fetchAllPositions(userAddr);
    }
    
    // This is a read-only function but needs to be marked non-view to use console.log
    function fetchAllPositions(address userAddr) public view {
        TribeVaultFactory factory = TribeVaultFactory(VAULT_FACTORY);
        TribeLeaderRegistry registry = TribeLeaderRegistry(LEADER_REGISTRY);
        
        // Check if the user is a registered leader
        bool isLeader = registry.isRegisteredLeader(userAddr);
        
        if (isLeader) {
            console.log("User is a registered leader");
            console.log("---------- LEADER POSITIONS ----------");
            fetchLeaderPositions(userAddr);
        }
        
        // Get all registered leaders to check if user has vaults as follower
        address[] memory allLeaders = registry.getAllLeaders();
        console.log("Total number of leaders:", allLeaders.length);
        
        console.log("---------- FOLLOWER POSITIONS ----------");
        console.log("Checking user's follower vaults...");
        
        uint256 vaultCount = 0;
        
        // For each leader, check if the user has a vault
        for (uint256 i = 0; i < allLeaders.length; i++) {
            address leader = allLeaders[i];
            address vaultAddr = factory.followerVaults(userAddr, leader);
            
            if (vaultAddr != address(0)) {
                vaultCount++;
                console.log("Found vault for leader:", leader);
                console.log("Vault address:", vaultAddr);
                
                // Get positions from this vault
                TribeCopyVault vault = TribeCopyVault(vaultAddr);
                
                // Determine the number of positions by trying to access them in a loop
                uint256 positionCount = 0;
                bool continueChecking = true;
                
                while (continueChecking) {
                    try vault.positions(positionCount) returns (
                        address protocol,
                        address token0,
                        address token1,
                        uint256 liquidity,
                        uint256 tokenId,
                        bool isActive
                    ) {
                        if (isActive) {
                            console.log("Position ID:", positionCount);
                            console.log("  Protocol:", protocol);
                            console.log("  Token0:", token0);
                            console.log("  Token1:", token1);
                            console.log("  Liquidity:", liquidity);
                            console.log("  TokenId:", tokenId);
                            console.log("  Active:", isActive);
                            console.log("---------------------------");
                        }
                        positionCount++;
                    } catch (bytes memory) {
                        continueChecking = false;
                    }
                }
                
                console.log("Total positions in this vault:", positionCount);
            }
        }
        
        if (vaultCount == 0) {
            console.log("No vaults found for this user as a follower");
        } else {
            console.log("Total vaults found:", vaultCount);
        }
        
        console.log("\n---------- SUMMARY ----------");
        console.log("User address:", userAddr);
        console.log("Is registered leader:", isLeader ? "Yes" : "No");
        console.log("Follower vaults found:", vaultCount);
        console.log("---------------------------");
        
    }
    
    /**
     * @notice Helper function to enumerate tokens directly within the same function 
     */
    function useTokenEnumerationInline(IExtendedPositionManager posManager, address owner, uint256 balance) internal view returns (bool) {
        uint256 foundPositions = 0;
        
        // Loop through all tokens owned by this owner
        for (uint256 i = 0; i < balance; i++) {
            try posManager.tokenOfOwnerByIndex(owner, i) returns (uint256 tokenId) {
                foundPositions++;
                
                // Get position details
                try posManager.positions(tokenId) returns (
                    uint96 /* nonce */,
                    address /* operator */,
                    address token0,
                    address token1,
                    uint24 fee,
                    int24 tickLower,
                    int24 tickUpper,
                    uint128 liquidity,
                    uint256 /* feeGrowthInside0LastX128 */,
                    uint256 /* feeGrowthInside1LastX128 */,
                    uint128 /* tokensOwed0 */,
                    uint128 /* tokensOwed1 */
                ) {
                    console.log("Found position with token ID:", tokenId);
                    console.log("  Token0:", token0);
                    console.log("  Token1:", token1);
                    console.log("  Fee Tier:", fee);
                    console.log("  Liquidity:", liquidity);
                    if (liquidity > 0) {
                        console.log("  Status: Active");
                    } else {
                        console.log("  Status: Closed or Empty");
                    }
                    
                    // Print tick range (convert to int256 to avoid overflow issues with console.log)
                    int256 lowerTick = int256(int24(tickLower));
                    int256 upperTick = int256(int24(tickUpper));
                    console.log("  Tick Range:");
                    console.log("    Lower:", lowerTick);
                    console.log("    Upper:", upperTick);
                    console.log("---------------------------");
                } catch (bytes memory) {
                    console.log("Found token ID", tokenId, "but couldn't read position details");
                }
            } catch (bytes memory) {
                console.log("Error fetching token at index", i);
                return false;
            }
        }
        
        console.log("Total positions found using enumeration:", foundPositions);
        return foundPositions > 0;
    }

    /**
     * @notice Fetch positions directly owned by a leader
     * @dev Uses ERC721 ownership checking and position details from Uniswap V3 PositionManager
     */
    function fetchLeaderPositions(address leaderAddr) public view {
        // Interface to check position details and ownership
        IExtendedPositionManager posManager = IExtendedPositionManager(POSITION_MANAGER);
        
        // First check if the leader has any NFTs at all
        try posManager.balanceOf(leaderAddr) returns (uint256 balance) {
            console.log("Leader owns", balance, "Uniswap V3 position NFTs");
            
            if (balance == 0) {
                console.log("No positions found for this leader");
                return;
            }
            
            console.log("Fetching positions directly using tokenOfOwnerByIndex...");
            
            // Try to use ERC721Enumerable interface directly (more efficient)
            try posManager.tokenOfOwnerByIndex(leaderAddr, 0) returns (uint256) {
                // If we can successfully get the first token, we assume enumeration is supported
                useTokenEnumerationInline(posManager, leaderAddr, balance);
                return; // Successfully used enumeration
            } catch (bytes memory) {
                console.log("Token enumeration not supported or failed.");
            }
            
            // Fall back to range-based scanning if enumeration fails
            console.log("Falling back to range-based scanning...");
        } catch (bytes memory) {
            console.log("Failed to check NFT balance, proceeding with scanning");
        }
        
        // Range-based scanning with different ranges to maximize chance of finding positions
        uint256 startTokenId = vm.envOr("START_TOKEN_ID", uint256(1)); 
        uint256 endTokenId = vm.envOr("END_TOKEN_ID", uint256(100000));
            
        // Set some reasonable scan ranges based on common Uniswap V3 token ID patterns
        console.log("Scanning token IDs from", startTokenId, "to", endTokenId);
        
        // Break into smaller chunks for efficient scanning
        uint256 chunkSize = 1000;
        for (uint256 i = startTokenId; i < endTokenId; i += chunkSize) {
            uint256 end = i + chunkSize;
            if (end > endTokenId) {
                end = endTokenId;
            }
            console.log("Scanning chunk:", i, "to", end);
            scanTokenIdRange(posManager, leaderAddr, i, end);
        }
    }
    
    /**
     * @notice Scan a range of token IDs for positions owned by an address
     */
    function scanTokenIdRange(IExtendedPositionManager posManager, address owner, uint256 startTokenId, uint256 endTokenId) public view {
        uint256 foundPositions = 0;
        
        for (uint256 tokenId = startTokenId; tokenId <= endTokenId; tokenId++) {
            // Try to get owner of this token ID
            try IERC721(address(posManager)).ownerOf(tokenId) returns (address tokenOwner) {
                bool isOwner = (tokenOwner == owner);
                
                if (isOwner) {
                    foundPositions++;
                    // Get position details
                    try posManager.positions(tokenId) returns (
                        uint96 /* nonce */,
                        address /* operator */,
                        address token0,
                        address token1,
                        uint24 fee,
                        int24 tickLower,
                        int24 tickUpper,
                        uint128 liquidity,
                        uint256 /* feeGrowthInside0LastX128 */,
                        uint256 /* feeGrowthInside1LastX128 */,
                        uint128 /* tokensOwed0 */,
                        uint128 /* tokensOwed1 */
                    ) {
                        console.log("Found position with token ID:", tokenId);
                        console.log("  Token0:", token0);
                        console.log("  Token1:", token1);
                        console.log("  Fee Tier:", fee);
                        console.log("  Liquidity:", liquidity);
                        if (liquidity > 0) {
                            console.log("  Status: Active");
                        } else {
                            console.log("  Status: Closed or Empty");
                        }
                        
                        // Print tick range (convert to int256 to avoid overflow issues with console.log)
                        int256 lowerTick = int256(int24(tickLower));
                        int256 upperTick = int256(int24(tickUpper));
                        console.log("  Tick Range:");
                        console.log("    Lower:", lowerTick);
                        console.log("    Upper:", upperTick);
                        console.log("---------------------------");
                    } catch (bytes memory) {
                        console.log("Found token ID", tokenId, "but couldn't read position details");
                    }
                }
            } catch (bytes memory) {
                // Skip tokens that can't be queried (might not exist or have other issues)
                continue;
            }
        }
        
        console.log("Total positions found for leader:", foundPositions);
        
        // Additional approach: check for any other contracts or methods that might track leader positions
        // For example, you might want to check TribeLeaderTerminal for additional context
        console.log("Note: This scan only shows positions directly owned by the leader.");
        console.log("Other positions might exist through the terminal or other contracts.");
    }
    
    /**
     * @notice Uses ERC721Enumerable tokenOfOwnerByIndex to efficiently fetch tokens
     */
    function useTokenEnumeration(address posManagerAddr, address owner, uint256 balance) public view returns (bool) {
        IExtendedPositionManager posManager = IExtendedPositionManager(posManagerAddr);
        uint256 foundPositions = 0;
        
        // Loop through all tokens owned by this owner
        for (uint256 i = 0; i < balance; i++) {
            try posManager.tokenOfOwnerByIndex(owner, i) returns (uint256 tokenId) {
                foundPositions++;
                // Get position details
                try posManager.positions(tokenId) returns (
                    uint96 /*nonce*/,
                    address /*operator*/,
                    address token0,
                    address token1,
                    uint24 fee,
                    int24 tickLower,
                    int24 tickUpper,
                    uint128 liquidity,
                    uint256 /*feeGrowthInside0LastX128*/,
                    uint256 /*feeGrowthInside1LastX128*/,
                    uint128 /*tokensOwed0*/,
                    uint128 /*tokensOwed1*/
                ) {
                    console.log("Found position with token ID:", tokenId);
                    console.log("  Token0:", token0);
                    console.log("  Token1:", token1);
                    console.log("  Fee Tier:", fee);
                    console.log("  Liquidity:", liquidity);
                    if (liquidity > 0) {
                        console.log("  Status: Active");
                    } else {
                        console.log("  Status: Closed or Empty");
                    }
                    
                    // Print tick range (convert to int256 to avoid overflow issues with console.log)
                    int256 lowerTick = int256(int24(tickLower));
                    int256 upperTick = int256(int24(tickUpper));
                    console.log("  Tick Range:");
                    console.log("    Lower:", lowerTick);
                    console.log("    Upper:", upperTick);
                    console.log("---------------------------");
                } catch (bytes memory) {
                    console.log("Found token ID", tokenId, "but couldn't read position details");
                }
            } catch (bytes memory) {
                // This shouldn't happen with tokenOfOwnerByIndex if balance is correct
                console.log("Error fetching token at index", i);
                return false;
            }
        }
        
        console.log("Total positions found using enumeration:", foundPositions);
        return true;
    }
}