// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AutoLiquidity, IERC20AL, IRouterV2, IPairV2} from "../contracts/AutoLiquidity.sol";

interface Vm {
    function warp(uint256) external;
    function expectRevert(bytes calldata) external;
}

contract MToken {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    function mint(address to, uint256 a) external { balanceOf[to] += a; }
    function approve(address s, uint256 a) external returns (bool) { allowance[msg.sender][s] = a; return true; }
    function transfer(address to, uint256 a) external returns (bool) { balanceOf[msg.sender] -= a; balanceOf[to] += a; return true; }
    function transferFrom(address f, address to, uint256 a) external returns (bool) {
        allowance[f][msg.sender] -= a; balanceOf[f] -= a; balanceOf[to] += a; return true;
    }
}

contract MPair {
    address public token0;
    constructor(address t) { token0 = t; }
    function getReserves() external pure returns (uint112, uint112, uint32) { return (1_000_000e18, 100e6, 0); }
}

contract MRouter {
    MToken token; MToken usdc;
    uint256 public lastMin;
    address public lastLpTo;
    constructor(MToken t, MToken u) { token = t; usdc = u; }
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256 a, uint256 minOut, address[] calldata, address to, uint256)
        external
    {
        token.transferFrom(msg.sender, address(this), a);
        lastMin = minOut;
        usdc.transfer(to, minOut);
    }
    function addLiquidity(address, address, uint256 a, uint256 b, uint256, uint256, address to, uint256)
        external returns (uint256, uint256, uint256)
    {
        token.transferFrom(msg.sender, address(this), a);
        usdc.transferFrom(msg.sender, address(this), b);
        lastLpTo = to;
        return (a, b, 1);
    }
}

contract AutoLiquidityTest {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
    MToken token; MToken usdc; MRouter router; AutoLiquidity al;

    function _new() internal returns (AutoLiquidity) {
        return new AutoLiquidity(
            IERC20AL(address(token)), IERC20AL(address(usdc)), IRouterV2(address(router)),
            IPairV2(address(new MPair(address(token))))
        );
    }

    function setUp() public {
        vm.warp(10 days);
        token = new MToken(); usdc = new MToken(); router = new MRouter(token, usdc);
        usdc.mint(address(router), 1_000e6);
        al = _new();
        token.mint(address(al), 499_500_000e18 + 50_000e18);
    }

    function testAddsLimitedAmountAndLocksLp() public {
        al.addLiquidity();
        // plafond : 0,2 % de 1 000 000 = 2 000 tokens récoltés
        // 2 000 BILL récoltés vendus en USDC, puis liquidité appariée depuis la réserve initiale
        require(al.stockLeft() < 499_500_000e18, "stock used");
        require(token.balanceOf(address(al)) == al.stockLeft() + 48_000e18, "harvest capped");
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
        AutoLiquidity empty = _new();
        vm.expectRevert("nothing to add");
        empty.addLiquidity();
    }
}
