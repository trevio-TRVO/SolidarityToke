# V3: community distribution (15% of the supply = 150,000,000 BILL)

Contract: `contracts/CommunityLots.sol` (no owner, immutable parameters).

## Structure: 1,500 lots of 100,000 BILL
| Phase | Lots | Rule |
|---|---|---|
| Pioneers (1%) | 100 | Price 10 USDC per lot, fixed quantity of 100,000 BILL (value 10 USDC at the launch price 0.0001 USDC/BILL). Open from launch. |
| Continuous series | 14 series of 100 | 90 paid + 10 free. They open when the price takes off (see below), then a new series every 30 days, until the reserve is exhausted (14 series maximum). |

Total: (100 + 14 × 100) × 100,000 = 150,000,000 BILL.

## Series launch
- At launch, **only the 100 pioneer lots** are on sale.
- The 50 USDC series start only once the TWAP price has taken off: `openSeries()` (public, once only) requires a price >= 0.001 USDC/BILL (x10 the launch price), i.e. a 100 USDC lot <= 100,000 BILL. Series 1 at trigger, then one series every 30 days. This threshold guarantees that 1,400 lots fit in the 140 M BILL reserve.
- Before the trigger, no purchases and no free lots.

## Price and quantity
- Pioneer lot: **fixed** (100,000 BILL for 10 USDC).
- Following lots: **50 USDC** for **100 USDC of BILL at the TWAP price** (x2, never more). Example: BILL at 1 USDC, 50 USDC paid = 100 BILL. The quantity varies with the price: the higher BILL goes, the fewer tokens a lot contains (scarcity). Safety cap: 10,000,000 BILL per lot. If the reserve is no longer sufficient, purchases are refused.
- Unsold lots remain in the contract (no burn, no outflow).
- TWAP oracle (BILL/USDC pair): public `update()` (at most every 24 h), minimum window of 1 h. Call `update()` after adding liquidity, then wait 1 h.
- One lot per wallet.

## Free lots
- 10 lots per series (same quantity as the paid lots, 100 USDC of value) go to the 10 sub-wallets of the special wallet (participation program, managed by V4: campaign, 3 administrators drawn at random per lot). `allocateFree(series)` is public and can only be called once per series.

## Vesting per lot
- 45-day cliff from the purchase, then linear unlocking over 30 days. No early claim.

## Safeguards
- Capped pool: the contract must be pre-funded with 150,000,000 BILL; `outstanding <= balance` is checked at every allocation.
- Purchases are only possible if a TWAP observation exists.
