# BillPay Protocol website: requirements

The site is the **first community project**. Public, Base network.

## Users
Visitor · Applicant · Lot buyer (validator) · Council member · Founder

## Pages
1. **Home / Dashboard**: Impact Counter (balance of the `solidarityWallet`, in real time), total paid out, number of families helped, next distribution (24 h countdown).
2. **Applicants Area**: wallet connection, form (amount, provider, urgency, description without paste), bill upload with masking of private data.
3. **Solidarity Tribunal**: anonymous cards, YES/NO (Google or equivalent login), status (validations 0/5, council approvals, 24 h delay).
4. **Validators Area**: reserved for lot buyers, on-chain validation.
5. **Council**: composition of the month, rankings (influencer, X, Facebook, TikTok, trader, top wallet), vote for the elected seat.
6. **Lots**: series, price, remaining quantity, purchase of a lot (1 per wallet), vesting schedule (45 d cliff, 30 d linear), `claim`.
7. **Transparency**: payment history, project logbook, links to the contracts and the code.

## Functional requirements
- Wallet connection (Base) and Google login for voting.
- AI check of requests (flags, does not pay) before publication.
- Private data never published nor on-chain: only the fingerprint of the file is.
- Description field without paste (browser-side brake).
- Notifications of a request's status.
- French first; English and Turkish afterwards (the example mentioned Euro/Lira).

## Non-functional requirements
- Mobile first, readable, highly visual.
- Encryption of bills at rest, limited retention period, GDPR compliance (deletion on request).
- Anti-bot, rate limiting, audit log.
- No private key on the server side.

## Proposed stack
Next.js + TypeScript, wagmi/viem (Base), Google Auth (OAuth), encrypted bill storage, PostgreSQL database for votes, indexing of contract events.

## Steps
1. Mockup (`site/index.html`) validated.
2. On-chain reading (impact counter, lots).
3. Applicants Area and Tribunal.
4. Validators Area and Council.
5. Security audit, then opening.

## Naming
- Interface: **BillPay Hub** (voting DApp: **BillPay DAO**).
- Hosting: GitHub Pages, `https://trevio-TRVO.github.io/billpay-protocol/` (repository named `billpay-protocol`).
