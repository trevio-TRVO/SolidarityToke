// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20AL {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
}

interface IRouterV2 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256, uint256, uint256);
}

interface IPairV2 {
    function getReserves() external view returns (uint112, uint112, uint32);
    function token0() external view returns (address);
}

/// @title AutoLiquidity - transforme la réserve de 1 % en liquidité verrouillée.
/// @notice Sans owner : n'importe qui peut appeler addLiquidity(), au plus une fois par 24 h.
///         Les LP tokens sont envoyés à l'adresse morte (liquidité définitivement verrouillée).
///         Montant limité à 0,2 % de la réserve de la paire par appel pour réduire l'impact et
///         l'intérêt d'une attaque sandwich. Adresses du routeur et de la paire immuables.
contract AutoLiquidity {
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 public constant COOLDOWN = 1 days;
    uint256 public constant MAX_BPS_OF_RESERVE = 20; // 0,2 %
    uint256 public constant SLIPPAGE_BPS = 500; // 5 %

    IERC20AL public immutable token;
    IERC20AL public immutable usdc;
    IRouterV2 public immutable router;
    IPairV2 public immutable pair;
    /// Réserve initiale (499 500 000 BILL) : injectée progressivement en face des USDC récoltés.
    uint256 public constant INITIAL_STOCK = 499_500_000e18;
    uint256 public stockLeft = INITIAL_STOCK;
    uint256 public lastRun;

    event LiquidityAdded(uint256 tokensSold, uint256 usdcAdded, uint256 tokensAdded, uint256 lpTokens);

    constructor(IERC20AL _token, IERC20AL _usdc, IRouterV2 _router, IPairV2 _pair) {
        token = _token;
        usdc = _usdc;
        router = _router;
        pair = _pair;
    }

    function _reserves() internal view returns (uint256 rToken, uint256 rUsdc) {
        (uint256 r0, uint256 r1,) = pair.getReserves();
        (rToken, rUsdc) = pair.token0() == address(token) ? (r0, r1) : (r1, r0);
    }

    /// @notice Récolte la contribution de 1 % (hors réserve initiale), la vend en USDC, puis ajoute
    /// la liquidité avec la quantité de BILL correspondante prise sur la réserve initiale.
    function addLiquidity() external {
        require(block.timestamp >= lastRun + COOLDOWN, "cooldown");
        lastRun = block.timestamp;

        (uint256 rToken, uint256 rUsdc) = _reserves();
        uint256 bal = token.balanceOf(address(this));
        uint256 harvest = bal > stockLeft ? bal - stockLeft : 0;
        uint256 cap = (rToken * MAX_BPS_OF_RESERVE) / 10_000;
        if (harvest > cap) harvest = cap;
        require(harvest > 1, "nothing to add");

        // réserve initiale restante : tout est vendu ; sinon moitié vendue, moitié en liquidité
        uint256 sold = stockLeft > 0 ? harvest : harvest / 2;
        uint256 expected = (sold * 997 * rUsdc) / (rToken * 1000 + sold * 997);
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(usdc);
        token.approve(address(router), sold);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            sold, (expected * (10_000 - SLIPPAGE_BPS)) / 10_000, path, address(this), block.timestamp
        );

        (rToken, rUsdc) = _reserves();
        uint256 usdcBal = usdc.balanceOf(address(this));
        uint256 tokenForLp = harvest - sold;
        uint256 needed = (usdcBal * rToken) / rUsdc;
        if (needed > tokenForLp) {
            uint256 extra = needed - tokenForLp;
            if (extra > stockLeft) extra = stockLeft;
            stockLeft -= extra;
            tokenForLp += extra;
        }
        if (needed > tokenForLp) usdcBal = (tokenForLp * rUsdc) / rToken;

        token.approve(address(router), tokenForLp);
        usdc.approve(address(router), usdcBal);
        (uint256 aT, uint256 aU, uint256 lp) = router.addLiquidity(
            address(token),
            address(usdc),
            tokenForLp,
            usdcBal,
            (tokenForLp * 9000) / 10_000,
            (usdcBal * 9000) / 10_000,
            DEAD,
            block.timestamp
        );
        emit LiquidityAdded(sold, aU, aT, lp);
    }
}
