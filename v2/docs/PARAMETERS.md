# Parameters

## Frozen (decided)

| Name | Value |
|---|---|
| SOFT_CAP | 5_000e6 USDC |
| HARD_CAP | 10_000e6 USDC |
| TOKENS_FOR_SALE | 4_200_000e18 TRVO |
| TOKENS_FOR_LIQUIDITY | 2_100_000e18 TRVO |
| USDC_FOR_LIQUIDITY | 5_000e6 USDC |
| TGE_UNLOCK_BPS | 2500 |
| VESTING_DURATION_BUYERS | 180 days |
| MAX_PER_WALLET | 500e6 USDC (proposed) |
| Price | 420 TRVO per USDC; tokens = usdcAmount * 420e12 |
| Team vesting | start = TGE + 12 months, duration 48 months, linear |
| Treasury vesting | start = TGE, duration 60 months, linear |
| Rewards vesting | start = TGE, duration 60 months, linear |

## Pending confirmation (do not code until confirmed)

- Total supply and team/rewards split (working hypothesis: 21,000,000 TRVO; 20/10/30/20/20)
- Treasury multisig address (surplus funds recipient)
- Sale start/end timestamps
- DEX, router/factory and LP locker: official addresses on Base MUST be verified against official docs before being hardcoded
- Buyer vesting split (25% at TGE, 75% linear over 180 days) and its implementation (custom, since plain VestingWallet has no TGE tranche)
- Slither policy (currently: fail on high severity)
