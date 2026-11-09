# Site web SolidarityToken : besoin

Le site est le **premier projet communautaire**. Public, réseau Base.

## Utilisateurs
Visiteur · Demandeur · Acquéreur de lot (validateur) · Membre du conseil · Fondateur

## Pages
1. **Accueil / Tableau de bord** : Compteur d'Impact (solde du `solidarityWallet`, en temps réel), total versé, nombre de familles aidées, prochaine distribution (compte à rebours 24 h).
2. **Espace Demandeurs** : connexion wallet, formulaire (montant, fournisseur, urgence, description sans collage), téléversement de la facture avec masquage des données privées.
3. **Tribunal Solidaire** : cartes anonymes, OUI/NON (connexion Google ou équivalent), statut (validations 0/5, approbations du conseil, délai de 24 h).
4. **Espace Validateurs** : réservé aux acquéreurs de lots, validation sur chaîne.
5. **Conseil** : composition du mois, classements (influenceur, X, Facebook, TikTok, trader, top wallet), vote du siège élu.
6. **Lots** : séries, prix, quantité restante, achat d'un lot (1 par wallet), calendrier de vesting (cliff 45 j, linéaire 30 j), `claim`.
7. **Transparence** : historique des paiements, journal du projet, liens vers les contrats et le code.

## Exigences fonctionnelles
- Connexion wallet (Base) et connexion Google pour le vote.
- Contrôle IA des demandes (signale, ne paie pas) avant publication.
- Données privées jamais publiées ni sur la chaîne : seule l'empreinte du dossier l'est.
- Champ description sans collage (frein côté navigateur).
- Notifications du statut d'une demande.
- Français d'abord ; anglais et turc ensuite (l'exemple mentionnait Euro/Lira).

## Exigences non fonctionnelles
- Mobile d'abord, lisible, très visuel.
- Chiffrement des factures au repos, durée de conservation limitée, conformité RGPD (suppression sur demande).
- Anti-bots, limitation de débit, journal d'audit.
- Aucune clé privée côté serveur.

## Stack proposée
Next.js + TypeScript, wagmi/viem (Base), Auth Google (OAuth), stockage chiffré des factures, base PostgreSQL pour les votes, indexation des événements des contrats.

## Étapes
1. Maquette (`site/index.html`) validée.
2. Lecture on-chain (compteur d'impact, lots).
3. Espace Demandeurs et Tribunal.
4. Espace Validateurs et Conseil.
5. Audit de sécurité, puis ouverture.
