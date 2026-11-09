// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SolidarityWallet, IERC20Min, ICommunityLots} from "../contracts/SolidarityWallet.sol";

interface Vm {
    function warp(uint256) external;
    function prank(address) external;
    function expectRevert(bytes calldata) external;
}

contract MockToken {
    mapping(address => uint256) public balanceOf;
    function mint(address to, uint256 a) external { balanceOf[to] += a; }
    function transfer(address to, uint256 a) external returns (bool) {
        balanceOf[msg.sender] -= a; balanceOf[to] += a; return true;
    }
}

contract MockLots {
    mapping(address => bool) public hasBought;
    function set(address a) external { hasBought[a] = true; }
}

contract SolidarityWalletTest {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
    MockToken token; MockLots lots; SolidarityWallet w;
    address founder = address(0xF0);
    address payee = address(0xCAFE);
    address[10] council;

    function setUp() public {
        vm.warp(1_000_000);
        token = new MockToken(); lots = new MockLots();
        for (uint256 i; i < 10; i++) council[i] = address(uint160(0xC000 + i));
        w = new SolidarityWallet(IERC20Min(address(token)), ICommunityLots(address(lots)), founder, council);
        token.mint(address(w), 1_000e18);
        for (uint256 i; i < 6; i++) lots.set(address(uint160(0xA000 + i)));
    }

    function _validate(uint256 id, uint256 n) internal {
        for (uint256 i; i < n; i++) { vm.prank(address(uint160(0xA000 + i))); w.validate(id); }
    }
    function _approve(uint256 id, address a) internal { vm.prank(a); w.approve(id); }

    function _ready() internal returns (uint256 id) {
        id = w.createRequest(payee, 100e18, keccak256("invoice"));
        _validate(id, 5);
    }

    function testHappyPathFounderPlusTwoCouncil() public {
        uint256 id = _ready();
        _approve(id, founder); _approve(id, council[0]); _approve(id, council[1]);
        vm.warp(block.timestamp + 24 hours);
        w.execute(id);
        require(token.balanceOf(payee) == 100e18, "paid");
    }

    function testFounderAloneCannotPay() public {
        uint256 id = _ready();
        _approve(id, founder);
        vm.warp(block.timestamp + 24 hours);
        vm.expectRevert("council weight");
        w.execute(id);
    }

    function testFiveCouncilMembersWithoutFounder() public {
        uint256 id = _ready();
        for (uint256 i; i < 5; i++) _approve(id, council[i]);
        vm.warp(block.timestamp + 24 hours);
        w.execute(id);
        require(token.balanceOf(payee) == 100e18, "paid");
    }

    function testNeedsFiveValidators() public {
        uint256 id = w.createRequest(payee, 100e18, bytes32(0));
        _validate(id, 4);
        for (uint256 i; i < 5; i++) _approve(id, council[i]);
        vm.warp(block.timestamp + 24 hours);
        vm.expectRevert("validators");
        w.execute(id);
    }

    function testNonLotHolderCannotValidate() public {
        uint256 id = w.createRequest(payee, 100e18, bytes32(0));
        vm.prank(address(0xDEAD)); vm.expectRevert("not a lot holder"); w.validate(id);
    }

    function testCycleDelay() public {
        uint256 id = _ready();
        for (uint256 i; i < 5; i++) _approve(id, council[i]);
        vm.expectRevert("cycle not elapsed");
        w.execute(id);
    }

    function testFounderCanCancel() public {
        uint256 id = _ready();
        vm.prank(founder); w.cancel(id);
        vm.expectRevert("not open");
        w.execute(id);
    }

    function testNonFounderCannotCancelAlone() public {
        uint256 id = _ready();
        vm.prank(council[0]); vm.expectRevert("founder only"); w.cancel(id);
    }

    function testCouncilCancelAtWeightFive() public {
        uint256 id = _ready();
        for (uint256 i; i < 5; i++) { vm.prank(council[i]); w.cancelByCouncil(id); }
        (,,,,,, SolidarityWallet.Status s) = w.requests(id);
        require(s == SolidarityWallet.Status.Cancelled, "cancelled");
    }

    function testCapAndCooldown() public {
        vm.expectRevert("above cap");
        w.createRequest(payee, 201e18, bytes32(0));
        uint256 id = _ready();
        for (uint256 i; i < 5; i++) _approve(id, council[i]);
        vm.warp(block.timestamp + 24 hours);
        w.execute(id);
        vm.expectRevert("payee cooldown");
        w.createRequest(payee, 10e18, bytes32(0));
    }
}
