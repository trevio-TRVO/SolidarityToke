# TREVIO

[![CI](https://github.com/trevio-TRVO/TREVIO/actions/workflows/ci.yml/badge.svg)](https://github.com/trevio-TRVO/TREVIO/actions/workflows/ci.yml)
![Solidity](https://img.shields.io/badge/Solidity-0.8.24-363636)
![OpenZeppelin](https://img.shields.io/badge/OpenZeppelin-5.x-4E5EE4)
![Network](https://img.shields.io/badge/Network-Base-0052FF)
![License](https://img.shields.io/badge/License-MIT-green)

Official Trevio (TRVO) smart contracts, tokenomics, documentation, and deployment pipeline on Base.

> **Status: pre-audit, not deployed.** Tests are written but their results are not yet published. Nothing here is an offer, a promise of returns, or legal advice. See [SECURITY.md](SECURITY.md).

## Architecture

- `src/TrvoToken.sol`: fixed-supply ERC-20, minted once in the constructor. No owner, mint, burn or pause.
- `src/TokenSale.sol`: fixed-price USDC sale, refunds, buyer vesting (25% at TGE, 75% linear over 180 days).
- `script/Deploy.s.sol`: deploys token, 3 OpenZeppelin VestingWallets and the sale (Base Sepolia / Base).
- `test/`: Foundry tests.

The initial brief named `TrevioToken.sol`, `TrevioLaunch.sol` and `TrevioSale.sol`. The code uses `TrvoToken` and `TokenSale`; there is no `TrevioLaunch` yet (see SECURITY.md, F1).

## Tokenomics

| Allocation | % | TRVO | Vesting |
|---|---|---|---|
| Public sale | 20 | 4,200,000 | 25% at TGE, 75% linear over 180 days |
| Liquidity | 10 | 2,100,000 | LP lock 24 months (not yet enforced on-chain, F1) |
| Team | 20 | 4,200,000 | starts +12 months, 48 months linear |
| Treasury | 30 | 6,300,000 | 60 months linear |
| Rewards | 20 | 4,200,000 | 60 months linear |
| **Total** | 100 | **21,000,000** | fixed, no inflation |

VestingWallet releases continuously: monthly figures (87,500 / 105,000 / 70,000 TRVO) are averages.

Sale: 420 TRVO per USDC, soft cap 5,000 USDC, hard cap 10,000 USDC, 500 USDC per wallet (weak anti-concentration signal only). Full refund if the soft cap is missed.

## Roadmap

No dates committed. 1) contracts and tests, 2) fix open findings and publish CI/coverage, 3) Base Sepolia, 4) independent audit, 5) Base Mainnet.

## Deployed addresses

None. Nothing is deployed on Base Sepolia or Base Mainnet.

## Foundry

```bash
forge install foundry-rs/forge-std OpenZeppelin/openzeppelin-contracts@v5.0.2 --no-git
forge fmt --check
forge build
forge test -vvv
forge coverage
```

## Deploy on Base

Copy `.env.example` to `.env`, then use a keystore or hardware wallet (never a raw key in a file):

```bash
source .env
forge script script/Deploy.s.sol --rpc-url base_sepolia --account $DEPLOYER_ACCOUNT --broadcast --verify
```

Chain IDs: Base Sepolia 84532, Base 8453. Use `--rpc-url base` only after the audit.

## Verify on Basescan

```bash
forge verify-contract <ADDRESS> src/TrvoToken.sol:TrvoToken --chain base --etherscan-api-key $BASESCAN_API_KEY --constructor-args $(cast abi-encode "constructor(address,uint256)" <RECIPIENT> 21000000000000000000000000)
```

## License

MIT
