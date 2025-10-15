// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {TribeLeaderRegistry} from "../src/TribeLeaderRegistry.sol";

contract TestLeaderRegistration is Script {
    // Set via environment: export LEADER_REGISTRY=0x...
    address immutable LEADER_REGISTRY = vm.envAddress("LEADER_REGISTRY");

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address leader = vm.addr(pk);
        vm.startBroadcast(pk);

        // Only register if not already registered
        bool isRegistered = TribeLeaderRegistry(LEADER_REGISTRY).isRegisteredLeader(leader);
        if (!isRegistered) {
            // Prepare historical positions for qualification
            TribeLeaderRegistry.HistoricalPosition[] memory positions = new TribeLeaderRegistry.HistoricalPosition[](5);
            for (uint256 i = 0; i < 5; i++) {
                positions[i] = TribeLeaderRegistry.HistoricalPosition({
                    token0: address(0x1),
                    token1: address(0x2),
                    openTime: block.timestamp - 10 days - i * 1 days,
                    closeTime: block.timestamp - 9 days - i * 1 days,
                    principalUsd: 1000e18,
                    netPnLUsd: int256(100e18),
                    isProfitable: true
                });
            }
            // Submit positions
            TribeLeaderRegistry(LEADER_REGISTRY).submitHistoricalPositions(positions);
            console.log("Historical positions submitted.");

            // Register as leader
            TribeLeaderRegistry(LEADER_REGISTRY).registerAsLeader(
                "Test Strategy",
                "A test strategy for registration.",
                1000 // 10% fee
            );
            console.log("Leader registered.");
        } else {
            console.log("Leader already registered, skipping registration.");
        }

        // Update strategy
        TribeLeaderRegistry(LEADER_REGISTRY).updateStrategy("Updated Strategy", "Updated description.");
        console.log("Strategy updated.");

        // Deactivate leader (must be owner, so skip if not owner)
        // For demo, try/catch to avoid revert
        try TribeLeaderRegistry(LEADER_REGISTRY).deactivateLeader(leader) {
            console.log("Leader deactivated.");
        } catch {
            console.log("Could not deactivate leader (not owner).");
        }

        // Reactivate leader (must be owner, so skip if not owner)
        try TribeLeaderRegistry(LEADER_REGISTRY).reactivateLeader(leader) {
            console.log("Leader reactivated.");
        } catch {
            console.log("Could not reactivate leader (not owner).");
        }

        // Fetch and log leader info
        TribeLeaderRegistry.Leader memory info = TribeLeaderRegistry(LEADER_REGISTRY).getLeader(leader);
        console.log("Leader info:");
        console.log("wallet:", info.wallet);
        console.log("strategyName:", info.strategyName);
        console.log("description:", info.description);
        console.log("isActive:", info.isActive);
        console.log("registrationTime:", info.registrationTime);
        console.log("totalFollowers:", info.totalFollowers);
        console.log("totalTvl:", info.totalTvl);
        console.log("performanceFeePercent:", info.performanceFeePercent);

        vm.stopBroadcast();
    }
}
