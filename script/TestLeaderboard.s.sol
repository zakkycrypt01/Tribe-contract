// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {TribeLeaderboard} from "../src/TribeLeaderboard.sol";

contract TestLeaderboard is Script {
    address constant LEADERBOARD = 0xe27070fd257607aB185B83652C139aE38f997cbE;

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        // Get all leader profiles
        TribeLeaderboard leaderboard = TribeLeaderboard(LEADERBOARD);
        address[] memory allLeaders = leaderboard.LEADER_REGISTRY().getAllLeaders();
        console.log("Total leaders:", allLeaders.length);

        // For each leader, get profile
        for (uint256 i = 0; i < allLeaders.length; i++) {
            // This will revert if not registered, so wrap in try/catch
            try leaderboard.getLeaderProfile(allLeaders[i]) returns (TribeLeaderboard.LeaderProfile memory profile) {
                console.log("Leader:", profile.wallet);
                console.log("Strategy:", profile.strategyName);
                console.log("APR:", profile.netApr);
                console.log("Followers:", profile.totalFollowers);
            } catch {
                console.log("Could not fetch profile for leader:", allLeaders[i]);
            }
        }

        vm.stopBroadcast();
    }
}
