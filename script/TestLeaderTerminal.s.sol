// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {TribeLeaderTerminal} from "../src/TribeLeaderTerminal.sol";
import {TribeVaultFactory} from "../src/TribeVaultFactory.sol";
import {TribeLeaderRegistry} from "../src/TribeLeaderRegistry.sol";

contract TestLeaderTerminal is Script {
    // Set via environment: export LEADER_TERMINAL=0x..., VAULT_FACTORY=0x..., LEADER_REGISTRY=0x...
    address immutable LEADER_TERMINAL = vm.envAddress("LEADER_TERMINAL");
    address immutable VAULT_FACTORY = vm.envAddress("VAULT_FACTORY");
    address immutable LEADER_REGISTRY = vm.envAddress("LEADER_REGISTRY");

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
