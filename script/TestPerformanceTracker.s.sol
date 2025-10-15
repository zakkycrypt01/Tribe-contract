// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {TribePerformanceTracker} from "../src/TribePerformanceTracker.sol";
import {TribeVaultFactory} from "../src/TribeVaultFactory.sol";
import {TribeLeaderRegistry} from "../src/TribeLeaderRegistry.sol";

contract TestPerformanceTracker is Script {
    address constant PERFORMANCE_TRACKER = 0xdFbefEcD6A35078c409fd907E0FA03a33015A48e;
    address constant VAULT_FACTORY = 0x54e6Cb2C7da3BB683f0653D804969609711B2740;
    address constant LEADER_REGISTRY = 0xB28049beA41b96B54a8dA0Ee47C8F7209e820150;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address leader = vm.addr(pk);
        vm.startBroadcast(pk);

        // Get metrics for leader
        TribePerformanceTracker tracker = TribePerformanceTracker(PERFORMANCE_TRACKER);
        (
            uint256 totalFeesEarned,
            uint256 netApr,
            uint256 totalVolume,
            uint256 maxDrawdown,
            uint256 riskScore,
            uint256 lastUpdated
        ) = tracker.leaderMetrics(leader);

        console.log("totalFeesEarned:", totalFeesEarned);
        console.log("netApr:", netApr);
        console.log("totalVolume:", totalVolume);
        console.log("maxDrawdown:", maxDrawdown);
        console.log("riskScore:", riskScore);
        console.log("lastUpdated:", lastUpdated);

        vm.stopBroadcast();
    }
}
