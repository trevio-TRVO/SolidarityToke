# Aide directe : site web, vote et distribution

## Site web (réseau Base), trois sections
1. **Compteur d'Impact** (en haut) : solde du `solidarityWallet` (les 5 % d'aide) en temps réel.
2. **Espace Demandeurs** : le demandeur connecte son wallet et téléverse sa facture, données privées masquées. Le document brut n'est jamais public ; seules les informations nécessaires sont affichées.
3. **Arène de Vote (Tribunal Solidaire)** : cartes anonymes (montant, fournisseur, urgence) avec [OUI 👍] / [NON 👎].

## Validation et protection du projet (décision du 2026-11-09)
Objectif central : **faire évoluer le projet en le protégeant** contre les faux bénéficiaires et les bots. C'est le rôle de la communauté.

1. **Dépôt de la demande** : facture téléversée (données privées masquées) **plus une description** écrite par le demandeur. Le collage est bloqué dans le champ (saisie manuelle uniquement).
2. **Contrôle par IA, automatique** : analyse de la facture et de la description (cohérence, doublons, falsification, texte généré en masse, comportement de bot). L'IA **classe et signale** ; elle ne détient aucune clé de paiement.
3. **Validation par au moins 5 acquéreurs de lots** : seuls les wallets ayant acheté un lot (preuve vérifiable dans `CommunityLots.grants`) ont un compte validateur spécial. Il faut **au moins 5 validateurs distincts** qui approuvent.
4. **Vote public** : tout visiteur identifié (Google ou équivalent, une voix par compte) peut voter OUI ou NON. Il sert de signal communautaire.
5. **Paiement automatique** : dès que les conditions sont réunies (dossier non signalé par l'IA, ≥ 5 validations de détenteurs de lots, vote public favorable), le contrat du `solidarityWallet` paie la facture au prochain cycle de 24 h. Aucune intervention manuelle.

### Principes d'architecture
- Les 5 validations sont **sur chaîne** : signatures de wallets détenant un lot, vérifiées par le contrat, donc sans admin.
- L'IA et le vote public sont hors chaîne. Pour rester « sans admin », l'IA ne peut que **bloquer ou signaler** un dossier, jamais le payer ; le droit de veto est lui-même contestable par les validateurs (règle à définir).
- Les validateurs sont des acheteurs de lots : ils sont les plus engagés dans le projet (le début est pour « les croyants »).

## Distribution
- Cycle de **24 heures** : les factures approuvées sont payées sur le fonds disponible.
- Règle de priorité si le fonds est insuffisant : à définir (urgence, ordre d'arrivée, vote).

## Limite de vente de 1 % : plateformes de trading uniquement
- La limite ne s'applique qu'aux ventes vers les paires de trading (ex. Uniswap). Les transferts P2P n'influencent pas le prix et ne sont pas limités.
- **Aucune exemption par bénéficiaire n'est nécessaire** : un bénéficiaire peut transférer ou vendre en P2P librement, et on ne bloque jamais un transfert en échange d'une aide.
- Le contrat du token fait seulement une chose : router les 5 % d'aide vers le `solidarityWallet`. Sa gestion (versements, règles) est un contrat à part, conforme à la règle d'or.

## Risques
- **Blocage du collage** : contrôle côté navigateur uniquement, contournable ; c'est un frein, pas une garantie. La vraie protection est l'IA et la validation par 5 détenteurs de lots.
- **Collusion** : 5 validateurs peuvent s'entendre ou être le même acteur avec plusieurs wallets (1 achat par wallet). Pistes : validateurs tirés au sort parmi les détenteurs, ancienneté minimale du lot, rotation.
- **Faux comptes** : une identification Google est facile à multiplier ; un vote public à une voix par compte est vulnérable aux bots. Pistes : un seul compte par personne vérifié, délai minimal d'ancienneté, quorum, vérification des factures hors chaîne.
- **Confiance** : un résultat de vote hors chaîne exige un signataire ou un oracle, ce qui réintroduit une clé privilégiée, contraire à « sans admin ». À trancher (ex. comité de 3 signataires tirés au sort, multisig).
- **Vie privée** : jamais de documents ni d'identités sur la chaîne ; données masquées sur les cartes.
- Un dossier par adresse et par période, contre la revente de factures.
