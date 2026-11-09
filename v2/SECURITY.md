# Security notes (preliminary self-review, NOT an audit)

Author's own review. An independent audit is required before mainnet. Build, tests, coverage and Slither have not been run by the author of these files; results will come from CI.

| ID | Severity | Finding | Fix |
|---|---|---|---|
| F1 | High (policy) | Liquidity is not provisioned on-chain; the 24-month LP lock is not enforced by code. | Provisioner contract with verified DEX/locker addresses. |
| F2 | Medium | Sale is funded after construction. If soft cap is met but the sale holds fewer than TOKENS_FOR_SALE, finalize() reverts and refunds are unavailable: funds locked. | Fund atomically or add a refund fallback after a grace period. |
| F3 | Medium | USDC issuer can blacklist addresses; a blacklisted recipient makes finalize() revert, a blacklisted buyer cannot be refunded. | Pull-based payouts, non-blacklistable recipients. |
| F4 | Medium | Team/Treasury/Rewards vesting starts at SALE_END, buyers at finalize(); they vest even if the sale fails. | Define failed-sale policy. |
| F5 | Low | OZ VestingWallet is Ownable; beneficiary can transfer ownership. | Multisig beneficiaries. |
| F6 | Low | Hard-cap dust: a buy above remaining capacity reverts. | Partial fill or accept. |
| F7 | Info | Timestamp dependence is seconds-level. | None. |
| F8 | Info | Months approximated as 365-day years; rounding by wei. | Documented. |
| F9 | Info | Per-wallet cap bypassable with many wallets; not an AML control. | Documented. |

Not written yet: malicious-token reentrancy test, coverage measurement. Do not call the project audited before an independent audit.
