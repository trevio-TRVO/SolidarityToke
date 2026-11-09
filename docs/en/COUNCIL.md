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
- **Rotation: implemented** (`contracts/CouncilRegistry.sol`). `SolidarityWallet` reads the council from the registry (immutable address). No owner: the rotation is confirmed by a **fixed** (immutable) set of election signers, threshold M of N. Each signer confirms the same exact list of 10 addresses; at the M-th `confirmRotation` call, the list applies. At most one rotation per 30 days (the first one 30 days after deployment), 10 distinct, non-zero addresses, different from the founder. Events: `RotationConfirmed`, `CouncilRotated`.
- **Election signers (validated choice)**: a small group independent of the founder, threshold 3 of 5 (`ELECTION_SIGNERS` / `ELECTION_THRESHOLD` environment variables).
- **Why not a vote by the outgoing council**: a council supermajority could re-elect itself and lock in power. The signers do not sit on the council and only publish the election results.
- **Effects of the rotation**: a removed member loses all voting rights; their approvals and cancellation votes on open requests no longer count (weight recalculated at execution). The founder is never affected.
- **Residual risk**: M colluding signers can impose a council, at most once a month; the set of signers never changes (in case of compromise, a new deployment would be needed). To be mitigated with public multisigs.
- **Off-chain results** (X, Facebook, TikTok, influencer, web vote): an oracle or a committee is needed to publish the result on-chain. This is a trust point that must be framed.
- **Wallet holding the most**: exclude the liquidity pair, contracts (lots, solidarityWallet), the founder and exchange addresses. Risk of artificial rotation between wallets before the close: use the average balance over the month.
- **Top trader**: wash trading risk; compute on net PnL or on volume with a cap.
- **One person, one seat**: the same actor cannot hold several seats; in case of a duplicate, next seat in the ranking.
- **Conflicts of interest**: a member does not vote on their own request nor on that of a relative.
- **Social networks**: identification via a linked account (OAuth); metrics depend on the platforms' APIs.
