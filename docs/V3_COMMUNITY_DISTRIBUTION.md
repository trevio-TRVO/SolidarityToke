# V3 – Distribution communautaire (15 % de l'offre)

Contrat : `contracts/CommunityLots.sol` (Solidity ^0.8.20, sans owner, paramètres immuables).

## Règles
- **Phase 0** : 1 % de l'offre en 100 lots de 10 USDC (à déployer via le même mécanisme / config dédiée – à définir).
- **Phase 1 (continue)** : séries de 100 lots = 90 payants + 10 gratuits.
- Chaque lot = 200 % de sa valeur (ex. lot à 100 $ → 200 USDC de tokens).
- Prix : lot 1 = 50 $, lot 2 = 100 $. Hausse **max ×2** entre séries (imposé dans le constructeur).
- Quantité de tokens par lot **non croissante** → rareté.
- **1 achat par wallet**. Vesting par lot : cliff 45 j à partir de l'achat, puis linéaire 30 j. Aucun claim anticipé.
- Lots gratuits : 10 sous-wallets du wallet spécial ; attribution permissionless via `allocateFree(série)`. Programme/campagne (3 admins aléatoires par lot) = **V4**.
- Pool plafonné : le contrat doit être préfinancé ; `outstanding <= balance` est vérifié à chaque attribution.



