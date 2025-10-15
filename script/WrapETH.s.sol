// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";

interface IWETH {
    function deposit() external payable;
    function balanceOf(address) external view returns (uint256);
}

contract WrapETH is Script {
    address constant WETH = 0x4200000000000000000000000000000000000006; // WETH on Base Sepolia

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address user = vm.addr(pk);
        vm.startBroadcast(pk);

        // Wrap 0.01 ETH to WETH
        uint256 amountToWrap = 0.01 ether;
        console.log("Wrapping", amountToWrap, "ETH to WETH");

        IWETH(WETH).deposit{value: amountToWrap}();

        uint256 wethBalance = IWETH(WETH).balanceOf(user);
        console.log("WETH balance after wrapping:", wethBalance);

        vm.stopBroadcast();
    }
}
