// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {TribeLeaderTerminal} from "../src/TribeLeaderTerminal.sol";
import {TribeVaultFactory} from "../src/TribeVaultFactory.sol";
import {TribeLeaderRegistry} from "../src/TribeLeaderRegistry.sol";

contract TestLeaderTerminal is Script {
    address constant LEADER_TERMINAL = 0xE4E9D97664f1c74aEe1E6A83866E9749D32e02CE;
    address constant VAULT_FACTORY = 0x54e6Cb2C7da3BB683f0653D804969609711B2740;
    address constant LEADER_REGISTRY = 0xB28049beA41b96B54a8dA0Ee47C8F7209e820150;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address leader = vm.addr(pk);
        vm.startBroadcast(pk);

        // Check if leader is registered
        bool isRegistered = TribeLeaderRegistry(LEADER_REGISTRY).isRegisteredLeader(leader);
        console.log("Is registered leader:", isRegistered);

        // Get leader vaults
        address[] memory vaults = TribeVaultFactory(VAULT_FACTORY).getLeaderVaults(leader);
        console.log("Leader vault count:", vaults.length);

        // Log protocol addresses
        address uniswapPM = TribeLeaderTerminal(LEADER_TERMINAL).uniswapV3PositionManager();
        address aerodromeRouter = TribeLeaderTerminal(LEADER_TERMINAL).aerodromeRouter();
        console.log("UniswapV3PositionManager:", uniswapPM);
        console.log("AerodromeRouter:", aerodromeRouter);

        vm.stopBroadcast();
    }
}
