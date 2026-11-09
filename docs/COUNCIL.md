# Conseil de la Solidarité : composition (10 sièges + fondateur)

Mandat **mensuel**. Le fondateur garde son poids de 3 ; le conseil compte 10 sièges de poids 1 ; seuil de validation : 5.

| # | Siège | Désignation |
|---|---|---|
| 1-3 | 3 membres pionniers | Choisis chaque mois (méthode à définir : tirage au sort parmi les acquéreurs de lots) |
| 4 | Meilleur influenceur | Vote sur la plateforme |
| 5 | Meilleur contributeur X | Classement du mois (engagement vérifié) |
| 6 | Meilleur contributeur Facebook | Idem |
| 7 | Meilleur contributeur TikTok | Idem |
| 8 | Meilleur trader du mois | Classement on-chain (volume net, hors wash trading) |
| 9 | Wallet la plus fournie en BILL | Lecture on-chain à la clôture du mois |
| 10 | Siège élu | Vote sur le site web |

## Points à trancher
- **Rotation : implémentée** (`contracts/CouncilRegistry.sol`). Le `SolidarityWallet` lit le conseil dans le registre (adresse immuable). Pas d'owner : la rotation est confirmée par un ensemble **fixe** de signataires d'élection (immutable), seuil M sur N. Chaque signataire confirme la même liste exacte de 10 adresses ; au M-ième appel `confirmRotation`, la liste s'applique. Au plus une rotation par 30 jours (la première, 30 jours après le déploiement), 10 adresses distinctes, non nulles, différentes du fondateur. Événements : `RotationConfirmed`, `CouncilRotated`.
- **Signataires d'élection (choix validé)** : un petit groupe indépendant du fondateur, seuil 3 sur 5 (variables `ELECTION_SIGNERS` / `ELECTION_THRESHOLD`).
- **Pourquoi pas un vote du conseil sortant** : une supermajorité du conseil pourrait se reconduire et verrouiller le pouvoir. Les signataires ne siègent pas et ne publient que le résultat des élections.
- **Effets de la rotation** : un membre retiré perd tout droit de vote ; ses approbations et votes d'annulation sur les demandes ouvertes ne comptent plus (poids recalculé à l'exécution). Le fondateur n'est jamais affecté.
- **Risque résiduel** : M signataires complices peuvent imposer un conseil, au plus une fois par mois ; l'ensemble des signataires ne change jamais (en cas de compromission, il faudrait un nouveau déploiement). À mitiger par des multisigs publics.
- **Résultats hors chaîne** (X, Facebook, TikTok, influenceur, vote web) : il faut un oracle ou un comité qui publie le résultat sur la chaîne. C'est un point de confiance à encadrer.
- **Wallet la plus fournie** : exclure la paire de liquidité, les contrats (lots, solidarityWallet), le fondateur et les adresses d'échange. Risque de rotation artificielle entre wallets avant la clôture : utiliser la moyenne du solde sur le mois.
- **Meilleur trader** : risque de wash trading ; calculer sur le PnL net ou le volume avec plafond.
- **Une personne, un siège** : un même acteur ne peut pas cumuler plusieurs sièges ; en cas de doublon, siège suivant au classement.
- **Conflits d'intérêts** : un membre ne vote pas sur sa propre demande ni sur celle d'un proche.
- **Réseaux sociaux** : identification par compte lié (OAuth) ; les métriques dépendent des API des plateformes.
