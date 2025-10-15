// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {TribeVaultFactory} from "../src/TribeVaultFactory.sol";
import {TribeLeaderRegistry} from "../src/TribeLeaderRegistry.sol";

contract TestVaultFactory is Script {
    address constant VAULT_FACTORY = 0x54e6Cb2C7da3BB683f0653D804969609711B2740;
    address constant LEADER_REGISTRY = 0xB28049beA41b96B54a8dA0Ee47C8F7209e820150;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address follower = vm.addr(pk);
        vm.startBroadcast(pk);

        // Find a registered leader
        address[] memory leaders = TribeLeaderRegistry(LEADER_REGISTRY).getAllLeaders();
        require(leaders.length > 0, "No leaders registered");
        address leader = leaders[0];

        // Create a vault for the follower-leader pair
        address vault = TribeVaultFactory(VAULT_FACTORY).createVault(leader);
        console.log("Vault created:", vault);

        // Get vault address for follower-leader pair
        address vaultCheck = TribeVaultFactory(VAULT_FACTORY).getVault(follower, leader);
        console.log("Vault for follower-leader:", vaultCheck);

        // Get all vaults for leader
        address[] memory leaderVaults = TribeVaultFactory(VAULT_FACTORY).getLeaderVaults(leader);
        console.log("Leader vault count:", leaderVaults.length);

        vm.stopBroadcast();
    }
}
