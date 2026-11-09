// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {CommunityLots, IERC20} from "../contracts/CommunityLots.sol";

interface Vm {
    function warp(uint256) external;
    function prank(address) external;
    function expectRevert(bytes calldata) external;
}

contract MockERC20 {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function mint(address to, uint256 a) external { balanceOf[to] += a; }
    function approve(address s, uint256 a) external returns (bool) { allowance[msg.sender][s] = a; return true; }
    function transfer(address to, uint256 a) external returns (bool) {
        balanceOf[msg.sender] -= a; balanceOf[to] += a; return true;
    }
    function transferFrom(address f, address to, uint256 a) external returns (bool) {
        allowance[f][msg.sender] -= a; balanceOf[f] -= a; balanceOf[to] += a; return true;
    }
}

contract CommunityLotsTest {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
    MockERC20 token; MockERC20 usdc; CommunityLots lots;
    address treasury = address(0xAAA);
    address[10] free;

    uint256 constant T0 = 1_000_000;
    uint256 constant P0 = 50e6;
    uint256 constant Q0 = 100e18;

    function setUp() public {
        vm.warp(T0);
        token = new MockERC20(); usdc = new MockERC20();
        for (uint256 i; i < 10; i++) free[i] = address(uint160(0xF000 + i));
        uint256[] memory p = new uint256[](2); p[0] = P0; p[1] = P0 * 2;
        uint256[] memory q = new uint256[](2); q[0] = Q0; q[1] = Q0 / 2;
        lots = new CommunityLots(IERC20(address(token)), IERC20(address(usdc)), treasury, p, q, free);
        token.mint(address(lots), 100_000e18);
    }

    function _buyer(uint256 i) internal returns (address b) {
        b = address(uint160(0xB000 + i));
        usdc.mint(b, 1_000e6);
        vm.prank(b); usdc.approve(address(lots), type(uint256).max);
    }

    function _buy(address b) internal { vm.prank(b); lots.buy(); }

    function testBuyPaysTreasuryAndCreatesGrant() public {
        address b = _buyer(1); _buy(b);
        require(usdc.balanceOf(treasury) == P0, "treasury");
        (uint128 total,, uint64 start) = lots.grants(b, 0);
        require(total == Q0 && start == T0, "grant");
    }

    function testOneBuyPerWallet() public {
        address b = _buyer(1); _buy(b);
        vm.expectRevert("already bought");
        vm.prank(b); lots.buy();
    }

    function testSeriesAdvancesAfter90AndPriceDoubles() public {
        for (uint256 i; i < 90; i++) _buy(_buyer(i));
        require(lots.currentSeries() == 1, "series");
        address b = _buyer(500); _buy(b);
        require(usdc.balanceOf(b) == 1_000e6 - 2 * P0, "price x2");
        (uint128 total,,) = lots.grants(b, 0);
        require(total == Q0 / 2, "scarcity");
    }

    function testSoldOut() public {
        for (uint256 i; i < 180; i++) _buy(_buyer(i));
        address b = _buyer(999);
        vm.expectRevert("sold out");
        _buy(b);
    }

    function testVestingCliffAndLinear() public {
        address b = _buyer(1); _buy(b);
        vm.warp(T0 + 45 days - 1);
        require(lots.vested(b, 0) == 0, "cliff");
        vm.prank(b); vm.expectRevert("nothing to claim"); lots.claim(0);
        vm.warp(T0 + 45 days + 15 days);
        require(lots.vested(b, 0) == Q0 / 2, "half");
        vm.prank(b); lots.claim(0);
        require(token.balanceOf(b) == Q0 / 2, "claimed half");
        vm.warp(T0 + 75 days + 1);
        vm.prank(b); lots.claim(0);
        require(token.balanceOf(b) == Q0, "all");
        require(lots.outstanding() == 0, "outstanding");
    }

    function testFreeAllocationOnceAndGated() public {
        vm.expectRevert("series not open");
        lots.allocateFree(1);
        lots.allocateFree(0);
        for (uint256 i; i < 10; i++) require(lots.grantCount(free[i]) == 1, "free grant");
        vm.expectRevert("done");
        lots.allocateFree(0);
    }

    function testUnderfundedPoolReverts() public {
        uint256[] memory p = new uint256[](1); p[0] = P0;
        uint256[] memory q = new uint256[](1); q[0] = Q0;
        CommunityLots l = new CommunityLots(IERC20(address(token)), IERC20(address(usdc)), treasury, p, q, free);
        address b = _buyer(7);
        vm.prank(b); usdc.approve(address(l), type(uint256).max);
        vm.prank(b); vm.expectRevert("pool underfunded"); l.buy();
    }

    function testConstructorRejectsPriceAboveX2() public {
        uint256[] memory p = new uint256[](2); p[0] = P0; p[1] = P0 * 2 + 1;
        uint256[] memory q = new uint256[](2); q[0] = Q0; q[1] = Q0;
        vm.expectRevert("price > x2");
        new CommunityLots(IERC20(address(token)), IERC20(address(usdc)), treasury, p, q, free);
    }

    function testConstructorRejectsGrowingQuantity() public {
        uint256[] memory p = new uint256[](2); p[0] = P0; p[1] = P0 * 2;
        uint256[] memory q = new uint256[](2); q[0] = Q0; q[1] = Q0 + 1;
        vm.expectRevert("quantity must not grow");
        new CommunityLots(IERC20(address(token)), IERC20(address(usdc)), treasury, p, q, free);
    }
}
