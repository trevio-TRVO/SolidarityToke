# SolidarityToken (SLDR) V3

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

Vocabulaire : on parle de **contribution solidaire** ou de **prélèvement réparti**, jamais de « taxe ». Le point le plus important est l'aide directe : paiement direct de factures pour des personnes en urgence.

## Distribution communautaire (15 % de l'offre)

Spécification complète : [docs/V3_COMMUNITY_DISTRIBUTION.md](docs/V3_COMMUNITY_DISTRIBUTION.md). Contrat : `contracts/CommunityLots.sol`.

## Journal de bord

| Date | Entrée |
|---|---|
| 2026-11-09 | Spécification de la distribution communautaire V3 : séries de 100 lots (90 payants, 10 gratuits), prix max ×2 par série, quantité non croissante (rareté), 1 achat par wallet, cliff 45 j puis linéaire 30 j. |
| 2026-11-09 | Contrat `CommunityLots.sol` écrit (sans owner, paramètres immuables, pool plafonné) et compilé. PR #5. |
| 2026-11-09 | Intégration de la règle d'or au README. Point ouvert : la contribution de 10 % s'applique-t-elle aux `claim()` du contrat de lots ? Le contrat doit être exempté, sinon les bénéficiaires reçoivent moins que leur lot (issue #4). |
| À venir | Tests Foundry (#1), Phase 0 (#2), V4 programme de participation (#3). |
