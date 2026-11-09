// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {VestingWallet} from "@openzeppelin/contracts/finance/VestingWallet.sol";
import {TrvoToken} from "../src/TrvoToken.sol";
import {TokenSale} from "../src/TokenSale.sol";

/// @notice Deploys TRVO, the vesting wallets and the sale on Base Sepolia (84532) or Base (8453).
/// All inputs come from environment variables. No private key is read here:
/// sign with `--account <keystore>` or `--ledger` on the forge command line.
///
/// ASSUMPTIONS TO VALIDATE BEFORE MAINNET:
/// - Vesting anchor ("TGE") for Team/Treasury/Rewards is SALE_END, because OZ VestingWallet
///   fixes `start` at construction. Buyers' TGE is the finalize() time (>= SALE_END).
/// - Months are approximated: 12 months = 365 days, 48 months = 4 * 365 days,
///   60 months = 5 * 365 days. OZ VestingWallet releases continuously, not monthly.
/// - OZ VestingWallet is Ownable: the beneficiary can transfer ownership of the wallet.
///   Beneficiaries must be multisigs.
contract Deploy is Script {
    uint256 internal constant SUPPLY = 21_000_000e18;
    uint256 internal constant SALE_ALLOC = 4_200_000e18;
    uint256 internal constant LIQUIDITY_ALLOC = 2_100_000e18;
    uint256 internal constant TEAM_ALLOC = 4_200_000e18;
    uint256 internal constant TREASURY_ALLOC = 6_300_000e18;
    uint256 internal constant REWARDS_ALLOC = 4_200_000e18;

    function run() external {
        require(block.chainid == 84532 || block.chainid == 8453, "unsupported chain");

        address usdc = vm.envAddress("USDC_ADDRESS");
        address teamBeneficiary = vm.envAddress("TEAM_BENEFICIARY");
        address treasuryBeneficiary = vm.envAddress("TREASURY_BENEFICIARY");
        address rewardsBeneficiary = vm.envAddress("REWARDS_BENEFICIARY");
        address fundsRecipient = vm.envAddress("TREASURY_MULTISIG");
        address liquidityReceiver = vm.envAddress("LIQUIDITY_RECEIVER");
        uint64 saleStart = uint64(vm.envUint("SALE_START"));
        uint64 saleEnd = uint64(vm.envUint("SALE_END"));

        vm.startBroadcast();
        (, address deployer,) = vm.readCallers();

        VestingWallet team =
            new VestingWallet(teamBeneficiary, saleEnd + uint64(365 days), uint64(4 * 365 days));
        VestingWallet treasury =
            new VestingWallet(treasuryBeneficiary, saleEnd, uint64(5 * 365 days));
        VestingWallet rewards = new VestingWallet(rewardsBeneficiary, saleEnd, uint64(5 * 365 days));

        TrvoToken trvo = new TrvoToken(deployer, SUPPLY);
        TokenSale sale = new TokenSale(
            IERC20(usdc),
            IERC20(address(trvo)),
            address(treasury),
            fundsRecipient,
            liquidityReceiver,
            saleStart,
            saleEnd
        );

        // Entire supply is distributed here. The deployer keeps nothing.
        trvo.transfer(address(sale), SALE_ALLOC);
        trvo.transfer(liquidityReceiver, LIQUIDITY_ALLOC);
        trvo.transfer(address(team), TEAM_ALLOC);
        trvo.transfer(address(treasury), TREASURY_ALLOC);
        trvo.transfer(address(rewards), REWARDS_ALLOC);
        require(trvo.balanceOf(deployer) == 0, "supply not fully distributed");

        vm.stopBroadcast();

        console2.log("chainId", block.chainid);
        console2.log("TrvoToken", address(trvo));
        console2.log("TokenSale", address(sale));
        console2.log("TeamVesting", address(team));
        console2.log("TreasuryVesting", address(treasury));
        console2.log("RewardsVesting", address(rewards));
    }
}
