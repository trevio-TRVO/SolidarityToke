# BillPay Relay

Relais **lecture seule** pour BillPay Protocol ($BILL, Base) : API JSON publique + agent de publication (FR/EN/RU) avec file d'approbation humaine.

> Le relais **ne signe jamais, ne paie jamais, ne détient aucune clé privée**. Il n'utilise que `eth_call` et `eth_getLogs`.

## Démarrage

```bash
cd relay
npm install
cp .env.example .env   # renseigner les adresses de contrats ; ne jamais commiter .env
npm test && npm run typecheck
npm start              # API sur :8787 (charger .env via `node --env-file=.env` ou l'environnement)
```

## 1. API publique (`node:http`)

| Route | Contenu |
|---|---|
| `GET /api/stats` | offre totale, **brûlé** (offre initiale − offre actuelle), **circulant** (offre − soldes exclus : solidarité, ops, réserve de liquidité, AutoLiquidity, lots, paires, dead), liquidité USDC et ETH (réserves des paires), détenteurs **approximatifs**, demandes solidaires en attente |
| `GET /api/lots` | état des lots : lot pionnier, séries ouvertes (14 × 90 lots payants + 10 gratuits), disponibilité, calendrier, `lotTokens` (null tant que le TWAP n'a pas de prix) |
| `GET /api/health` | `{ ok: true }` |

Montants en chaînes décimales (wei / unités natives), pour éviter toute perte de précision. CORS (`CORS_ORIGIN`), `Cache-Control` + cache mémoire (`CACHE_TTL_SECONDS`), réponse périmée servie si le RPC échoue (`X-Cache-Stale`). Les erreurs ne révèlent jamais l'URL RPC.

Approximations : « détenteurs » = nombre d'adresses ayant déjà reçu des BILL (borne haute du nombre de détenteurs actuels), scanné progressivement depuis `DEPLOY_BLOCK` ; le brûlé suppose `INITIAL_SUPPLY` correct.

## 2. Publisher (équivalent d'un flux n8n, en code)

```bash
npm run publisher -- collect        # lit les évènements on-chain → brouillons FR/EN/RU (statut pending)
npm run publisher -- list
npm run publisher -- approve <id>   # approbation HUMAINE
npm run publisher -- reject <id>
npm run publisher -- flush          # envoie les brouillons approuvés
```

Évènements : lot vendu (`Purchased`), facture payée (`Paid`), jalons de burn (`BURN_MILESTONES`). Premier lancement : démarre à la tête de chaîne, pas de rattrapage.

**Garde-fous** (testés) :
- `DRY_RUN=true` par défaut : les posts sont seulement affichés.
- Publication réelle uniquement si `DRY_RUN=false` **et** `APPROVE=true` **et** le brouillon a été approuvé par un humain. Sans `APPROVE=true`, rien ne part, jamais.
- Canaux enfichables (`Channel`) : Telegram (`TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`) et X (`X_ACCESS_TOKEN`, ≤ 280 caractères). Secrets uniquement par variables d'environnement, masqués dans les erreurs.
- Textes déterministes (pas de LLM), adresses abrégées.

## 3. n8n

Importer `n8n/billpay-stats-approval.json` : planificateur → `GET /api/stats` → texte FR/EN/RU → **approbation humaine Telegram** (`sendAndWait`) → publication si approuvé **et** `APPROVE=true`. Variables n8n : `RELAY_API_URL`, `TELEGRAM_APPROVER_CHAT_ID`, `TELEGRAM_PUBLIC_CHAT_ID`, `APPROVE`. Les identifiants Telegram se configurent dans n8n (`REPLACE_ME` à remplacer).

---

## EN (short)
Read-only relay for BillPay Protocol: public JSON API (`/api/stats`, `/api/lots`, `/api/health`, CORS + caching) and a content publisher turning on-chain events (lot sold, bill paid, burn milestones) into FR/EN/RU drafts. Dry-run by default; nothing is ever posted without a human approving each draft **and** `APPROVE=true` (and `DRY_RUN=false`). Channels: Telegram, X. An importable n8n workflow with an approval step is in `n8n/`. No keys, no signing, no payments. Config via env (`.env.example`). Run `npm test && npm run typecheck`.

## RU (кратко)
Релей BillPay Protocol только для чтения: публичный JSON API (`/api/stats`, `/api/lots`, `/api/health`, CORS и кэш) и публикатор, превращающий ончейн-события (продажа лота, оплата счёта, рубежи сжигания) в черновики FR/EN/RU. По умолчанию dry-run; ничего не публикуется без одобрения человеком каждого черновика **и** `APPROVE=true` (и `DRY_RUN=false`). Каналы: Telegram, X. Импортируемый workflow n8n с шагом одобрения лежит в `n8n/`. Никаких ключей, подписей и платежей. Настройки через env (`.env.example`).
