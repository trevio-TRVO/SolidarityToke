# Aide directe : site web, vote et distribution

## Site web (réseau Base), trois sections
1. **Compteur d'Impact** (en haut) : solde du `solidarityWallet` (les 5 % d'aide) en temps réel.
2. **Espace Demandeurs** : le demandeur connecte son wallet et téléverse sa facture, données privées masquées. Le document brut n'est jamais public ; seules les informations nécessaires sont affichées.
3. **Arène de Vote (Tribunal Solidaire)** : cartes anonymes (montant, fournisseur, urgence) avec [OUI 👍] / [NON 👎].

## Anti-fraude : vote pondéré par la détention
- Seuls les wallets détenant au moins **1 000 SLDR** peuvent voter.
- Le poids du vote est proportionnel au solde.
- Points à définir : prise d'un snapshot du solde à l'ouverture du vote (contre les flash-loans et les transferts entre wallets), quorum, seuil d'approbation, durée du vote.

## Distribution
- Cycle de **24 heures** : les factures approuvées sont payées sur le fonds disponible.
- Règle de priorité si le fonds est insuffisant : à définir (urgence, ordre d'arrivée, vote).

## Exemption de la limite de vente de 1 %
Le bénéficiaire doit pouvoir vendre ses tokens sans restriction pour payer sa facture. Son adresse est exemptée de la limite de vente de 1 % le temps de la conversion (USDC ou monnaie locale sur Uniswap).

**Contrainte "sans admin"** : l'exemption ne peut pas être accordée à la main. Elle doit être inscrite automatiquement par le contrat de paiement lors de l'approbation du vote, avec expiration (ex. 24 h), sans aucune clé privilégiée.

## Risques
- Faux dossiers et revente de factures : vérification de la facture hors chaîne, un dossier par adresse et par période.
- Baleines : le vote pondéré donne le pouvoir aux gros détenteurs ; prévoir un plafond de poids par wallet.
- Vie privée : jamais de documents ou d'identités sur la chaîne.
