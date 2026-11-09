// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}

interface IPair {
    function token0() external view returns (address);
    function getReserves() external view returns (uint112, uint112, uint32);
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
}

/// @title CommunityLots V3 - 15 % de l'offre distribués en lots (sans admin)
/// @notice 1 500 lots de 100 000 BILL = 150 000 000 BILL :
///   - série 0 "pionniers" : 100 lots de valeur 10 USDC (prix fixe 5 USDC = 50 %), ouverts dès le lancement ;
///   - 14 séries continues, une toutes les 30 jours : 90 lots payants + 10 lots gratuits
///     (attribués aux 10 sous-wallets du wallet spécial, programme V4).
/// Prix d'un lot payant = 50 % de la valeur de marché (TWAP de la paire BILL/USDC) : le lot contient
/// donc 200 % de ce qui est payé. Un seul achat par wallet. Chaque lot : cliff 45 j puis linéaire 30 j.
/// Aucune fonction owner/admin : tout est immuable.
contract CommunityLots {
    uint256 public constant LOT_TOKENS = 100_000e18;
    uint256 public constant PIONEER_LOTS = 100;
    uint256 public constant PIONEER_PRICE = 10e6; // 10 USDC, quantité fixe (100 000 BILL au prix de lancement 0,0001)
    uint256 public constant SERIES_COUNT = 14;
    uint256 public constant PAID_LOTS = 90;
    uint256 public constant FREE_LOTS = 10;
    uint256 public constant SERIES_INTERVAL = 30 days;
    uint256 public constant LOT_PRICE = 50e6; // 50 USDC, prix d'un lot payant
    uint256 public constant LOT_VALUE = 100e6; // valeur de marché livrée (x2) : 100 USDC
    uint256 public constant TRIGGER_LOT_TOKENS = 100_000e18; // seuil : 100 USDC de BILL <= 100 000 BILL, soit prix >= 0,001 USDC (x10)
    uint256 public constant MAX_LOT_TOKENS = 10_000_000e18; // plafond de sécurité si le prix s'effondre
    uint256 public constant CLIFF = 45 days;
    uint256 public constant VESTING = 30 days;
    uint256 public constant UPDATE_INTERVAL = 24 hours;
    uint256 public constant MIN_TWAP_WINDOW = 1 hours;

    IERC20 public immutable token;
    IERC20 public immutable usdc;
    IPair public immutable pair;        // paire BILL/USDC (Uniswap V2)
    address public immutable treasury;  // reçoit les USDC
    uint256 public seriesStart; // 0 tant que le prix n'a pas décollé
    address[FREE_LOTS] public freeWallets;

    struct Grant {
        uint128 total;
        uint128 claimed;
        uint64 start;
    }

    struct Obs {
        uint32 t;
        uint256 cum;
    }

    Obs public prev;
    Obs public cur;

    mapping(address => Grant[]) public grants;
    mapping(address => bool) public hasBought;
    uint256 public pioneerSold;
    uint256 public paidSold;
    mapping(uint256 => bool) public freeAllocated;
    uint256 public outstanding;

    event Purchased(address indexed buyer, bool pioneer, uint256 price);
    event SeriesOpened(uint256 time);
    event FreeAllocated(uint256 indexed series);
    event Claimed(address indexed who, uint256 indexed grantId, uint256 amount);
    event OracleUpdated(uint256 time);

    constructor(IERC20 _token, IERC20 _usdc, IPair _pair, address _treasury, address[FREE_LOTS] memory _freeWallets) {
        require(_treasury != address(0), "zero treasury");
        for (uint256 i; i < FREE_LOTS; i++) require(_freeWallets[i] != address(0), "zero wallet");
        token = _token;
        usdc = _usdc;
        pair = _pair;
        treasury = _treasury;
        freeWallets = _freeWallets;
    }

    // ---------- oracle TWAP ----------

    function _currentCumulative() internal view returns (uint256 cum) {
        (uint112 r0, uint112 r1, uint32 ts) = pair.getReserves();
        bool billIs0 = pair.token0() == address(token);
        (uint256 rBill, uint256 rUsdc) = billIs0 ? (r0, r1) : (r1, r0);
        require(rBill > 0 && rUsdc > 0, "no liquidity");
        cum = billIs0 ? pair.price0CumulativeLast() : pair.price1CumulativeLast();
        uint32 now32 = uint32(block.timestamp);
        if (ts != now32) {
            unchecked {
                cum += ((rUsdc << 112) / rBill) * uint32(now32 - ts);
            }
        }
    }

    /// @notice Enregistre un point d'observation (public, au plus toutes les 24 h).
    function update() external {
        require(cur.t == 0 || block.timestamp >= uint256(cur.t) + UPDATE_INTERVAL, "too soon");
        prev = cur;
        cur = Obs(uint32(block.timestamp), _currentCumulative());
        emit OracleUpdated(block.timestamp);
    }

    function _twap() internal view returns (uint256 avg) {
        Obs memory o = cur;
        if (o.t == 0 || block.timestamp < uint256(o.t) + MIN_TWAP_WINDOW) o = prev;
        require(o.t != 0, "no oracle");
        uint256 dt;
        unchecked {
            dt = uint32(block.timestamp) - o.t;
            avg = (_currentCumulative() - o.cum) / dt;
        }
        require(avg > 0, "no price");
    }

    /// @notice Quantité de BILL livrée pour une valeur de marché de 10 USDC (x2 du prix payé).
    /// Le premier lot (pionnier) est fixe ; ensuite la quantité suit le prix : jamais plus que x2.
    function lotTokens() public view returns (uint256 t) {
        t = (LOT_VALUE << 112) / _twap();
        if (t > MAX_LOT_TOKENS) t = MAX_LOT_TOKENS;
    }

    // ---------- séries ----------

    /// @notice Lance les séries continues, une seule fois, dès que le cours TWAP a décollé (x10 du prix de lancement).
    function openSeries() external {
        require(seriesStart == 0, "already open");
        require(lotTokens() <= TRIGGER_LOT_TOKENS, "price too low");
        seriesStart = block.timestamp;
        emit SeriesOpened(block.timestamp);
    }

    /// @notice Séries ouvertes : 0 avant le déclenchement, 1 au déclenchement, puis +1 tous les 30 jours.
    function openedSeries() public view returns (uint256 n) {
        if (seriesStart == 0) return 0;
        n = (block.timestamp - seriesStart) / SERIES_INTERVAL + 1;
        if (n > SERIES_COUNT) n = SERIES_COUNT;
    }

    function availablePaidLots() public view returns (uint256) {
        return openedSeries() * PAID_LOTS - paidSold;
    }

    // ---------- achats ----------

    /// @notice Lot pionnier : 10 USDC pour 100 000 BILL (quantité fixe).
    function buyPioneer() external {
        require(!hasBought[msg.sender], "already bought");
        require(pioneerSold < PIONEER_LOTS, "pioneers sold out");
        hasBought[msg.sender] = true;
        pioneerSold++;
        _sell(PIONEER_PRICE, true, LOT_TOKENS);
    }

    /// @notice Lot de série continue : 50 USDC contre 100 USDC de BILL au cours TWAP (x2).
    function buy() external {
        require(!hasBought[msg.sender], "already bought");
        require(paidSold < SERIES_COUNT * PAID_LOTS, "sold out");
        require(availablePaidLots() > 0, "next series not open");
        hasBought[msg.sender] = true;
        paidSold++;
        _sell(LOT_PRICE, false, lotTokens());
    }

    function _sell(uint256 price, bool pioneer, uint256 tokens) internal {
        _commit(tokens);
        require(usdc.transferFrom(msg.sender, treasury, price), "payment failed");
        grants[msg.sender].push(Grant(uint128(tokens), 0, uint64(block.timestamp)));
        emit Purchased(msg.sender, pioneer, price);
    }

    /// @notice Attribue les 10 lots gratuits d'une série (1..14) aux sous-wallets, une seule fois.
    function allocateFree(uint256 series) external {
        require(series >= 1 && series <= openedSeries(), "series not open");
        require(!freeAllocated[series], "done");
        freeAllocated[series] = true;
        uint256 tokens = lotTokens();
        _commit(tokens * FREE_LOTS);
        for (uint256 i; i < FREE_LOTS; i++) {
            grants[freeWallets[i]].push(Grant(uint128(tokens), 0, uint64(block.timestamp)));
        }
        emit FreeAllocated(series);
    }

    function _commit(uint256 amount) internal {
        outstanding += amount;
        require(token.balanceOf(address(this)) >= outstanding, "pool underfunded");
    }

    // ---------- vesting ----------

    function vested(address who, uint256 id) public view returns (uint256) {
        Grant memory g = grants[who][id];
        uint256 t = block.timestamp;
        if (t < g.start + CLIFF) return 0;
        uint256 elapsed = t - g.start - CLIFF;
        if (elapsed >= VESTING) return g.total;
        return (uint256(g.total) * elapsed) / VESTING;
    }

    function claim(uint256 id) external {
        uint256 amount = vested(msg.sender, id) - grants[msg.sender][id].claimed;
        require(amount > 0, "nothing to claim");
        grants[msg.sender][id].claimed += uint128(amount);
        outstanding -= amount;
        require(token.transfer(msg.sender, amount), "transfer failed");
        emit Claimed(msg.sender, id, amount);
    }

    function grantCount(address who) external view returns (uint256) {
        return grants[who].length;
    }
}
