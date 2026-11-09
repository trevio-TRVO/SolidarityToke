// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title BillPayProtocol (BILL)
/// @notice ERC-20 à offre plafonnée, frappée une seule fois. Aucun owner, aucun mint, aucune pause,
///         aucune fonction modifiable après déploiement (même modèle que le V2 TrvoToken).
///
/// Contribution solidaire : 10 % prélevés UNIQUEMENT lors d'un trade avec une paire de liquidité
/// (achat ou vente). Les transferts P2P ne sont pas concernés.
///   5 % aide directe  -> solidarityWallet
///   2 % raréfaction   -> détruits définitivement
///   2 % opérationnel  -> operationsWallet
///   1 % auto-liquidité-> liquidityReserve
/// Protection de lancement (7 premiers jours) : vente max 0,1 % de l'offre par transaction et 0,2 %
/// par wallet et par 24 h. Ensuite : 1 % par transaction et 1 % par wallet et par 24 h.
/// Ces limites ne visent que les ventes vers une paire ; les achats et le P2P sont libres.
contract BillPayProtocol is ERC20 {
    uint256 public constant CONTRIBUTION_BPS = 1000; // 10 %
    uint256 public constant AID_BPS = 500;
    uint256 public constant BURN_BPS = 200;
    uint256 public constant OPS_BPS = 200;
    uint256 public constant LIQUIDITY_BPS = 100;
    uint256 public constant LAUNCH_PERIOD = 7 days;
    uint256 public constant LAUNCH_TX_BPS = 10; // 0,1 % par vente pendant le lancement
    uint256 public constant LAUNCH_DAILY_BPS = 20; // 0,2 % par wallet et par 24 h pendant le lancement
    uint256 public constant MAX_SELL_BPS = 100; // 1 % par vente après le lancement
    uint256 public constant DAILY_SELL_BPS = 100; // 1 % par wallet et par 24 h après le lancement
    uint256 public constant BPS = 10_000;

    address public immutable solidarityWallet;
    address public immutable operationsWallet;
    address public immutable liquidityReserve;
    uint256 public immutable launchEnd;

    struct SellWindow {
        uint64 start;
        uint192 sold;
    }
    mapping(address => SellWindow) public sellWindow;

    mapping(address => bool) public isPair;
    // Adresses exemptées (ajout de liquidité initial, contrats du protocole). Figées au déploiement.
    mapping(address => bool) public isExempt;

    event Contribution(address indexed trader, uint256 aid, uint256 burned, uint256 ops, uint256 liquidity);

    constructor(
        uint256 totalSupply_,
        address[] memory recipients,
        uint256[] memory amounts,
        address _solidarityWallet,
        address _operationsWallet,
        address _liquidityReserve,
        address[] memory pairs,
        address[] memory exempt
    ) ERC20("BillPay Protocol", "BILL") {
        require(totalSupply_ > 0, "supply=0");
        require(recipients.length == amounts.length && recipients.length > 0, "bad allocation");
        require(
            _solidarityWallet != address(0) && _operationsWallet != address(0) && _liquidityReserve != address(0),
            "zero address"
        );
        solidarityWallet = _solidarityWallet;
        operationsWallet = _operationsWallet;
        liquidityReserve = _liquidityReserve;
        launchEnd = block.timestamp + LAUNCH_PERIOD;

        for (uint256 i; i < pairs.length; i++) {
            require(pairs[i] != address(0), "pair=0");
            isPair[pairs[i]] = true;
        }
        for (uint256 i; i < exempt.length; i++) {
            isExempt[exempt[i]] = true;
        }
        isExempt[_solidarityWallet] = true;
        isExempt[_operationsWallet] = true;
        isExempt[_liquidityReserve] = true;

        uint256 sum;
        for (uint256 i; i < recipients.length; i++) {
            require(recipients[i] != address(0), "recipient=0");
            sum += amounts[i];
            _mint(recipients[i], amounts[i]);
        }
        require(sum == totalSupply_, "allocation != supply");
    }

    function _checkSell(address seller, uint256 amount) internal {
        bool launch = block.timestamp < launchEnd;
        uint256 supply = totalSupply();
        require(amount <= (supply * (launch ? LAUNCH_TX_BPS : MAX_SELL_BPS)) / BPS, "sell limit per tx");

        SellWindow memory w = sellWindow[seller];
        if (block.timestamp >= uint256(w.start) + 1 days) {
            w.start = uint64(block.timestamp);
            w.sold = 0;
        }
        uint256 sold = uint256(w.sold) + amount;
        require(sold <= (supply * (launch ? LAUNCH_DAILY_BPS : DAILY_SELL_BPS)) / BPS, "sell limit per day");
        w.sold = uint192(sold);
        sellWindow[seller] = w;
    }

    function _update(address from, address to, uint256 amount) internal override {
        bool isTrade = (isPair[from] || isPair[to]) && from != address(0) && to != address(0);
        if (!isTrade || isExempt[from] || isExempt[to]) {
            super._update(from, to, amount);
            return;
        }

        if (isPair[to]) _checkSell(from, amount);

        uint256 aid = (amount * AID_BPS) / BPS;
        uint256 burn_ = (amount * BURN_BPS) / BPS;
        uint256 ops = (amount * OPS_BPS) / BPS;
        uint256 liq = (amount * LIQUIDITY_BPS) / BPS;
        uint256 fee = aid + burn_ + ops + liq;

        super._update(from, to, amount - fee);
        super._update(from, solidarityWallet, aid);
        super._update(from, address(0), burn_);
        super._update(from, operationsWallet, ops);
        super._update(from, liquidityReserve, liq);
        emit Contribution(isPair[from] ? to : from, aid, burn_, ops, liq);
    }
}
