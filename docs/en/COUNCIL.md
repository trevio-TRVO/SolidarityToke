# Solidarity Council: composition (10 seats + founder)

**Monthly** term. The founder keeps a weight of 3; the council has 10 seats of weight 1; validation threshold: 5.

| # | Seat | Designation |
|---|---|---|
| 1-3 | 3 pioneer members | Chosen each month (method to be defined: random draw among lot buyers) |
| 4 | Top influencer | Vote on the platform |
| 5 | Top X contributor | Ranking of the month (verified engagement) |
| 6 | Top Facebook contributor | Same |
| 7 | Top TikTok contributor | Same |
| 8 | Top trader of the month | On-chain ranking (net volume, excluding wash trading) |
| 9 | Wallet holding the most BILL | On-chain reading at month end |
| 10 | Elected seat | Vote on the website |

## Points to settle
- **The current contract freezes the council** (immutable). A monthly rotation requires a new version of `SolidarityWallet`: update of the 10 seats once a month, through a mechanism without a single key (e.g. a `CouncilRegistry` contract fed by the results).
- **Off-chain results** (X, Facebook, TikTok, influencer, web vote): an oracle or a committee is needed to publish the result on-chain. This is a trust point that must be framed.
- **Wallet holding the most**: exclude the liquidity pair, contracts (lots, solidarityWallet), the founder and exchange addresses. Risk of artificial rotation between wallets before the close: use the average balance over the month.
- **Top trader**: wash trading risk; compute on net PnL or on volume with a cap.
- **One person, one seat**: the same actor cannot hold several seats; in case of a duplicate, next seat in the ranking.
- **Conflicts of interest**: a member does not vote on their own request nor on that of a relative.
- **Social networks**: identification via a linked account (OAuth); metrics depend on the platforms' APIs.
