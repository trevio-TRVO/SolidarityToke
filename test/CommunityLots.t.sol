// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {CommunityLots, IERC20, IPair} from "../contracts/CommunityLots.sol";

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
    function transfer(address to, uint256 a) external returns (bool) { balanceOf[msg.sender] -= a; balanceOf[to] += a; return true; }
    function transferFrom(address f, address to, uint256 a) external returns (bool) {
        allowance[f][msg.sender] -= a; balanceOf[f] -= a; balanceOf[to] += a; return true;
    }
}

/// Paire BILL/USDC simulée : prix constant, cumul mis à jour manuellement.
contract MockPair {
    address public token0;
    uint112 public r0 = 500_000_000e18; // BILL
    uint112 public r1 = 50_000e6;       // USDC -> 0,0001 USDC par BILL
    uint32 public ts;
    uint256 public price0CumulativeLast;
    constructor(address bill) { token0 = bill; ts = uint32(block.timestamp); }
    function price1CumulativeLast() external pure returns (uint256) { return 0; }
    function getReserves() external view returns (uint112, uint112, uint32) { return (r0, r1, ts); }
    function setUsdc(uint112 usdcReserve) external {
        uint32 n = uint32(block.timestamp);
        price0CumulativeLast += ((uint256(r1) << 112) / r0) * (n - ts);
        ts = n;
        r1 = usdcReserve;
    }
}

contract CommunityLotsTest {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
    MockERC20 token; MockERC20 usdc; MockPair pair; CommunityLots lots;
    address treasury = address(0xAAA);
    address[10] free;
    uint256 constant T0 = 1_000_000;
    uint256 constant LOT = 100_000e18;

    function setUp() public {
        vm.warp(T0);
        token = new MockERC20(); usdc = new MockERC20();
        pair = new MockPair(address(token));
        for (uint256 i; i < 10; i++) free[i] = address(uint160(0xF000 + i));
        lots = new CommunityLots(IERC20(address(token)), IERC20(address(usdc)), IPair(address(pair)), treasury, free);
        token.mint(address(lots), 150_000_000e18);
    }

    function _buyer(uint256 i) internal returns (address b) {
        b = address(uint160(0xB000 + i));
        usdc.mint(b, 1_000_000e6);
        vm.prank(b); usdc.approve(address(lots), type(uint256).max);
    }

    function _oracle() internal {
        lots.update();
        vm.warp(block.timestamp + 2 hours);
    }

    function testPioneerLotFixedPriceAndSupply() public {
        address b = _buyer(1);
        vm.prank(b); lots.buyPioneer();
        require(usdc.balanceOf(treasury) == 5e6, "5 USDC");
        (uint128 total,,) = lots.grants(b, 0);
        require(total == LOT, "100k BILL");
    }

    function testPioneersCappedAt100AndOnePerWallet() public {
        address b = _buyer(1);
        vm.prank(b); lots.buyPioneer();
        vm.prank(b); vm.expectRevert("already bought"); lots.buyPioneer();
        for (uint256 i = 2; i <= 100; i++) { address x = _buyer(i); vm.prank(x); lots.buyPioneer(); }
        address y = _buyer(500);
        vm.prank(y); vm.expectRevert("pioneers sold out"); lots.buyPioneer();
    }

    function testPaidLotPriceIsHalfOfMarket() public {
        _oracle();
        // marché : 0,0001 USDC/BILL -> lot = 10 USDC ; prix = 5 USDC
        uint256 mv = lots.lotMarketValue();
        require(mv >= 9_999_000 && mv <= 10e6, "market value");
        uint256 price = lots.lotPrice();
        require(price >= 4_999_500 && price <= 5e6, "50%");
        address b = _buyer(1);
        vm.prank(b); lots.buy();
        require(usdc.balanceOf(treasury) == price, "paid");
    }

    function testPriceFollowsMarketTwap() public {
        _oracle();
        pair.setUsdc(100_000e6); // le prix double
        vm.warp(block.timestamp + 1 days);
        lots.update();
        vm.warp(block.timestamp + 2 hours);
        require(lots.lotPrice() > 5e6 && lots.lotPrice() <= 10e6, "twap moves");
    }

    function testNoOracleNoBuy() public {
        address b = _buyer(1);
        vm.prank(b); vm.expectRevert("no oracle"); lots.buy();
    }

    function testSeriesOpenEvery30Days() public {
        _oracle();
        require(lots.availablePaidLots() == 90, "series 1");
        for (uint256 i; i < 90; i++) { address x = _buyer(i); vm.prank(x); lots.buy(); }
        address y = _buyer(900);
        vm.prank(y); vm.expectRevert("next series not open"); lots.buy();
        vm.warp(T0 + 30 days);
        lots.update();
        vm.warp(block.timestamp + 2 hours);
        require(lots.availablePaidLots() == 90, "series 2");
        vm.prank(y); lots.buy();
    }

    function testFreeLotsGoToTenWalletsOnce() public {
        vm.expectRevert("series not open");
        lots.allocateFree(2);
        lots.allocateFree(1);
        for (uint256 i; i < 10; i++) require(lots.grantCount(free[i]) == 1, "grant");
        vm.expectRevert("done");
        lots.allocateFree(1);
    }

    function testVestingCliff45ThenLinear30() public {
        address b = _buyer(1);
        vm.prank(b); lots.buyPioneer();
        vm.warp(T0 + 45 days - 1);
        require(lots.vested(b, 0) == 0, "cliff");
        vm.warp(T0 + 60 days);
        require(lots.vested(b, 0) == LOT / 2, "half");
        vm.prank(b); lots.claim(0);
        require(token.balanceOf(b) == LOT / 2, "claimed");
        vm.warp(T0 + 75 days);
        vm.prank(b); lots.claim(0);
        require(token.balanceOf(b) == LOT, "all");
        require(lots.outstanding() == 0, "outstanding");
    }

    function testUnderfundedPoolReverts() public {
        CommunityLots l = new CommunityLots(IERC20(address(token)), IERC20(address(usdc)), IPair(address(pair)), treasury, free);
        address b = _buyer(7);
        vm.prank(b); usdc.approve(address(l), type(uint256).max);
        vm.prank(b); vm.expectRevert("pool underfunded"); l.buyPioneer();
    }

    function testTotalPoolIs15Percent() public view {
        uint256 total = (100 + 14 * 100) * LOT;
        require(total == 150_000_000e18, "15% of 1B");
    }
}
