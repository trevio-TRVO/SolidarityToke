# Open questions

## Validated decisions (2026-11-09)
- The founder funds the 50 USDC of initial liquidity personally (with 500,000 BILL).
- Their remuneration comes from the 2% "management and marketing" contribution (`operationsWallet`), with no special treatment on the token; their 20% remains subject to vesting and sell limits.
- Free lots contain the same quantity of BILL as the 90 paid lots of the series (market value of 100 USDC at the TWAP price).

- Series trigger threshold: x10 the launch price (0.001 USDC/BILL), validated on 2026-11-09.
- Anti-sybil: 1 purchase per wallet can be bypassed with multiple wallets (see issue #4).
- V4 program: allocation of free lots (campaign, 3 administrators drawn at random).
- Verify the official Uniswap V2 addresses on Base (router, pair) before deployment.
- TWAP oracle manipulable at high but non-zero cost; minimum window of 1 h.
- Tests on Base Sepolia, Slither analysis, external audit and legal review before mainnet.
