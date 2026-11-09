// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {VestingWallet} from "@openzeppelin/contracts/finance/VestingWallet.sol";
import {BillPayProtocol} from "../contracts/BillPayProtocol.sol";
import {CommunityLots, IERC20} from "../contracts/CommunityLots.sol";
import {AutoLiquidity, IERC20AL, IRouterV2, IPairV2} from "../contracts/AutoLiquidity.sol";
import {SolidarityWallet, IERC20Min, ICommunityLots} from "../contracts/SolidarityWallet.sol";

/// Répartition de 1 000 000 000 BILL :
///   50 % liquidité initiale (LIQUIDITY_SEEDER) · 20 % fondateur (VestingWallet)
///   15 % CommunityLots · 15 % croissance et marketing (VestingWallet)
/// Les adresses des contrats sont prédites par nonce car elles se référencent mutuellement.
/// Variables : FOUNDER, LIQUIDITY_SEEDER, OPERATIONS_WALLET, ROUTER, GROWTH_BENEFICIARY, PAIR,
/// USDC, TREASURY, COUNCIL (10 adresses, virgules), FREE_WALLETS (10 adresses), PRICES, TOKENS_PER_LOT (listes).
/// La clé privée se passe via --account / --ledger, jamais dans un fichier.
contract DeployV3 is Script {
    uint256 public constant SUPPLY = 1_000_000_000e18;
    uint256 public constant FOUNDER_CLIFF = 90 days; // validé : revenu rapide, V2 = 12 mois
    uint256 public constant FOUNDER_DURATION = 3 * 365 days; // V2 = 48 mois
    uint256 public constant GROWTH_DURATION = 5 * 365 days; // même modèle que la trésorerie du V2

    struct Deployed {
        address founderVesting;
        address growthVesting;
        address solidarity;
        address lots;
        address autoLiquidity;
        address token;
    }

    function run() external returns (Deployed memory d) {
        address deployer = msg.sender;
        uint256 n = vm.getNonce(deployer);
        address predictedToken = vm.computeCreateAddress(deployer, n + 5);
        address predictedLots = vm.computeCreateAddress(deployer, n + 3);
        address predictedAutoLiq = vm.computeCreateAddress(deployer, n + 4);
        address predictedSolidarity = vm.computeCreateAddress(deployer, n + 2);

        vm.startBroadcast();
        d.founderVesting = address(
            new VestingWallet(vm.envAddress("FOUNDER"), uint64(block.timestamp + FOUNDER_CLIFF), uint64(FOUNDER_DURATION))
        );
        d.growthVesting = address(
            new VestingWallet(vm.envAddress("GROWTH_BENEFICIARY"), uint64(block.timestamp), uint64(GROWTH_DURATION))
        );

        address[10] memory council = _toTen(vm.envAddress("COUNCIL", ","));
        d.solidarity = address(
            new SolidarityWallet(
                IERC20Min(predictedToken), ICommunityLots(predictedLots), vm.envAddress("FOUNDER"), council
            )
        );
        require(d.solidarity == predictedSolidarity, "nonce: solidarity");

        d.lots = address(
            new CommunityLots(
                IERC20(predictedToken),
                IERC20(vm.envAddress("USDC")),
                vm.envAddress("TREASURY"),
                vm.envUint("PRICES", ","),
                vm.envUint("TOKENS_PER_LOT", ","),
                _toTen(vm.envAddress("FREE_WALLETS", ","))
            )
        );
        require(d.lots == predictedLots, "nonce: lots");

        d.autoLiquidity = address(
            new AutoLiquidity(
                IERC20AL(predictedToken), IRouterV2(vm.envAddress("ROUTER")), IPairV2(vm.envAddress("PAIR"))
            )
        );
        require(d.autoLiquidity == predictedAutoLiq, "nonce: autoLiquidity");

        d.token = _deployToken(d);
        require(d.token == predictedToken, "nonce: token");
        vm.stopBroadcast();

        console2.log("BillPayProtocol", d.token);
        console2.log("CommunityLots", d.lots);
        console2.log("AutoLiquidity", d.autoLiquidity);
        console2.log("SolidarityWallet", d.solidarity);
        console2.log("FounderVesting", d.founderVesting);
        console2.log("GrowthVesting", d.growthVesting);
    }

    function _deployToken(Deployed memory d) internal returns (address) {
        address seeder = vm.envAddress("LIQUIDITY_SEEDER");
        address[] memory r = new address[](4);
        uint256[] memory a = new uint256[](4);
        r[0] = seeder;            a[0] = SUPPLY * 50 / 100;
        r[1] = d.founderVesting;  a[1] = SUPPLY * 20 / 100;
        r[2] = d.lots;            a[2] = SUPPLY * 15 / 100;
        r[3] = d.growthVesting;   a[3] = SUPPLY * 15 / 100;

        address[] memory pairs = new address[](1);
        pairs[0] = vm.envAddress("PAIR");
        address[] memory exempt = new address[](1);
        exempt[0] = seeder;

        return address(
            new BillPayProtocol(
                SUPPLY, r, a, d.solidarity, vm.envAddress("OPERATIONS_WALLET"), d.autoLiquidity, pairs, exempt
            )
        );
    }

    function _toTen(address[] memory a) internal pure returns (address[10] memory out) {
        require(a.length == 10, "need 10 addresses");
        for (uint256 i; i < 10; i++) out[i] = a[i];
    }
}
