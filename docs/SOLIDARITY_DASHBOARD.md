# Aide directe : site web, vote et distribution

## Site web (réseau Base), trois sections
1. **Compteur d'Impact** (en haut) : solde du `solidarityWallet` (les 5 % d'aide) en temps réel.
2. **Espace Demandeurs** : le demandeur connecte son wallet et téléverse sa facture, données privées masquées. Le document brut n'est jamais public ; seules les informations nécessaires sont affichées.
3. **Arène de Vote (Tribunal Solidaire)** : cartes anonymes (montant, fournisseur, urgence) avec [OUI 👍] / [NON 👎].

## Vote public (décision du 2026-11-09)
- Le vote est **public** : chaque visiteur peut voter OUI ou NON après une simple identification (Google ou équivalent). Un compte = une voix.
- Ce choix remplace le vote pondéré par la détention (minimum 1 000 SLDR).
- Le vote et l'identification sont hors chaîne (site web). Le contrat de gestion du `solidarityWallet` ne doit exécuter un paiement que sur une décision valide ; le mécanisme d'attestation du résultat est à définir (voir risques).

## Distribution
- Cycle de **24 heures** : les factures approuvées sont payées sur le fonds disponible.
- Règle de priorité si le fonds est insuffisant : à définir (urgence, ordre d'arrivée, vote).

## Limite de vente de 1 % : plateformes de trading uniquement
- La limite ne s'applique qu'aux ventes vers les paires de trading (ex. Uniswap). Les transferts P2P n'influencent pas le prix et ne sont pas limités.
- **Aucune exemption par bénéficiaire n'est nécessaire** : un bénéficiaire peut transférer ou vendre en P2P librement, et on ne bloque jamais un transfert en échange d'une aide.
- Le contrat du token fait seulement une chose : router les 5 % d'aide vers le `solidarityWallet`. Sa gestion (versements, règles) est un contrat à part, conforme à la règle d'or.

## Risques
- **Faux comptes** : une identification Google est facile à multiplier ; un vote public à une voix par compte est vulnérable aux bots. Pistes : un seul compte par personne vérifié, délai minimal d'ancienneté, quorum, vérification des factures hors chaîne.
- **Confiance** : un résultat de vote hors chaîne exige un signataire ou un oracle, ce qui réintroduit une clé privilégiée, contraire à « sans admin ». À trancher (ex. comité de 3 signataires tirés au sort, multisig).
- **Vie privée** : jamais de documents ni d'identités sur la chaîne ; données masquées sur les cartes.
- Un dossier par adresse et par période, contre la revente de factures.
