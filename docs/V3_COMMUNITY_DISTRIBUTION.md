# V3 : distribution communautaire (15 % de l'offre = 150 000 000 BILL)

Contrat : `contracts/CommunityLots.sol` (sans owner, paramètres immuables).

## Structure : 1 500 lots de 100 000 BILL
| Phase | Lots | Règle |
|---|---|---|
| Pionniers (1 %) | 100 | Prix 10 USDC par lot, quantité fixe de 100 000 BILL (valeur 10 USDC au prix de lancement 0,0001 USDC/BILL). Ouverts dès le lancement. |
| Séries continues | 14 séries de 100 | 90 payants + 10 gratuits. Une série s'ouvre toutes les 30 jours, jusqu'à épuisement de la réserve (14 séries, environ 14 mois). |

Total : (100 + 14 × 100) × 100 000 = 150 000 000 BILL.

## Prix et quantité
- Lot pionnier : **fixe** (100 000 BILL pour 10 USDC).
- Lots suivants : **50 USDC** contre **100 USDC de BILL au cours TWAP** (x2, jamais plus). Exemple : BILL à 1 USDC, 50 USDC payés = 100 BILL. La quantité varie avec le prix : plus BILL monte, moins le lot contient de tokens (rareté). Plafond de sécurité : 10 000 000 BILL par lot. Si la réserve ne suffit plus, les achats sont refusés.
- Les lots invendus restent dans le contrat (aucun burn, aucune sortie).
- Oracle TWAP (paire BILL/USDC) : `update()` public (au plus toutes les 24 h), fenêtre minimale de 1 h. Appeler `update()` après l'ajout de liquidité, puis attendre 1 h.
- Un lot par wallet.

## Lots gratuits
- 10 lots par série (même quantité que les lots payants, 100 USDC de valeur) vont aux 10 sous-wallets du wallet spécial (programme de participation, géré par le V4 : campagne, 3 administrateurs tirés au sort par lot). `allocateFree(série)` est public et ne peut être appelé qu'une fois par série.

## Vesting par lot
- Cliff de 45 jours à partir de l'achat, puis déblocage linéaire sur 30 jours. Aucun claim anticipé.

## Garde-fous
- Pool plafonné : le contrat doit être préfinancé de 150 000 000 BILL ; `outstanding <= solde` est vérifié à chaque attribution.
- Les achats ne sont possibles que si une observation TWAP existe.
