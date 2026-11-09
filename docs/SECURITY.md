# Revue de sécurité — durcissement V3

Périmètre : AutoLiquidity, CommunityLots, CouncilRegistry, SolidarityWallet, script DeployV3.

| # | Contrat | Constat | Correctif |
|---|---------|---------|-----------|
| 1 | AutoLiquidity | Le stock de réserve prélevé pour l'ajout de liquidité mais non consommé par le routeur n'était pas restitué ; il était revendu comme « récolte » au cycle suivant. | Suivi de `fromStock` ; la part non consommée retourne dans `stockLeft` (plafonnée à ce qui venait du stock). |
| 2 | CommunityLots | `MAX_LOT_TOKENS` à 10 M BILL : un effondrement du prix permettait de livrer des lots disproportionnés. | Plafond ramené à 1 M BILL (100 USDC au prix de lancement 0,0001). |
| 3 | CommunityLots | Fenêtre TWAP minimale de 1 h : manipulation peu coûteuse. | `MIN_TWAP_WINDOW` = 24 h. |
| 4 | CouncilRegistry | Un signataire d'élection pouvait siéger au conseil (conflit d'intérêts). | `_validate` rejette `isElectionSigner[m]` (fonction désormais `view`). |
| 5 | SolidarityWallet | Le bénéficiaire (council) pouvait approuver sa propre demande. | `require(msg.sender != r.payee)` dans l'approbation. |
| 6 | SolidarityWallet | Le plafond par paiement (`MAX_BPS_PER_PAYMENT`) n'était pas revérifié à l'exécution, le solde pouvant avoir baissé. | Contrôle `above cap` à l'exécution. |
| 7 | DeployV3 | `msg.sender` du script ≠ émetteur réel des transactions (`--account`/`--ledger`) : adresses CREATE prédites fausses. | Déployeur lu via `vm.readCallers()` sous broadcast. |

Revue : aucun problème bloquant détecté dans le diff. Remarque : la restitution du stock (1) ne couvre que la part issue du stock, par conception.

Tests : 56 tests passent (`forge test --no-match-path "script/*"`), dont de nouveaux tests pour CommunityLots et SolidarityWallet.
