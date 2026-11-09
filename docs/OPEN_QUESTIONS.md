# Points ouverts

## Décisions validées (2026-11-09)
- Le fondateur finance lui-même les 50 USDC de la liquidité initiale (avec 500 000 BILL).
- Sa rémunération provient des 2 % de contribution « gestion et marketing » (`operationsWallet`), sans passe-droit sur le token ; ses 20 % restent soumis au vesting et aux limites de vente.
- Les lots gratuits contiennent la même quantité de BILL que les 90 lots payants de la série (valeur de marché de 100 USDC au cours TWAP).

- Seuil de déclenchement des séries : x10 du prix de lancement (0,001 USDC/BILL), validé le 2026-11-09.
- Anti-sybil : 1 achat par wallet est contournable par multi-wallets (voir issue #4).
- Programme V4 : attribution des lots gratuits (campagne, 3 administrateurs tirés au sort).
- Vérifier les adresses officielles Uniswap V2 sur Base (routeur, paire) avant déploiement.
- Oracle TWAP manipulable à coût élevé mais non nul ; fenêtre minimale de 1 h.
- Tests sur Base Sepolia, analyse Slither, audit externe et revue juridique avant mainnet.
