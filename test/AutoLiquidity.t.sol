// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AutoLiquidity, IERC20AL, IRouterV2, IPairV2} from "../contracts/AutoLiquidity.sol";

interface Vm {
    function warp(uint256) external;
    function deal(address, uint256) external;
    function expectRevert(bytes calldata) external;
}

contract MToken {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    function mint(address to, uint256 a) external { balanceOf[to] += a; }
    function approve(address s, uint256 a) external returns (bool) { allowance[msg.sender][s] = a; return true; }
    function transferFrom(address f, address to, uint256 a) external returns (bool) {
        allowance[f][msg.sender] -= a; balanceOf[f] -= a; balanceOf[to] += a; return true;
    }
}

contract MPair {
    address public token0;
    constructor(address t) { token0 = t; }
    function getReserves() external pure returns (uint112, uint112, uint32) { return (1_000_000e18, 100e18, 0); }
}

contract MRouter {
    MToken token;
    uint256 public lastMin;
    address public lastLpTo;
    constructor(MToken t) { token = t; }
    receive() external payable {}
    function WETH() external pure returns (address) { return address(0xE7); }
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 a, uint256 minOut, address[] calldata, address to, uint256)
        external
    {
        token.transferFrom(msg.sender, address(this), a);
        lastMin = minOut;
        (bool ok,) = to.call{value: minOut}("");
        require(ok);
    }
    function addLiquidityETH(address, uint256 amt, uint256, uint256, address to, uint256)
        external payable returns (uint256, uint256, uint256)
    {
        token.transferFrom(msg.sender, address(this), amt);
        lastLpTo = to;
        return (amt, msg.value, 1);
    }
}

contract AutoLiquidityTest {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
    MToken token; MRouter router; AutoLiquidity al;

    function setUp() public {
        vm.warp(10 days);
        token = new MToken(); router = new MRouter(token);
        vm.deal(address(router), 10 ether);
        al = new AutoLiquidity(IERC20AL(address(token)), IRouterV2(address(router)), IPairV2(address(new MPair(address(token)))));
        token.mint(address(al), 50_000e18);
    }

    function testAddsLimitedAmountAndLocksLp() public {
        al.addLiquidity();
        // plafond : 0,2 % de 1 000 000 = 2 000 tokens ; la moitié est vendue
        require(token.balanceOf(address(al)) == 48_000e18, "cap");
        require(token.balanceOf(address(router)) == 2_000e18, "router got 2000");
        require(router.lastLpTo() == 0x000000000000000000000000000000000000dEaD, "lp burned");
        require(router.lastMin() > 0, "slippage floor");
    }

    function testCooldown() public {
        al.addLiquidity();
        vm.expectRevert("cooldown");
        al.addLiquidity();
        vm.warp(block.timestamp + 1 days);
        al.addLiquidity();
    }

    function testNothingToAdd() public {
        AutoLiquidity empty = new AutoLiquidity(IERC20AL(address(token)), IRouterV2(address(router)), IPairV2(address(new MPair(address(token)))));
        vm.expectRevert("nothing to add");
        empty.addLiquidity();
    }
}
