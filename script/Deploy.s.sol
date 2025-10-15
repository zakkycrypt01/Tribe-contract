// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {TribeLeaderRegistry} from "../src/TribeLeaderRegistry.sol";
import {TribeVaultFactory} from "../src/TribeVaultFactory.sol";
import {TribeLeaderTerminal} from "../src/TribeLeaderTerminal.sol";
import {TribeLeaderboard} from "../src/TribeLeaderboard.sol";
import {TribePerformanceTracker} from "../src/TribePerformanceTracker.sol";
import {TribeUniswapV3Adapter} from "../src/TribeUniswapV3Adapter.sol";
import {TribeAerodromeAdapter} from "../src/TribeAerodromeAdapter.sol";

/**
 * @title Deploy
 * @notice Deployment script for Tribe protocol on Base Sepolia
 */
contract Deploy is Script {
    
    // Base Sepolia addresses (you may need to update these)
    address constant UNISWAP_V3_POSITION_MANAGER = 0x27F971cb582BF9E50F397e4d29a5C7A34f11faA2;
    address constant AERODROME_ROUTER = address(0); // Update with actual Aerodrome router if available
    address constant ETH_USD_PRICE_FEED = 0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1; // Chainlink ETH/USD on Base Sepolia
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying contracts with account:", deployer);
        console.log("Account balance:", deployer.balance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy TribeLeaderRegistry
        console.log("\n1. Deploying TribeLeaderRegistry...");
        TribeLeaderRegistry leaderRegistry = new TribeLeaderRegistry();
        console.log("TribeLeaderRegistry deployed at:", address(leaderRegistry));
        
        // 2. Deploy TribeVaultFactory
        console.log("\n2. Deploying TribeVaultFactory...");
        TribeVaultFactory vaultFactory = new TribeVaultFactory(address(leaderRegistry));
        console.log("TribeVaultFactory deployed at:", address(vaultFactory));
        
        // 3. Deploy TribeLeaderTerminal
        console.log("\n3. Deploying TribeLeaderTerminal...");
        TribeLeaderTerminal leaderTerminal = new TribeLeaderTerminal(
            address(vaultFactory),
            address(leaderRegistry),
            UNISWAP_V3_POSITION_MANAGER,
            AERODROME_ROUTER
        );
        console.log("TribeLeaderTerminal deployed at:", address(leaderTerminal));
        
        // 4. Set Terminal address in VaultFactory
        console.log("\n4. Setting Terminal address in VaultFactory...");
        vaultFactory.setTerminal(address(leaderTerminal));
        console.log("Terminal address set in VaultFactory");
        
        // 5. Deploy TribePerformanceTracker
        console.log("\n5. Deploying TribePerformanceTracker...");
        TribePerformanceTracker performanceTracker = new TribePerformanceTracker(
            address(vaultFactory),
            address(leaderRegistry)
        );
        console.log("TribePerformanceTracker deployed at:", address(performanceTracker));
        
        // 6. Deploy TribeLeaderboard
        console.log("\n6. Deploying TribeLeaderboard...");
        TribeLeaderboard leaderboard = new TribeLeaderboard(
            address(leaderRegistry),
            address(performanceTracker),
            address(vaultFactory)
        );
        console.log("TribeLeaderboard deployed at:", address(leaderboard));
        
        // 7. Deploy TribeUniswapV3Adapter
        console.log("\n7. Deploying TribeUniswapV3Adapter...");
        TribeUniswapV3Adapter uniswapAdapter = new TribeUniswapV3Adapter(UNISWAP_V3_POSITION_MANAGER);
        console.log("TribeUniswapV3Adapter deployed at:", address(uniswapAdapter));
        
        // 8. Deploy TribeAerodromeAdapter (if router is available)
        if (AERODROME_ROUTER != address(0)) {
            console.log("\n8. Deploying TribeAerodromeAdapter...");
            TribeAerodromeAdapter aerodromeAdapter = new TribeAerodromeAdapter(AERODROME_ROUTER);
            console.log("TribeAerodromeAdapter deployed at:", address(aerodromeAdapter));
        } else {
            console.log("\n8. Skipping TribeAerodromeAdapter (no router address configured)");
        }
        
        vm.stopBroadcast();
        
        // Print deployment summary
        console.log("\n=== DEPLOYMENT SUMMARY ===");
        console.log("Network: Base Sepolia (Chain ID: 84532)");
        console.log("Deployer:", deployer);
        console.log("\nCore Contracts:");
        console.log("- TribeLeaderRegistry:", address(leaderRegistry));
        console.log("- TribeVaultFactory:", address(vaultFactory));
        console.log("- TribeLeaderTerminal:", address(leaderTerminal));
        console.log("\nAuxiliary Contracts:");
        console.log("- TribeLeaderboard:", address(leaderboard));
        console.log("- TribePerformanceTracker:", address(performanceTracker));
        console.log("\nAdapters:");
        console.log("- TribeUniswapV3Adapter:", address(uniswapAdapter));
        console.log("\n=========================\n");
        
        // Save deployment addresses to file
        string memory deploymentInfo = string(abi.encodePacked(
            "LEADER_REGISTRY=", vm.toString(address(leaderRegistry)), "\n",
            "VAULT_FACTORY=", vm.toString(address(vaultFactory)), "\n",
            "LEADER_TERMINAL=", vm.toString(address(leaderTerminal)), "\n",
            "LEADERBOARD=", vm.toString(address(leaderboard)), "\n",
            "PERFORMANCE_TRACKER=", vm.toString(address(performanceTracker)), "\n",
            "UNISWAP_V3_ADAPTER=", vm.toString(address(uniswapAdapter)), "\n"
        ));
        
        // Try writing deployment addresses to file; if not permitted, just log them.
        try vm.writeFile("deployments/base-sepolia.txt", deploymentInfo) {
            console.log("Deployment addresses saved to deployments/base-sepolia.txt");
        } catch {
            console.log("Warning: could not write to deployments/base-sepolia.txt (fs permissions). Below are the addresses:");
            console.log(deploymentInfo);
        }
    }
}
