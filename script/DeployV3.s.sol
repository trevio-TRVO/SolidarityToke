// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {BillPayProtocol} from "../contracts/BillPayProtocol.sol";

/// Variables d'environnement : SUPPLY, COMMUNITY_POOL (15 %), LIQUIDITY_SEEDER, REST_RECIPIENT,
/// SOLIDARITY_WALLET, OPERATIONS_WALLET, LIQUIDITY_RESERVE, PAIR (peut être vide avant création).
/// La clé privée est passée par --account / --ledger, jamais écrite dans un fichier.
contract DeployV3 is Script {
    function run() external returns (BillPayProtocol token) {
        uint256 supply = vm.envUint("SUPPLY");
        address[] memory r = new address[](3);
        uint256[] memory a = new uint256[](3);
        r[0] = vm.envAddress("COMMUNITY_POOL");   a[0] = supply * 15 / 100;
        r[1] = vm.envAddress("LIQUIDITY_SEEDER"); a[1] = supply * 10 / 100;
        r[2] = vm.envAddress("REST_RECIPIENT");   a[2] = supply - a[0] - a[1];

        address[] memory pairs = new address[](1);
        pairs[0] = vm.envAddress("PAIR");
        address[] memory exempt = new address[](2);
        exempt[0] = r[1];
        exempt[1] = r[0];

        vm.startBroadcast();
        token = new BillPayProtocol(
            supply,
            r,
            a,
            vm.envAddress("SOLIDARITY_WALLET"),
            vm.envAddress("OPERATIONS_WALLET"),
            vm.envAddress("LIQUIDITY_RESERVE"),
            pairs,
            exempt
        );
        vm.stopBroadcast();
        console2.log("BillPayProtocol", address(token));
    }
}
