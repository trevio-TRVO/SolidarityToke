[Français](README.md) | **English** | [Русский](README.ru.md)

# BillPay Protocol (BILL) V3

Deflationary token on Base, with no admin: nothing can be modified after deployment.

## Golden rule: the Circular Contribution Ecosystem

> Every transaction on our token is not a cost, but an automatic 10% solidarity contribution, reinjected directly to stabilize the market and change lives.
>
> - **5% Direct Aid**: allocated instantly to fund and pay the electricity and heating bills of families in difficulty.
> - **2% Deflationary Scarcity**: deducted to permanently destroy tokens on every trade, creating a mathematical shortage that increases the value of holders' wallets.
> - **2% Operational Support**: dedicated to guerrilla marketing and autonomous technical maintenance to propel the project.
> - **1% Auto-Liquidity**: locked in by the code to continuously strengthen the price floor and protect traders.
>
> Here, the more active the market, the greater the social impact. Speculating becomes an act of solidarity.

**The contribution only applies to trades** (buying/selling through the liquidity pair), not to simple transfers nor to lot `claim()` calls.

Vocabulary: we speak of a **solidarity contribution** or a **distributed levy**, never a "tax". The most important point is direct aid: direct payment of bills for people in an emergency.

## Community distribution (15% of the supply)

Full specification: [docs/en/V3_COMMUNITY_DISTRIBUTION.md](docs/en/V3_COMMUNITY_DISTRIBUTION.md). Contract: `contracts/CommunityLots.sol`.

- **At launch: 100 pioneer lots only** (1%), 10 USDC per lot, 100,000 BILL fixed.
- **Following series** (90 paid + 10 free, one series every 30 days): they open only once the price has taken off (x10 the launch price, via `openSeries()`).
- **Paid lot: 50 USDC for 100 USDC of BILL at the market price** (double the stake, never more). The quantity decreases as the price rises (scarcity). Example: BILL at 1 USDC, 50 USDC = 100 BILL.
- One lot per wallet. Vesting of each lot: locked for 45 days, then linear unlocking over 30 days. Unsold lots are kept in the contract.
- **Liquidity**: 500,000 BILL + 50 USDC at launch; 499.5 M BILL in reserve injected gradually by `AutoLiquidity` (see [docs/en/DEPLOY_V3.md](docs/en/DEPLOY_V3.md)).

## Direct aid: website and community vote

Specification: [docs/en/SOLIDARITY_DASHBOARD.md](docs/en/SOLIDARITY_DASHBOARD.md) (dashboard on Base, applicants area, public vote by identification, distribution every 24 h, 1% sell limit on trading platforms only).

## Council and website

- [docs/en/COUNCIL.md](docs/en/COUNCIL.md): monthly composition of the council.
- [docs/en/SITE_REQUIREMENTS.md](docs/en/SITE_REQUIREMENTS.md): website requirements.
- `site/index.html`: static mockup.

## Version history

- V1: abandoned.
- [`v2/`](v2/ARCHIVE.md): archive of TREVIO (TRVO), fixed supply of 21 M, fixed-price sale.
- V3: this repository (BillPay Protocol, BILL).

## Logbook

