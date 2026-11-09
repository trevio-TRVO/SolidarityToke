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

- **Au lancement : 100 lots pionniers uniquement** (1 %), 10 USDC le lot, 100 000 BILL fixes.
- **Séries suivantes** (90 payants + 10 gratuits, une série tous les 30 jours) : elles s'ouvrent seulement quand le prix a décollé (x10 du prix de lancement, via `openSeries()`).
- **Lot payant : 50 USDC pour 100 USDC de BILL au cours du marché** (le double de la mise, jamais plus). La quantité diminue quand le prix monte (rareté). Exemple : BILL à 1 USDC, 50 USDC = 100 BILL.
- Un lot par wallet. Vesting de chaque lot : blocage 45 jours, puis déblocage linéaire sur 30 jours. Lots invendus conservés dans le contrat.
- **Liquidité** : 500 000 BILL + 50 USDC au lancement ; 499,5 M BILL en réserve injectés progressivement par `AutoLiquidity` (voir [docs/DEPLOY_V3.md](docs/DEPLOY_V3.md)).

## Aide directe : site web et vote communautaire

Spécification : [docs/SOLIDARITY_DASHBOARD.md](docs/SOLIDARITY_DASHBOARD.md) (tableau de bord sur Base, espace demandeurs, vote public par identification, distribution toutes les 24 h, limite de vente de 1 % sur les plateformes de trading uniquement).

## Conseil et site web

- [docs/COUNCIL.md](docs/COUNCIL.md) : composition mensuelle du conseil.
- [docs/SITE_REQUIREMENTS.md](docs/SITE_REQUIREMENTS.md) : besoin du site.
- `site/index.html` : maquette statique.

## Historique des versions

- V1 : abandonné.
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
| 2026-11-09 | Rotation du conseil (issue #12) : `CouncilRegistry.sol` (10 sièges, sans owner, rotation au plus tous les 30 jours confirmée par M signataires d'élection fixes), `SolidarityWallet` lit le conseil dans le registre ; un membre retiré perd ses droits et ses approbations ne comptent plus. Tests et script de déploiement mis à jour. |
| 2026-11-09 | Nommage validé : contrat `BillPayProtocol`, ticker `BILL`, dépôt `billpay-protocol`, interface « BillPay Hub / BillPay DAO », site sur GitHub Pages. Le renommage du dépôt actuel (`SolidarityToke`) reste à faire par le propriétaire (droits insuffisants). |
| 2026-11-09 | Token `BillPayProtocol.sol` (7 tests), script `DeployV3.s.sol`, guide de déploiement. Suit le modèle V2. Anti-crash non spécifié. |
| 2026-11-09 | Répartition fixée : 50 % liquidité, 20 % fondateur (vesting), 15 % lots communautaires, 15 % croissance (vesting). Script de déploiement unique avec adresses prédites, simulé sans erreur. |
| 2026-11-09 | Protection de lancement 7 jours (0,1 % par vente, 0,2 % par wallet et par jour), contrat `AutoLiquidity`, pool V2 uniquement, vesting fondateur proposé 90 j + 36 mois. 30 tests. |
| 2026-11-09 | Vesting fondateur validé : 90 jours puis 36 mois linéaires. |
| 2026-11-09 | Lots refaits : 100 pionniers (1 %, 10 USDC) + 14 séries de 100 (90 payants à 50 % du prix de marché via TWAP, 10 gratuits), une série par 30 jours. Croissance : 48 mois mensuels (`MonthlyVesting`). Paire BILL/USDC. V1 abandonné. 37 tests. |
| 2026-11-09 | Liquidité de lancement : 500 000 BILL + 50 USDC ; 499,5 M BILL en réserve `AutoLiquidity`, injectés au fil des récoltes de la contribution de 1 %. Lots : seul le pionnier est fixe, les autres livrent exactement x2 au cours TWAP (quantité variable), invendus conservés. 47 tests. |
| 2026-11-09 | PR #5 fusionnée. Archivage du code V2 (TREVIO) dans `v2/`. V1 en attente. |
| 2026-11-09 | Prix des lots : pionnier 10 USDC (100 000 BILL fixes) ; lots suivants 50 USDC pour 100 USDC de BILL au cours TWAP (x2). |
| 2026-11-09 | Au lancement : 100 pionniers uniquement. Les séries à 50 USDC s'ouvrent via `openSeries()` quand le TWAP atteint x10 (0,001 USDC/BILL). 49 tests. |
| À venir | Phase 0 (#2), V4 programme de participation (#3), anti-sybil (#4), audit. |
