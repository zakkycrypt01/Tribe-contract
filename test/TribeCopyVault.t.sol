// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {TribeCopyVault} from "../src/TribeCopyVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockERC20 {
    string public name = "Mock";
    string public symbol = "MOCK";
    uint8 public decimals = 18;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 amount);

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "insufficient");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balanceOf[from] >= amount, "insufficient");
        require(allowance[from][msg.sender] >= amount, "allowance");
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
}

contract TribeCopyVaultTest is Test {
    address follower = address(0xF0);
    address leader = address(0xBEEF);
    address terminal = address(0xCAFE);

    MockERC20 token;
    TribeCopyVault vault;

    function setUp() public {
        token = new MockERC20();
        vault = new TribeCopyVault(follower, leader, terminal, 1000); // 10%
        token.mint(follower, 100 ether);
        vm.prank(follower);
        token.approve(address(vault), type(uint256).max);
    }

    function testDepositUpdatesAccounting() public {
        vm.prank(follower);
        vault.deposit(address(token), 10 ether);

        assertEq(vault.depositedCapital(), 10 ether, "deposited capital");
        assertEq(vault.highWaterMark(), 10 ether, "HWM set on first deposit");
        assertEq(token.balanceOf(address(vault)), 10 ether, "vault token balance");
    }

    function testWithdrawPaysFollowerAndFeeWhenProfitable() public {
        // Deposit 10
        vm.prank(follower);
        vault.deposit(address(token), 10 ether);

        // Simulate profit: mint tokens to vault so balance > HWM
        token.mint(address(vault), 2 ether); // vault balance now 12

        // Withdraw 6.
        // CORRECTED CALCULATION (per audit fix):
        // vaultBalance = 12, HWM = 10, totalProfit = 2
        // realizedProfit = (totalProfit * amount) / vaultBalance = (2 * 6) / 12 = 1
        // performanceFee = realizedProfit * 1000 / 10000 = 1 * 0.1 = 0.1
        // followerAmount = 6 - 0.1 = 5.9
        vm.prank(follower);
        vault.withdraw(address(token), 6 ether);

        // Follower should receive withdrawal amount minus proportional performance fee
        // followerAmount = 6 - 0.1 = 5.9
        assertEq(token.balanceOf(follower), 100 ether - 10 ether + 5.9 ether, "follower received");
        assertEq(token.balanceOf(leader), 0.1 ether, "leader fee received");
        // HWM is reduced by withdrawnCapital = amount - performanceFee = 5.9
        // newHWM = 10 - 5.9 = 4.1
        assertEq(vault.highWaterMark(), 4.1 ether, "HWM updated");
    }
}
