// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {MonthlyVesting} from "../contracts/MonthlyVesting.sol";
import {VestingWallet} from "@openzeppelin/contracts/finance/VestingWallet.sol";
import {BillPayProtocol} from "../contracts/BillPayProtocol.sol";
import {CommunityLots, IERC20, IPair} from "../contracts/CommunityLots.sol";
import {AutoLiquidity, IERC20AL, IRouterV2, IPairV2} from "../contracts/AutoLiquidity.sol";
import {CouncilRegistry} from "../contracts/CouncilRegistry.sol";
import {SolidarityWallet, IERC20Min, ICommunityLots, ICouncilRegistry} from "../contracts/SolidarityWallet.sol";

/// Répartition de 1 000 000 000 BILL :
///   50 % liquidité initiale BILL/USDC (LIQUIDITY_SEEDER) · 20 % fondateur (VestingWallet)
///   15 % CommunityLots (dont 1 % pionniers) · 15 % croissance et marketing (MonthlyVesting, 48 mois)
/// Les adresses des contrats sont prédites par nonce car elles se référencent mutuellement.
/// Variables : FOUNDER, LIQUIDITY_SEEDER, OPERATIONS_WALLET, GROWTH_BENEFICIARY, PAIR,
/// USDC, TREASURY, ROUTER, COUNCIL (les 10 sièges initiaux, virgules), FREE_WALLETS (10 adresses),
/// ELECTION_SIGNERS (signataires d'élection fixes, virgules), ELECTION_THRESHOLD (seuil M).
/// La clé privée se passe via --account / --ledger, jamais dans un fichier.
contract DeployV3 is Script {
    uint256 public constant SUPPLY = 1_000_000_000e18;
    uint256 public constant FOUNDER_CLIFF = 90 days; // validé : revenu rapide, V2 = 12 mois
    uint256 public constant FOUNDER_DURATION = 3 * 365 days; // V2 = 48 mois
    uint256 public constant GROWTH_MONTHS = 48; // déblocage par paliers mensuels

    struct Deployed {
        address founderVesting;
        address growthVesting;
        address registry;
        address solidarity;
        address lots;
        address autoLiquidity;
        address token;
    }

    function run() external returns (Deployed memory d) {
        address deployer = msg.sender;
        uint256 n = vm.getNonce(deployer);
        address predictedToken = vm.computeCreateAddress(deployer, n + 6);
        address predictedLots = vm.computeCreateAddress(deployer, n + 4);
        address predictedAutoLiq = vm.computeCreateAddress(deployer, n + 5);
        address predictedSolidarity = vm.computeCreateAddress(deployer, n + 3);
        address predictedRegistry = vm.computeCreateAddress(deployer, n + 2);

        vm.startBroadcast();
        d.founderVesting = address(
            new VestingWallet(vm.envAddress("FOUNDER"), uint64(block.timestamp + FOUNDER_CLIFF), uint64(FOUNDER_DURATION))
        );
        d.growthVesting = address(
            new MonthlyVesting(vm.envAddress("GROWTH_BENEFICIARY"), block.timestamp, GROWTH_MONTHS)
        );

        d.registry = address(
            new CouncilRegistry(
                vm.envAddress("FOUNDER"),
                _toTen(vm.envAddress("COUNCIL", ",")),
                vm.envAddress("ELECTION_SIGNERS", ","),
                vm.envUint("ELECTION_THRESHOLD")
            )
        );
        require(d.registry == predictedRegistry, "nonce: registry");

        d.solidarity = address(
            new SolidarityWallet(
                IERC20Min(predictedToken),
                ICommunityLots(predictedLots),
                vm.envAddress("FOUNDER"),
                ICouncilRegistry(d.registry)
            )
        );
        require(d.solidarity == predictedSolidarity, "nonce: solidarity");

        d.lots = address(
            new CommunityLots(
                IERC20(predictedToken),
                IERC20(vm.envAddress("USDC")),
                IPair(vm.envAddress("PAIR")),
                vm.envAddress("TREASURY"),
                _toTen(vm.envAddress("FREE_WALLETS", ","))
            )
        );
        require(d.lots == predictedLots, "nonce: lots");

        d.autoLiquidity = address(
            new AutoLiquidity(
                IERC20AL(predictedToken),
                IERC20AL(vm.envAddress("USDC")),
                IRouterV2(vm.envAddress("ROUTER")),
                IPairV2(vm.envAddress("PAIR"))
            )
        );
        require(d.autoLiquidity == predictedAutoLiq, "nonce: autoLiquidity");

        d.token = _deployToken(d);
        require(d.token == predictedToken, "nonce: token");
        vm.stopBroadcast();

        console2.log("BillPayProtocol", d.token);
        console2.log("CommunityLots", d.lots);
        console2.log("AutoLiquidity", d.autoLiquidity);
        console2.log("CouncilRegistry", d.registry);
        console2.log("SolidarityWallet", d.solidarity);
        console2.log("FounderVesting", d.founderVesting);
        console2.log("GrowthVesting", d.growthVesting);
    }

    function _deployToken(Deployed memory d) internal returns (address) {
        address seeder = vm.envAddress("LIQUIDITY_SEEDER");
        address[] memory r = new address[](5);
        uint256[] memory a = new uint256[](5);
        // 50 % = 500 000 BILL injectés au lancement (face à 50 USDC) + 499 500 000 BILL en réserve AutoLiquidity
        r[4] = d.autoLiquidity;   a[4] = 499_500_000e18;
        r[0] = seeder;            a[0] = SUPPLY * 50 / 100 - a[4];
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
