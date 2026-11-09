# BillPay Protocol (BILL) V3

Jeton déflationniste sur Base, sans admin : aucune modification possible après déploiement.

## Règle d'or : l'Écosystème à Contribution Circulaire

> Chaque transaction sur notre jeton n'est pas un coût, mais une contribution solidaire automatique de 10 % directement réinjectée pour stabiliser le marché et changer des vies.
>
> - **5 % d'Aide Directe** : alloués instantanément au financement et au paiement de factures d'électricité et de chauffage de familles en difficulté.
> - **2 % de Raréfaction Déflationniste** : déduits pour détruire définitivement des jetons à chaque échange, créant un manque mathématique qui valorise les portefeuilles des détenteurs.
> - **2 % de Support Opérationnel** : dédiés au marketing de guérilla et à la maintenance technique autonome pour propulser le projet.
> - **1 % d'Auto-Liquidité** : figés par le code pour consolider en continu le plancher de prix et protéger les traders.
>
> Ici, plus le marché est actif, plus l'impact social est massif. Spéculer devient un acte de solidarité.

**La contribution ne s'applique qu'aux trades** (achat/vente via la paire de liquidité), pas aux simples transferts ni aux `claim()` de lots.

Vocabulaire : on parle de **contribution solidaire** ou de **prélèvement réparti**, jamais de « taxe ». Le point le plus important est l'aide directe : paiement direct de factures pour des personnes en urgence.

## Distribution communautaire (15 % de l'offre)

Spécification complète : [docs/V3_COMMUNITY_DISTRIBUTION.md](docs/V3_COMMUNITY_DISTRIBUTION.md). Contrat : `contracts/CommunityLots.sol`.

## Aide directe : site web et vote communautaire

Spécification : [docs/SOLIDARITY_DASHBOARD.md](docs/SOLIDARITY_DASHBOARD.md) (tableau de bord sur Base, espace demandeurs, vote public par identification, distribution toutes les 24 h, limite de vente de 1 % sur les plateformes de trading uniquement).

## Conseil et site web

- [docs/COUNCIL.md](docs/COUNCIL.md) : composition mensuelle du conseil.
- [docs/SITE_REQUIREMENTS.md](docs/SITE_REQUIREMENTS.md) : besoin du site.
- `site/index.html` : maquette statique.

## Historique des versions

- `v1/` : à fournir (code V1 non trouvé).
- [`v2/`](v2/ARCHIVE.md) : archive de TREVIO (TRVO), offre fixe de 21 M, vente à prix fixe.
- V3 : ce dépôt (BillPay Protocol, BILL).

## Journal de bord

| Date | Entrée |
|---|---|
| 2026-11-09 | Spécification de la distribution communautaire V3 : séries de 100 lots (90 payants, 10 gratuits), prix max ×2 par série, quantité non croissante (rareté), 1 achat par wallet, cliff 45 j puis linéaire 30 j. |
| 2026-11-09 | Contrat `CommunityLots.sol` écrit (sans owner, paramètres immuables, pool plafonné) et compilé. PR #5. |
| 2026-11-09 | Intégration de la règle d'or au README. Décision : la contribution de 10 % ne s'applique qu'au trade ; les `claim()` du contrat de lots ne sont donc pas concernés. |
| 2026-11-09 | Spécification du tableau de bord, du vote pondéré (min. 1 000 BILL), de la distribution toutes les 24 h et de l'exemption de la limite de vente de 1 % pour les bénéficiaires. |
| 2026-11-09 | Tests Foundry : 9 tests passent (achat, 1/wallet, séries et prix ×2, épuisement, cliff + linéaire, lots gratuits, pool sous-financé, limites du constructeur). Lancer : `forge test --use <solc 0.8.26>`. |
| 2026-11-09 | Décisions : vote public (identification Google ou équivalent, une voix par compte) à la place du vote pondéré ; limite de vente de 1 % uniquement sur les plateformes de trading (P2P libre), donc plus d'exemption par bénéficiaire ; le token route seulement les 5 % vers le `solidarityWallet`, géré par un contrat dédié. |
| 2026-11-09 | Décision : paiement automatisé. Demande = facture + description (collage bloqué) ; contrôle IA anti-bots (signale, ne paie pas) ; validation sur chaîne par au moins 5 acquéreurs de lots ; vote public ; paiement au cycle de 24 h. Principe : faire évoluer le projet en le protégeant. |
| 2026-11-09 | Contrat `SolidarityWallet.sol` : reçoit les 5 %, paie uniquement le bénéficiaire d'une demande. Conditions : ≥ 5 validateurs acquéreurs de lots, poids du conseil ≥ 5 (10 comptes à 1, fondateur à 3, donc le fondateur a besoin de 2 membres), délai de 24 h, plafond de 20 % du solde, 1 paiement par bénéficiaire / 30 jours. Annulation : fondateur seul, ou conseil à poids 5. 10 tests. |
| 2026-11-09 | Composition du conseil (3 pionniers, influenceur, contributeurs X/Facebook/TikTok, trader, top wallet, 1 siège élu), besoin du site et maquette statique `site/index.html`. |
| 2026-11-09 | Nommage validé : contrat `BillPayProtocol`, ticker `BILL`, dépôt `billpay-protocol`, interface « BillPay Hub / BillPay DAO », site sur GitHub Pages. Le renommage du dépôt actuel (`SolidarityToke`) reste à faire par le propriétaire (droits insuffisants). |
| 2026-11-09 | PR #5 fusionnée. Archivage du code V2 (TREVIO) dans `v2/`. V1 en attente. |
| À venir | Phase 0 (#2), V4 programme de participation (#3), anti-sybil (#4), audit. |
