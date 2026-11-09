// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {VestingWallet} from "@openzeppelin/contracts/finance/VestingWallet.sol";
import {TrvoToken} from "../src/TrvoToken.sol";

contract TrvoTokenTest is Test {
    TrvoToken trvo;
    address holder = makeAddr("holder");

    function setUp() public {
        trvo = new TrvoToken(holder, 21_000_000e18);
    }

    function test_supplyAndMetadata() public view {
        assertEq(trvo.totalSupply(), 21_000_000e18);
        assertEq(trvo.balanceOf(holder), 21_000_000e18);
        assertEq(trvo.decimals(), 18);
        assertEq(trvo.symbol(), "TRVO");
    }

    function test_zeroRecipientReverts() public {
        vm.expectRevert("recipient=0");
        new TrvoToken(address(0), 1e18);
    }

    function test_zeroSupplyReverts() public {
        vm.expectRevert("supply=0");
        new TrvoToken(holder, 0);
    }

    /// ABI check: none of the privileged selectors exist.
    function test_noPrivilegedFunctions() public {
        bytes4[7] memory sels = [
            bytes4(keccak256("mint(address,uint256)")),
            bytes4(keccak256("burn(uint256)")),
            bytes4(keccak256("pause()")),
            bytes4(keccak256("unpause()")),
            bytes4(keccak256("owner()")),
            bytes4(keccak256("transferOwnership(address)")),
            bytes4(keccak256("blacklist(address)"))
        ];
        for (uint256 i = 0; i < sels.length; i++) {
            (bool ok,) = address(trvo).call(abi.encodeWithSelector(sels[i], address(1), 1));
            assertFalse(ok);
        }
        assertEq(trvo.totalSupply(), 21_000_000e18);
    }
}

contract VestingTest is Test {
    TrvoToken trvo;
    address beneficiary = makeAddr("beneficiary");

    function setUp() public {
        trvo = new TrvoToken(address(this), 21_000_000e18);
    }

    function _wallet(uint256 amount, uint64 start, uint64 duration)
        internal
        returns (VestingWallet w)
    {
        w = new VestingWallet(beneficiary, start, duration);
        trvo.transfer(address(w), amount);
    }

    function test_teamLockedThenLinear() public {
        uint64 start = uint64(block.timestamp) + 365 days;
        uint64 dur = 4 * 365 days;
        VestingWallet w = _wallet(4_200_000e18, start, dur);

        vm.warp(start - 1);
        assertEq(w.releasable(address(trvo)), 0);

        vm.warp(start + dur / 2);
        assertEq(w.releasable(address(trvo)), 2_100_000e18);
        w.release(address(trvo));
        assertEq(trvo.balanceOf(beneficiary), 2_100_000e18);

        vm.warp(start + dur);
        w.release(address(trvo));
        assertEq(trvo.balanceOf(beneficiary), 4_200_000e18);
    }

    function test_treasuryAndRewardsStartAtAnchor() public {
        uint64 start = uint64(block.timestamp);
        uint64 dur = 5 * 365 days;
        VestingWallet t = _wallet(6_300_000e18, start, dur);
        VestingWallet r = _wallet(4_200_000e18, start, dur);
        vm.warp(start + dur);
        assertEq(t.releasable(address(trvo)), 6_300_000e18);
        assertEq(r.releasable(address(trvo)), 4_200_000e18);
    }

    function test_zeroBeneficiaryReverts() public {
        vm.expectRevert();
        new VestingWallet(address(0), uint64(block.timestamp), 1 days);
    }
}
