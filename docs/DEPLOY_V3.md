# Déploiement V3 : BillPayProtocol (BILL)

Base : suit le V2 (`v2/`, TrvoToken) : offre fixe frappée au constructeur, aucun owner, aucun mint, aucune pause.

## Contrats
1. `BillPayProtocol` : token. 10 % de contribution au trade uniquement (5 % aide, 2 % burn, 2 % opérationnel, 1 % auto-liquidité), limite de vente de 1 % de l'offre vers une paire.
2. `SolidarityWallet` : reçoit les 5 %, paie les factures validées (conseil + 5 acquéreurs de lots).
3. `CommunityLots` : distribution communautaire (lots, cliff 45 j, linéaire 30 j).
4. `AutoLiquidity` : reçoit le 1 % et l'ajoute à la liquidité (LP verrouillés à l'adresse morte), appel public, 1 fois par 24 h.

## Répartition (1 000 000 000 BILL, offre fixe)
| Part | % | Destination | Vesting |
|---|---|---|---|
| Liquidité initiale | 50 | `LIQUIDITY_SEEDER` (exempté de la contribution pour ajouter la liquidité) | LP à verrouiller dans un locker public (24 mois comme le V2) |
| Fondateur | 20 | `VestingWallet` OpenZeppelin | départ +90 jours, puis 36 mois linéaires (proposé : le V2 prévoyait 12 mois + 48 mois ; voir « Rémunération du fondateur ») |
| Réserve communautaire et prévente | 15 | `CommunityLots` | cliff 45 j + linéaire 30 j par lot |
| Croissance et marketing | 15 | `VestingWallet` OpenZeppelin | 60 mois linéaires (modèle trésorerie V2, hypothèse) |

## Déploiement
`script/DeployV3.s.sol` déploie en une passe, dans l'ordre : 2 VestingWallets, `SolidarityWallet`, `CommunityLots`, `AutoLiquidity`, `BillPayProtocol`. Variable `ROUTER` : routeur Uniswap V2 officiel sur Base, à vérifier. Ces contrats se référencent entre eux : les adresses sont prédites par nonce et vérifiées (`require`). Le script a été exécuté en simulation locale sans erreur.

`forge script script/DeployV3.s.sol --rpc-url base_sepolia --account <keystore> --broadcast`

Ensuite : ajouter la liquidité (50 %) et verrouiller les LP, vérifier les contrats sur Basescan, renseigner `LIQUIDITY_RESERVE`.

## Écarts connus avec la spécification
- **Protection de lancement (7 jours)** : ventes vers une paire limitées à 0,1 % de l'offre par transaction (1 000 000 BILL) et 0,2 % par wallet et par 24 h. Ensuite : 1 % par transaction et 1 % par wallet et par 24 h. Les achats et le P2P ne sont pas limités ; l'ajout de liquidité initial est exempté. Limite connue : un détenteur peut répartir ses jetons sur plusieurs wallets pour multiplier la limite (le P2P est libre). Elle ralentit une vente massive sans l'empêcher totalement.
- **Auto-liquidité 1 %** : `AutoLiquidity` (contrat séparé, sans owner). Chaque appel utilise au plus 0,2 % de la réserve de la paire, tolérance de 5 % de glissement, LP envoyés à l'adresse morte. Une protection sandwich parfaite n'existe pas sans oracle de prix : les montants plafonnés limitent le risque.
- **Paires** : seules les paires de type Uniswap V2 (ou équivalents) sont gérées. Une vente par un pool V3/V4 échappe à la contribution et à la limite : ne déployer que sur un pool V2.
- **Adresse de la paire** : elle dépend de l'adresse du token (prédite par le script) ; à calculer avec la factory officielle (adresses et init code hash à vérifier dans la documentation officielle de Base).
- **Hypothèses de vesting** (fondateur, croissance) : à confirmer.

## Rémunération du fondateur
Les 20 % du fondateur sont verrouillés : 90 jours sans déblocage, puis 36 mois linéaires (environ 5,5 M BILL par mois), vendables dans les limites ci-dessus. Pendant les 90 premiers jours, aucun déblocage de ce lot : la rémunération doit venir du budget opérationnel (2 % de chaque trade, `operationsWallet`) ou du fonds de croissance, dans des règles publiques. Le fondateur n'est exempté d'aucune limite, ce qui protège aussi la confiance des détenteurs.
- **Gas** : la contribution est prélevée par transfert vers 4 destinataires, donc plus coûteuse qu'un ERC-20 simple.

## Avant mainnet
Revue interne, Slither, audit indépendant, essai complet sur Base Sepolia, revue juridique, aucune promesse de rendement (voir la politique du V2).

## Dépendances
`forge install OpenZeppelin/openzeppelin-contracts@v5.0.2 foundry-rs/forge-std --no-git` (le dossier `lib/` n'est pas versionné).
