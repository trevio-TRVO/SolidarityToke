# Policy Decisions (Final)

- Public sale uses a fixed deterministic price equal to 10,000 USDC divided by 4,200,000 TRVO, implemented with integer math.
- Any unsold sale allocation is automatically transferred to the Treasury VestingWallet at finalization.
- Initial liquidity targets 2,100,000 TRVO paired with 5,000 USDC; LP tokens are locked for 24 months in a public, irrevocable locker.
- Team/Treasury/Rewards vesting is enforced through OpenZeppelin VestingWallet contracts with continuous linear release.
- No owner privileges exist to override these rules after deployment.

## Communication rules

- No promise of returns. No wording such as "guaranteed" or "assured profit".
- Jurisdictional restrictions and KYC/AML policy are published before the sale.
- The per-wallet cap is a weak anti-concentration signal (bypassable with multiple wallets). It is not an AML control.
- This repository does not constitute legal advice. Legal review is required before any public sale.
