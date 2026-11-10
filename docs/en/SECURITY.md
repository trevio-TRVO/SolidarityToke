# Security review — V3 hardening

1. **AutoLiquidity**: reserve stock drawn for LP but unused by the router is now returned to `stockLeft` (it was resold as harvest).
2. **CommunityLots**: `MAX_LOT_TOKENS` lowered 10M → 1M BILL (100 USDC at launch price).
3. **CommunityLots**: `MIN_TWAP_WINDOW` raised 1 h → 24 h.
4. **CouncilRegistry**: election signers can no longer be council members.
5. **SolidarityWallet**: the payee cannot approve their own request.
6. **SolidarityWallet**: per-payment cap re-checked at execution.
7. **DeployV3**: deployer taken from `vm.readCallers()` under broadcast so predicted CREATE addresses match.

Tests: 56 pass. Full details (FR): `docs/SECURITY.md`.
