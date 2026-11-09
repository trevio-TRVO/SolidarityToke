// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MonthlyVesting, IERC20MV} from "../contracts/MonthlyVesting.sol";

interface Vm { function warp(uint256) external; function expectRevert(bytes calldata) external; }

contract MT {
    mapping(address => uint256) public balanceOf;
    function mint(address to, uint256 a) external { balanceOf[to] += a; }
    function transfer(address to, uint256 a) external returns (bool) { balanceOf[msg.sender] -= a; balanceOf[to] += a; return true; }
}

contract MonthlyVestingTest {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
    MT t; MonthlyVesting v;
    address ben = address(0xBEEF);

    function setUp() public {
        vm.warp(1_000_000);
        t = new MT();
        v = new MonthlyVesting(ben, block.timestamp, 48);
        t.mint(address(v), 150_000_000e18);
    }

    function testNothingBeforeFirstMonth() public {
        vm.warp(1_000_000 + 30 days - 1);
        vm.expectRevert("nothing to release");
        v.release(IERC20MV(address(t)));
    }

    function testOneFortyEighthPerMonth() public {
        vm.warp(1_000_000 + 30 days);
        v.release(IERC20MV(address(t)));
        require(t.balanceOf(ben) == 150_000_000e18 / 48, "1/48");
        vm.warp(1_000_000 + 90 days);
        v.release(IERC20MV(address(t)));
        require(t.balanceOf(ben) == 150_000_000e18 * 3 / 48, "3/48");
    }

    function testFullyVestedAfter48Months() public {
        vm.warp(1_000_000 + 48 * 30 days);
        v.release(IERC20MV(address(t)));
        require(t.balanceOf(ben) == 150_000_000e18, "all");
    }
}
