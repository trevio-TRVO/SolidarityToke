# V3 : distribution communautaire (15 % de l'offre = 150 000 000 BILL)

Contrat : `contracts/CommunityLots.sol` (sans owner, paramètres immuables).

## Structure : 1 500 lots de 100 000 BILL
| Phase | Lots | Règle |
|---|---|---|
| Pionniers (1 %) | 100 | Valeur 10 USDC par lot au prix de lancement (0,0001 USDC/BILL), vendus 5 USDC (50 %). Ouverts dès le lancement. |
| Séries continues | 14 séries de 100 | 90 payants + 10 gratuits. Une série s'ouvre toutes les 30 jours, jusqu'à épuisement de la réserve (14 séries, environ 14 mois). |

Total : (100 + 14 × 100) × 100 000 = 150 000 000 BILL.

## Prix
- Lot payant = **50 % de la valeur de marché** : le prix suit le marché (TWAP de la paire BILL/USDC), donc l'acheteur reçoit 200 % de ce qu'il paie. Le prix n'est plus doublé à chaque vente : il suit le marché.
- Oracle TWAP : point d'observation public `update()` (au plus toutes les 24 h), fenêtre minimale de 1 h. Il faut appeler `update()` après l'ajout de liquidité, puis attendre 1 h avant le premier achat de série continue.
- Un lot par wallet.

## Lots gratuits
- 10 lots par série vont aux 10 sous-wallets du wallet spécial (programme de participation, géré par le V4 : campagne, 3 administrateurs tirés au sort par lot). `allocateFree(série)` est public et ne peut être appelé qu'une fois par série.

## Vesting par lot
- Cliff de 45 jours à partir de l'achat, puis déblocage linéaire sur 30 jours. Aucun claim anticipé.

## Garde-fous
- Pool plafonné : le contrat doit être préfinancé de 150 000 000 BILL ; `outstanding <= solde` est vérifié à chaque attribution.
- Les achats ne sont possibles que si une observation TWAP existe.
