# V3 deployment: BillPayProtocol (BILL)

Basis: follows V2 (`v2/`, TrvoToken): fixed supply minted in the constructor, no owner, no mint, no pause.

## Contracts
1. `BillPayProtocol`: token. 10% contribution on trades only (5% aid, 2% burn, 2% operations, 1% auto-liquidity), 1% of supply sell limit towards a pair.
2. `SolidarityWallet`: receives the 5%, pays validated bills (council + 5 lot buyers).
3. `CommunityLots`: 15% in 1,500 lots (see `V3_COMMUNITY_DISTRIBUTION.md`).
5. `MonthlyVesting`: 15% growth, 1/48 per 30-day period.
4. `AutoLiquidity`: receives the 1% and adds it to liquidity (LP locked at the dead address), public call, once per 24 h.

## Allocation (1,000,000,000 BILL, fixed supply)
| Share | % | Destination | Vesting |
|---|---|---|---|
| Initial liquidity | 50 | `LIQUIDITY_SEEDER` (exempt from the contribution to add liquidity) | LP to be locked in a public locker (24 months like V2) |
| Founder | 20 | OpenZeppelin `VestingWallet` | start +90 days, then 36 linear months (validated by the founder; V2 planned 12 months + 48 months) |
| Community reserve (incl. 1% pioneers) | 15 | `CommunityLots` | 45 d cliff + 30 d linear per lot |
| Growth and marketing | 15 | `MonthlyVesting` | 48 months, 1/48 per month (validated) |

## Deployment
`script/DeployV3.s.sol` deploys in a single pass, in order: founder VestingWallet, `MonthlyVesting`, `SolidarityWallet`, `CommunityLots`, `AutoLiquidity`, `BillPayProtocol`. `ROUTER` variable: official Uniswap V2 router on Base, to be verified. The pair is **BILL/USDC** (not ETH): the lot price is thus computed directly in USDC. These contracts reference each other: the addresses are predicted by nonce and verified (`require`). The script was run in local simulation without errors.

`forge script script/DeployV3.s.sol --rpc-url base_sepolia --account <keystore> --broadcast`

Then: add the liquidity (500,000 BILL + **50 USDC** at the launch price 0.0001 USDC/BILL; the remaining 499,500,000 BILL are deposited in `AutoLiquidity` and injected gradually, paired with the USDC coming from the sale of the 1% contribution), lock the LP, call `CommunityLots.update()`, verify the contracts on Basescan.

## Known deviations from the specification
- **Launch protection (7 days)**: sales to a pair limited to 0.1% of supply per transaction (1,000,000 BILL) and 0.2% per wallet per 24 h. Afterwards: 1% per transaction and 1% per wallet per 24 h. Purchases and P2P are not limited; the initial liquidity addition is exempt. Known limitation: a holder can spread their tokens over several wallets to multiply the limit (P2P is free). It slows a massive sale without fully preventing it.
- **1% auto-liquidity**: `AutoLiquidity` (separate contract, no owner, BILL/USDC pair). Each call uses at most 0.2% of the pair's reserve, 5% slippage tolerance, LP sent to the dead address. Perfect sandwich protection does not exist without a price oracle: the capped amounts limit the risk.
- **Pairs**: only Uniswap V2-type pairs (or equivalents) are handled. A sale through a V3/V4 pool escapes the contribution and the limit: deploy only on a V2 pool.
- **Pair address**: it depends on the token address (predicted by the script); to be computed with the official factory (addresses and init code hash to be verified in Base's official documentation).
- **Vesting**: founder (90 d + 36 months) and growth (48 monthly periods) validated.
- **Launch value**: 0.0001 USDC/BILL (total diluted value of 100,000 USDC) follows from the pioneer lots and the liquidity of 500,000 BILL + 50 USDC. To be confirmed.
- **TWAP**: 1 h minimum window, manipulable at high but non-zero cost; no external oracle (Chainlink) exists for BILL.

## Founder compensation
The founder's 20% is locked: 90 days with no unlocking, then 36 linear months (about 5.5 M BILL per month), sellable within the limits above. During the first 90 days, no unlocking of this lot: compensation must come from the operations budget (2% of each trade, `operationsWallet`) or from the growth fund, under public rules. The founder is exempt from no limit, which also protects holders' trust.
- **Gas**: the contribution is collected by transfers to 4 recipients, hence more expensive than a simple ERC-20.

## Before mainnet
Internal review, Slither, independent audit, full trial on Base Sepolia, legal review, no promise of returns (see the V2 policy).

## Dependencies
`forge install OpenZeppelin/openzeppelin-contracts@v5.0.2 foundry-rs/forge-std --no-git` (the `lib/` folder is not versioned).
