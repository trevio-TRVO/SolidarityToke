# Déploiement V3 : BillPayProtocol (BILL)

Base : suit le V2 (`v2/`, TrvoToken) : offre fixe frappée au constructeur, aucun owner, aucun mint, aucune pause.

## Contrats
1. `BillPayProtocol` : token. 10 % de contribution au trade uniquement (5 % aide, 2 % burn, 2 % opérationnel, 1 % auto-liquidité), limite de vente de 1 % de l'offre vers une paire.
2. `SolidarityWallet` : reçoit les 5 %, paie les factures validées (conseil + 5 acquéreurs de lots).
3. `CommunityLots` : distribution communautaire de 15 % (lots, cliff 45 j, linéaire 30 j).

## Ordre de déploiement (Base Sepolia d'abord)
1. Déployer `CommunityLots` (adresse du token à connaître : voir étape 2).
2. Prédire l'adresse du token (nonce du déployeur) puis calculer l'adresse de la paire.
3. Déployer `SolidarityWallet` (token, lots, fondateur, 10 membres du conseil).
4. Déployer `BillPayProtocol` via `script/DeployV3.s.sol`.
5. Envoyer les 15 % au contrat `CommunityLots` (préfinancement), ajouter la liquidité, vérifier les contrats sur Basescan.

`forge script script/DeployV3.s.sol --rpc-url base_sepolia --account <keystore> --broadcast`

## Écarts connus avec la spécification
- **Anti-crash 1 %** : non implémenté (mécanisme non défini). À spécifier.
- **Auto-liquidité 1 %** : le token envoie 1 % à `liquidityReserve`. L'ajout automatique à la liquidité exige un contrat séparé et un routeur vérifié.
- **Paires** : le modèle « paire » couvre les pools de type Uniswap V2. Les pools V3/V4 n'ont pas de paire-contrat identique : à traiter avant déploiement.
- **Chicken-and-egg de la paire** : l'adresse de la paire dépend de l'adresse du token. La paire est donc passée au constructeur (figée), ce qui impose de la calculer à l'avance.
- **Répartition** : seule la part communautaire (15 %) est fixée. Le script met 10 % en liquidité et le reste à un destinataire (à décider), conformément à rien de figé dans la spécification.
- **Frais de contrats** : `CommunityLots` et `SolidarityWallet` doivent être exemptés de la limite de vente si besoin ; le P2P n'est pas taxé.
- **Adresses officielles** (routeur, factory, init code hash) à vérifier dans la documentation officielle de Base avant de les coder.

## Avant mainnet
Revue interne, Slither, audit indépendant, essai complet sur Base Sepolia, revue juridique, aucune promesse de rendement (voir la politique du V2).
