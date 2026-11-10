// Configuration publique du site. Aucune clé, aucun secret ici : tout ce fichier est lisible par tous.
export const CONFIG = {
  SITE_URL: "https://trevio-trvo.github.io/billpay-protocol/",
  // Relay (lecture seule). Le site appelle GET {API_URL}/api/stats et GET {API_URL}/api/votes.
  // Vide : les chiffres restent affichés « — ».
  // /api/stats attendu : { burned, liquidityEth, circulating, holders, solidarity: { invoice, balance, target, address } }
  // /api/votes attendu : [ { id, title, forVotes, againstVotes } ]
  API_URL: "",
  // Proxy serveur pour l'API Safe Transaction Service (la clé SAFE_API_KEY reste côté serveur, jamais ici).
  // Vide : la lecture Safe de wallets.html est désactivée. Voir relay/README.md.
  SAFE_PROXY_URL: "",
  // Adresse du contrat BillPayProtocol sur Base (vide tant que non déployé).
  CONTRACT_ADDRESS: "",
  // Lien d'achat de $BILL (vide tant que la pool n'existe pas).
  BUY_URL: "",
  EXPLORER_URL: "https://basescan.org",
  GITHUB_URL: "https://github.com/trevio-TRVO/billpay-protocol",
  BOT_URL: "https://t.me/Billpayprotocolbot",
  GROUP_URL: "", // lien du groupe Telegram : à renseigner
  CHAIN_ID: "0x2105" // Base
};