| Date | Entry |
|---|---|
| 2026-11-09 | Specification of the V3 community distribution: series of 100 lots (90 paid, 10 free), max price x2 per series, non-increasing quantity (scarcity), 1 purchase per wallet, 45-day cliff then 30-day linear. |
| 2026-11-09 | `CommunityLots.sol` contract written (no owner, immutable parameters, capped pool) and compiled. PR #5. |
| 2026-11-09 | Golden rule integrated into the README. Decision: the 10% contribution only applies to trades; `claim()` calls of the lots contract are therefore not concerned. |
| 2026-11-09 | Specification of the dashboard, the weighted vote (min. 1,000 BILL), the 24 h distribution and the exemption from the 1% sell limit for beneficiaries. |
| 2026-11-09 | Foundry tests: 9 tests pass (purchase, 1/wallet, series and x2 price, exhaustion, cliff + linear, free lots, underfunded pool, constructor limits). Run: `forge test --use <solc 0.8.26>`. |
| 2026-11-09 | Decisions: public vote (Google identification or equivalent, one vote per account) instead of the weighted vote; 1% sell limit only on trading platforms (P2P free), so no more per-beneficiary exemption; the token only routes the 5% to the `solidarityWallet`, managed by a dedicated contract. |
| 2026-11-09 | Decision: automated payment. Request = bill + description (paste blocked); AI anti-bot check (flags, does not pay); on-chain validation by at least 5 lot buyers; public vote; payment at the 24 h cycle. Principle: make the project evolve while protecting it. |
| 2026-11-09 | `SolidarityWallet.sol` contract: receives the 5%, pays only the beneficiary of a request. Conditions: ≥ 5 validators who are lot buyers, council weight ≥ 5 (10 accounts at 1, founder at 3, so the founder needs 2 members), 24 h delay, cap of 20% of the balance, 1 payment per beneficiary / 30 days. Cancellation: founder alone, or council at weight 5. 10 tests. |
| 2026-11-09 | Council composition (3 pioneers, influencer, X/Facebook/TikTok contributors, trader, top wallet, 1 elected seat), website requirements and static mockup `site/index.html`. |
| 2026-11-09 | Council rotation (issue #12): `CouncilRegistry.sol` (10 seats, no owner, rotation at most every 30 days confirmed by M fixed election signers), `SolidarityWallet` reads the council from the registry; a removed member loses their rights and their approvals no longer count. Tests and deployment script updated. |
| 2026-11-09 | Naming validated: contract `BillPayProtocol`, ticker `BILL`, repository `billpay-protocol`, interface "BillPay Hub / BillPay DAO", site on GitHub Pages. Renaming the current repository (`SolidarityToke`) remains to be done by the owner (insufficient rights). |
| 2026-11-09 | `BillPayProtocol.sol` token (7 tests), `DeployV3.s.sol` script, deployment guide. Follows the V2 model. Anti-crash not specified. |
| 2026-11-09 | Allocation fixed: 50% liquidity, 20% founder (vesting), 15% community lots, 15% growth (vesting). Single deployment script with predicted addresses, simulated without errors. |
| 2026-11-09 | 7-day launch protection (0.1% per sale, 0.2% per wallet per day), `AutoLiquidity` contract, V2 pool only, founder vesting proposed 90 d + 36 months. 30 tests. |
| 2026-11-09 | Founder vesting validated: 90 days then 36 linear months. |
| 2026-11-09 | Lots redone: 100 pioneers (1%, 10 USDC) + 14 series of 100 (90 paid at 50% of the market price via TWAP, 10 free), one series per 30 days. Growth: 48 monthly periods (`MonthlyVesting`). BILL/USDC pair. V1 abandoned. 37 tests. |
| 2026-11-09 | Launch liquidity: 500,000 BILL + 50 USDC; 499.5 M BILL in `AutoLiquidity` reserve, injected as the 1% contribution is harvested. Lots: only the pioneer lot is fixed, the others deliver exactly x2 at the TWAP price (variable quantity), unsold lots kept. 47 tests. |
| 2026-11-09 | PR #5 merged. V2 code (TREVIO) archived in `v2/`. V1 pending. |
| 2026-11-09 | Lot prices: pioneer 10 USDC (100,000 BILL fixed); following lots 50 USDC for 100 USDC of BILL at the TWAP price (x2). |
| 2026-11-09 | At launch: 100 pioneers only. The 50 USDC series open via `openSeries()` when the TWAP reaches x10 (0.001 USDC/BILL). 49 tests. |
| Upcoming | Phase 0 (#2), V4 participation program (#3), anti-sybil (#4), audit. |
