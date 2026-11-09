// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SolidarityWallet, IERC20Min, ICommunityLots, ICouncilRegistry} from "../contracts/SolidarityWallet.sol";
import {CouncilRegistry} from "../contracts/CouncilRegistry.sol";

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
    MockToken token; MockLots lots; SolidarityWallet w; CouncilRegistry reg;
    address sig1 = address(0x51); address sig2 = address(0x52); address sig3 = address(0x53);
    address founder = address(0xF0);
    address payee = address(0xCAFE);
    address[10] council;

    function setUp() public {
        vm.warp(1_000_000);
        token = new MockToken(); lots = new MockLots();
        for (uint256 i; i < 10; i++) council[i] = address(uint160(0xC000 + i));
        address[] memory sigs = new address[](3);
        sigs[0] = sig1; sigs[1] = sig2; sigs[2] = sig3;
        reg = new CouncilRegistry(founder, council, sigs, 2);
        w = new SolidarityWallet(IERC20Min(address(token)), ICommunityLots(address(lots)), founder, ICouncilRegistry(address(reg)));
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
        (,,,,, SolidarityWallet.Status s) = w.requests(id);
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

    function _newList() internal pure returns (address[10] memory l) {
        for (uint256 i; i < 10; i++) l[i] = address(uint160(0xD000 + i));
    }
    function _rotate(address[10] memory l) internal {
        vm.prank(sig1); reg.confirmRotation(l);
        vm.prank(sig2); reg.confirmRotation(l);
    }

    // --- registre et rotation ---

    function testRegistryInitial() public view {
        require(reg.isMember(council[3]) && !reg.isMember(founder), "initial");
        require(reg.threshold() == 2 && reg.epoch() == 0, "params");
    }

    function testRotationReplacesCouncil() public {
        vm.warp(block.timestamp + 30 days);
        address[10] memory l = _newList();
        vm.prank(sig1); reg.confirmRotation(l);
        require(!reg.isMember(l[0]), "one confirmation is not enough");
        vm.prank(sig2); reg.confirmRotation(l);
        require(reg.isMember(l[0]) && !reg.isMember(council[0]) && reg.epoch() == 1, "rotated");
        require(reg.council(9) == l[9], "seat");
    }

    function testRotationTooSoon() public {
        vm.warp(block.timestamp + 30 days);
        _rotate(_newList());
        address[10] memory l = _newList(); l[0] = address(0xE0);
        vm.prank(sig1); vm.expectRevert("too soon"); reg.confirmRotation(l);
        vm.warp(block.timestamp + 30 days);
        _rotate(l);
        require(reg.isMember(address(0xE0)) && reg.epoch() == 2, "second rotation");
    }

    function testRotationBeforeFirstMonthRejected() public {
        vm.prank(sig1); vm.expectRevert("too soon"); reg.confirmRotation(_newList());
    }

    function testOnlySignerAndNoDoubleConfirm() public {
        vm.warp(block.timestamp + 30 days);
        address[10] memory l = _newList();
        vm.prank(address(0xBAD)); vm.expectRevert("not signer"); reg.confirmRotation(l);
        vm.prank(council[0]); vm.expectRevert("not signer"); reg.confirmRotation(l);
        vm.prank(sig1); reg.confirmRotation(l);
        vm.prank(sig1); vm.expectRevert("already confirmed"); reg.confirmRotation(l);
    }

    function testDifferentListsDoNotAddUp() public {
        vm.warp(block.timestamp + 30 days);
        address[10] memory a = _newList(); address[10] memory b = _newList(); b[5] = address(0xE5);
        vm.prank(sig1); reg.confirmRotation(a);
        vm.prank(sig2); reg.confirmRotation(b);
        require(reg.epoch() == 0 && reg.isMember(council[0]), "no rotation");
    }

    function testBadListsRejected() public {
        vm.warp(block.timestamp + 30 days);
        address[10] memory l = _newList(); l[2] = address(0);
        vm.prank(sig1); vm.expectRevert("bad member"); reg.confirmRotation(l);
        l = _newList(); l[4] = founder;
        vm.prank(sig1); vm.expectRevert("bad member"); reg.confirmRotation(l);
        l = _newList(); l[7] = l[1];
        vm.prank(sig1); vm.expectRevert("duplicate member"); reg.confirmRotation(l);
    }

    function testConstructorChecks() public {
        address[] memory none = new address[](0);
        vm.expectRevert("bad signers"); new CouncilRegistry(founder, council, none, 1);
        address[] memory s = new address[](2); s[0] = sig1; s[1] = sig1;
        vm.expectRevert("bad signer"); new CouncilRegistry(founder, council, s, 1);
        s[1] = sig2;
        vm.expectRevert("bad threshold"); new CouncilRegistry(founder, council, s, 3);
        address[10] memory dup = council; dup[1] = dup[0];
        vm.expectRevert("duplicate member"); new CouncilRegistry(founder, dup, s, 1);
    }

    // --- effets de la rotation sur le portefeuille ---

    function testRemovedMemberLosesVotingRights() public {
        vm.warp(block.timestamp + 30 days);
        _rotate(_newList());
        uint256 id = _ready();
        vm.prank(council[0]); vm.expectRevert("not council"); w.approve(id);
        vm.prank(council[0]); vm.expectRevert("not council"); w.cancelByCouncil(id);
        _approve(id, address(0xD000));
        require(w.approvalWeight(id) == 1, "new member votes");
    }

    function testRemovedMembersApprovalsDoNotCount() public {
        uint256 id = _ready();
        for (uint256 i; i < 5; i++) _approve(id, council[i]);
        vm.warp(block.timestamp + 30 days);
        _rotate(_newList());
        require(w.approvalWeight(id) == 0, "weight reset");
        vm.expectRevert("council weight");
        w.execute(id);
    }

    function testFounderApprovalSurvivesRotationAndNeedsTwoNew() public {
        uint256 id = _ready();
        _approve(id, founder); _approve(id, council[0]); _approve(id, council[1]);
        vm.warp(block.timestamp + 30 days);
        _rotate(_newList());
        require(w.approvalWeight(id) == 3, "founder only");
        _approve(id, address(0xD000));
        vm.expectRevert("council weight");
        w.execute(id);
        _approve(id, address(0xD001));
        w.execute(id);
        require(token.balanceOf(payee) == 100e18, "paid");
    }

    function testRemovedMembersCancelVotesDoNotCount() public {
        uint256 id = _ready();
        for (uint256 i; i < 4; i++) { vm.prank(council[i]); w.cancelByCouncil(id); }
        vm.warp(block.timestamp + 30 days);
        _rotate(_newList());
        vm.prank(address(0xD000)); w.cancelByCouncil(id);
        (,,,,, SolidarityWallet.Status s) = w.requests(id);
        require(s == SolidarityWallet.Status.Open, "still open");
    }
}
