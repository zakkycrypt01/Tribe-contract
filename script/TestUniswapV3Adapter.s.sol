// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {TribeUniswapV3Adapter} from "../src/TribeUniswapV3Adapter.sol";

contract TestUniswapV3Adapter is Script {
    address constant UNISWAP_V3_ADAPTER = 0x36888e432d41729B0978F89e71F1e523147E7CcC;
    address constant POSITION_MANAGER = 0x27F971cb582BF9E50F397e4d29a5C7A34f11faA2;

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        // Check position manager address
        address pm = address(TribeUniswapV3Adapter(UNISWAP_V3_ADAPTER).POSITION_MANAGER());
        console.log("UniswapV3 Position Manager:", pm);

        vm.stopBroadcast();
    }
}
