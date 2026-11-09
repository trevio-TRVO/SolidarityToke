// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TrvoToken} from "../src/TrvoToken.sol";
import {TokenSale} from "../src/TokenSale.sol";

contract MockUSDC is ERC20 {
    constructor() ERC20("USDC", "USDC") {}

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(address to, uint256 amt) external {
        _mint(to, amt);
    }
}

contract TokenSaleTest is Test {
    MockUSDC usdc;
    TrvoToken trvo;
    TokenSale sale;

    address treasury = makeAddr("treasuryVesting");
    address multisig = makeAddr("multisig");
    address liquidity = makeAddr("liquidity");
    uint256 start;
    uint256 end;

    function setUp() public {
        usdc = new MockUSDC();
        // Test-only supply (real supply is pending confirmation).
        trvo = new TrvoToken(address(this), 21_000_000e18);
        start = block.timestamp + 1 days;
        end = start + 14 days;
        sale = new TokenSale(
            IERC20(address(usdc)), IERC20(address(trvo)), treasury, multisig, liquidity, start, end
        );
        trvo.transfer(address(sale), sale.TOKENS_FOR_SALE());
    }

    function _buy(address who, uint256 amt) internal {
        usdc.mint(who, amt);
        vm.startPrank(who);
        usdc.approve(address(sale), amt);
        sale.buy(amt);
        vm.stopPrank();
    }

    function _raise(uint256 buyers) internal {
        for (uint256 i = 0; i < buyers; i++) {
            _buy(address(uint160(1000 + i)), 500e6);
        }
    }

    function test_priceIsExact() public {
        vm.warp(start);
        address b = makeAddr("b");
        _buy(b, 1e6);
        assertEq(sale.purchased(b), 420e18);
    }

    function test_revertBeforeStartAndAfterEnd() public {
        usdc.mint(address(this), 1e6);
        usdc.approve(address(sale), 1e6);
        vm.expectRevert("not open");
        sale.buy(1e6);
        vm.warp(end);
        vm.expectRevert("not open");
        sale.buy(1e6);
    }

    function test_revertOverWalletCap() public {
        vm.warp(start);
        address b = makeAddr("b");
        _buy(b, 500e6);
        usdc.mint(b, 1e6);
        vm.startPrank(b);
        usdc.approve(address(sale), 1e6);
        vm.expectRevert("wallet cap");
        sale.buy(1e6);
        vm.stopPrank();
    }

    function test_refundWhenSoftCapMissed() public {
        vm.warp(start);
        address b = makeAddr("b");
        _buy(b, 100e6);
        vm.warp(end);
        assertTrue(sale.saleFailed());
        vm.prank(b);
        sale.refund();
        assertEq(usdc.balanceOf(b), 100e6);
        vm.prank(b);
        vm.expectRevert("already refunded");
        sale.refund();
        vm.expectRevert("soft cap missed");
        sale.finalize();
        sale.recoverFailedSaleTokens();
        assertEq(trvo.balanceOf(treasury), sale.TOKENS_FOR_SALE());
    }

    function test_finalizeAtSoftCap() public {
        vm.warp(start);
        _raise(10); // 5,000 USDC
        vm.warp(end);
        sale.finalize();
        assertEq(usdc.balanceOf(liquidity), 5_000e6);
        assertEq(usdc.balanceOf(multisig), 0);
        assertEq(trvo.balanceOf(treasury), sale.TOKENS_FOR_SALE() - 5_000e6 * 420e12);
        vm.expectRevert("finalized");
        sale.finalize();
    }

    function test_finalizeSurplusToMultisig() public {
        vm.warp(start);
        _raise(14); // 7,000 USDC
        vm.warp(end);
        sale.finalize();
        assertEq(usdc.balanceOf(liquidity), 5_000e6);
        assertEq(usdc.balanceOf(multisig), 2_000e6);
    }

    function test_noRefundAfterSuccess() public {
        vm.warp(start);
        _raise(10);
        vm.warp(end);
        sale.finalize();
        vm.prank(address(1000));
        vm.expectRevert("no refund");
        sale.refund();
    }

    function test_buyerVesting() public {
        vm.warp(start);
        _raise(10);
        vm.warp(end);
        sale.finalize();
        address b = address(1000);
        uint256 total = sale.purchased(b);
        vm.prank(b);
        sale.claim();
        assertEq(trvo.balanceOf(b), total / 4);
        vm.warp(block.timestamp + 90 days);
        assertEq(sale.vested(b), total / 4 + (total - total / 4) / 2);
        vm.warp(block.timestamp + 365 days);
        vm.prank(b);
        sale.claim();
        assertEq(trvo.balanceOf(b), total);
    }

    function test_claimBeforeFinalizeReverts() public {
        vm.warp(start);
        _buy(address(1000), 500e6);
        vm.prank(address(1000));
        vm.expectRevert("nothing");
        sale.claim();
    }

    function testFuzz_priceLinear(uint256 amt) public {
        amt = bound(amt, 1, 500e6);
        vm.warp(start);
        address b = makeAddr("f");
        _buy(b, amt);
        assertEq(sale.purchased(b), amt * 420e12);
    }
}
