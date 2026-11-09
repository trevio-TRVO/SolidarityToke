// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {BillPayProtocol} from "../contracts/BillPayProtocol.sol";

interface Vm {
    function warp(uint256) external;
    function prank(address) external;
    function expectRevert(bytes calldata) external;
}

contract BillPayProtocolTest {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
    BillPayProtocol t;
    address constant PAIR = address(0xAA11);
    address constant AID = address(0xA1D);
    address constant OPS = address(0x0B5);
    address constant LIQ = address(0x11C);
    address constant LP = address(0x1B0); // ajoute la liquidité initiale
    address constant USER = address(0xBEEF);
    address constant USER2 = address(0xCAFE);
    uint256 constant SUPPLY = 1_000_000e18;

    function setUp() public {
        address[] memory r = new address[](2);
        uint256[] memory a = new uint256[](2);
        r[0] = LP; a[0] = 900_000e18;
        r[1] = USER; a[1] = 100_000e18;
        address[] memory pairs = new address[](1); pairs[0] = PAIR;
        address[] memory ex = new address[](1); ex[0] = LP;
        t = new BillPayProtocol(SUPPLY, r, a, AID, OPS, LIQ, pairs, ex);
        vm.prank(LP); t.transfer(PAIR, 500_000e18); // liquidité initiale, exemptée
    }

    function testFixedSupplyAndAllocation() public view {
        require(t.totalSupply() == SUPPLY, "supply");
        require(t.balanceOf(PAIR) == 500_000e18, "liq seeded without fee");
    }

    function testSellTakesTenPercentSplit() public {
        vm.prank(USER); t.transfer(PAIR, 1_000e18);
        require(t.balanceOf(PAIR) == 500_000e18 + 900e18, "pair 90%");
        require(t.balanceOf(AID) == 50e18, "5% aid");
        require(t.balanceOf(OPS) == 20e18, "2% ops");
        require(t.balanceOf(LIQ) == 10e18, "1% liq");
        require(t.totalSupply() == SUPPLY - 20e18, "2% burned");
    }

    function testBuyTakesTenPercent() public {
        vm.prank(PAIR); t.transfer(USER2, 1_000e18);
        require(t.balanceOf(USER2) == 900e18, "buyer 90%");
        require(t.balanceOf(AID) == 50e18, "aid");
    }

    function testP2PTransferIsFree() public {
        vm.prank(USER); t.transfer(USER2, 50_000e18);
        require(t.balanceOf(USER2) == 50_000e18, "no fee");
        require(t.balanceOf(AID) == 0, "no aid");
    }

    function testLaunchLimitPerTx() public {
        vm.prank(USER); vm.expectRevert("sell limit per tx");
        t.transfer(PAIR, 1_001e18);
        vm.prank(USER); t.transfer(PAIR, 1_000e18);
    }

    function testLaunchLimitPerWalletPerDay() public {
        vm.prank(USER); t.transfer(PAIR, 900e18);
        vm.prank(USER); t.transfer(PAIR, 900e18);
        vm.prank(USER); vm.expectRevert("sell limit per day");
        t.transfer(PAIR, 300e18);
        vm.warp(block.timestamp + 1 days);
        vm.prank(USER); t.transfer(PAIR, 900e18);
    }

    function testLimitsRelaxAfterLaunch() public {
        vm.warp(block.timestamp + 7 days);
        vm.prank(USER); vm.expectRevert("sell limit per tx");
        t.transfer(PAIR, 10_001e18);
        vm.prank(USER); t.transfer(PAIR, 9_900e18);
        vm.prank(USER); vm.expectRevert("sell limit per day");
        t.transfer(PAIR, 200e18);
    }

    function testExemptSeederUnlimited() public {
        vm.prank(LP); t.transfer(PAIR, 100_000e18);
    }

    function testBuysNotLimited() public {
        vm.prank(PAIR); t.transfer(USER2, 100_000e18);
    }

    function testSellLimitDoesNotApplyToP2P() public {
        vm.prank(USER); t.transfer(USER2, 50_000e18);
    }

    function testRejectsBadAllocation() public {
        address[] memory r = new address[](1); r[0] = LP;
        uint256[] memory a = new uint256[](1); a[0] = SUPPLY - 1;
        address[] memory none = new address[](0);
        vm.expectRevert("allocation != supply");
        new BillPayProtocol(SUPPLY, r, a, AID, OPS, LIQ, none, none);
    }
}
