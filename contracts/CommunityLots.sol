// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}

/// @title CommunityLots V3 - distribution communautaire par lots (sans admin)
/// @notice Séries de 100 lots : 90 payants (1 achat par wallet), 10 gratuits
///         répartis vers 10 sous-wallets. Chaque lot : cliff 45j puis linéaire 30j.
///         Tous les paramètres sont immuables : aucune fonction owner/admin.
contract CommunityLots {
    uint256 public constant PAID_LOTS = 90;
    uint256 public constant FREE_LOTS = 10;
    uint256 public constant CLIFF = 45 days;
    uint256 public constant VESTING = 30 days;

    IERC20 public immutable token;      // token du projet
    IERC20 public immutable usdc;       // monnaie de paiement
    address public immutable treasury;  // reçoit les USDC

    uint256 public immutable seriesCount;
    uint256[] public pricePerSeries;    // prix USDC (6 déc.) d'un lot, <= x2 de la série précédente
    uint256[] public tokensPerSeries;   // tokens par lot : décroît => rareté
    address[FREE_LOTS] public freeWallets; // 10 sous-wallets du wallet spécial (programme V4)

    struct Grant {
        uint128 total;
        uint128 claimed;
        uint64 start; // début du cliff
    }

    mapping(address => Grant[]) public grants;
    uint256 public outstanding; // tokens attribués non encore réclamés
    mapping(address => bool) public hasBought;
    mapping(uint256 => uint256) public paidSold;      // série => lots payants vendus
    mapping(uint256 => bool) public freeAllocated;    // série => lots gratuits attribués

    event Purchased(address indexed buyer, uint256 indexed series, uint256 price, uint256 tokens);
    event FreeAllocated(uint256 indexed series, uint256 tokensPerLot);
    event Claimed(address indexed who, uint256 indexed grantId, uint256 amount);

    constructor(
        IERC20 _token,
        IERC20 _usdc,
        address _treasury,
        uint256[] memory _prices,
        uint256[] memory _tokens,
        address[FREE_LOTS] memory _freeWallets
    ) {
        require(_prices.length > 0 && _prices.length == _tokens.length, "bad schedule");
        for (uint256 i; i < _prices.length; i++) {
            require(_prices[i] > 0 && _tokens[i] > 0, "zero");
            if (i > 0) {
                require(_prices[i] <= _prices[i - 1] * 2, "price > x2");
                require(_prices[i] >= _prices[i - 1], "price decreasing");
                require(_tokens[i] <= _tokens[i - 1], "quantity must not grow");
            }
        }
        for (uint256 i; i < FREE_LOTS; i++) require(_freeWallets[i] != address(0), "zero wallet");
        require(_treasury != address(0), "zero treasury");
        token = _token;
        usdc = _usdc;
        treasury = _treasury;
        pricePerSeries = _prices;
        tokensPerSeries = _tokens;
        seriesCount = _prices.length;
        freeWallets = _freeWallets;
    }

    /// @notice Série active = première non épuisée (lots payants).
    function currentSeries() public view returns (uint256) {
        uint256 s;
        while (s < seriesCount && paidSold[s] >= PAID_LOTS) s++;
        return s;
    }

    /// @notice Achat d'un lot : un seul par wallet, vesting démarre à l'achat.
    function buy() external {
        require(!hasBought[msg.sender], "already bought");
        uint256 s = currentSeries();
        require(s < seriesCount, "sold out");
        hasBought[msg.sender] = true;
        paidSold[s]++;
        uint256 tokens = tokensPerSeries[s];
        uint256 price = pricePerSeries[s];

        _commit(tokens);
        require(usdc.transferFrom(msg.sender, treasury, price), "payment failed");
        grants[msg.sender].push(Grant(uint128(tokens), 0, uint64(block.timestamp)));
        emit Purchased(msg.sender, s, price, tokens);
    }

    /// @notice Attribue les 10 lots gratuits d'une série aux sous-wallets (permissionless, une fois).
    ///         Possible dès que la série est ouverte (atteinte ou dépassée).
    function allocateFree(uint256 s) external {
        require(s < seriesCount && s <= currentSeries(), "series not open");
        require(!freeAllocated[s], "done");
        freeAllocated[s] = true;
        uint256 tokens = tokensPerSeries[s];
        _commit(tokens * FREE_LOTS);
        for (uint256 i; i < FREE_LOTS; i++) {
            grants[freeWallets[i]].push(Grant(uint128(tokens), 0, uint64(block.timestamp)));
        }
        emit FreeAllocated(s, tokens);
    }

    function _commit(uint256 amount) internal {
        outstanding += amount;
        require(token.balanceOf(address(this)) >= outstanding, "pool underfunded");
    }

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
