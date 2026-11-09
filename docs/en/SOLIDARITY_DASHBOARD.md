# Direct aid: website, vote and distribution

## Website (Base network), three sections
1. **Impact Counter** (at the top): balance of the `solidarityWallet` (the 5% aid) in real time.
2. **Applicants Area**: the applicant connects their wallet and uploads their bill, private data masked. The raw document is never public; only the necessary information is displayed.
3. **Voting Arena (Solidarity Tribunal)**: anonymous cards (amount, provider, urgency) with [YES 👍] / [NO 👎].

## Validation and protection of the project (decision of 2026-11-09)
Central goal: **make the project evolve while protecting it** against fake beneficiaries and bots. This is the community's role.

1. **Submitting the request**: uploaded bill (private data masked) **plus a description** written by the applicant. Pasting is blocked in the field (manual typing only).
2. **Automatic AI check**: analysis of the bill and the description (consistency, duplicates, forgery, mass-generated text, bot behavior). The AI **ranks and flags**; it holds no payment key.
3. **Validation by at least 5 lot buyers**: only wallets that bought a lot (verifiable proof in `CommunityLots.grants`) have a special validator account. **At least 5 distinct validators** must approve.
4. **Public vote**: any identified visitor (Google or equivalent, one vote per account) can vote YES or NO. It serves as a community signal.
5. **Automatic payment**: as soon as the conditions are met (file not flagged by the AI, ≥ 5 validations from lot holders, favorable public vote), the `solidarityWallet` contract pays the bill at the next 24 h cycle. No manual intervention.

### Architecture principles
- The 5 validations are **on-chain**: signatures from wallets holding a lot, verified by the contract, hence without admin.
- The AI and the public vote are off-chain. To remain "without admin", the AI can only **block or flag** a file, never pay it; the veto right is itself contestable by the validators (rule to be defined).
- Validators are lot buyers: they are the most committed to the project (the beginning is for "the believers").

## Distribution
- **24-hour** cycle: approved bills are paid from the available fund.
- Priority rule if the fund is insufficient: to be defined (urgency, order of arrival, vote).

## 1% sell limit: trading platforms only
- The limit only applies to sales to trading pairs (e.g. Uniswap). P2P transfers do not influence the price and are not limited.
- **No per-beneficiary exemption is necessary**: a beneficiary can transfer or sell P2P freely, and a transfer is never blocked in exchange for aid.
- The token contract does only one thing: route the 5% aid to the `solidarityWallet`. Its management (payouts, rules) is a separate contract, in line with the golden rule.

## Risks
- **Paste blocking**: browser-side check only, bypassable; it is a brake, not a guarantee. The real protection is the AI and the validation by 5 lot holders.
- **Collusion**: 5 validators can collude or be the same actor with several wallets (1 purchase per wallet). Ideas: validators drawn at random among holders, minimum lot age, rotation.
- **Fake accounts**: a Google identification is easy to multiply; a public vote of one vote per account is vulnerable to bots. Ideas: a single verified account per person, minimum seniority delay, quorum, off-chain bill verification.
- **Trust**: an off-chain vote result requires a signer or an oracle, which reintroduces a privileged key, contrary to "without admin". To be settled (e.g. committee of 3 signers drawn at random, multisig).
- **Privacy**: never documents nor identities on-chain; data masked on the cards.
- One file per address and per period, against the resale of bills.
