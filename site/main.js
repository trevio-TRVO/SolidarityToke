import { initI18n } from "./i18n.js";
import { initWallet } from "./wallet.js";

initI18n();
initWallet();
if (document.getElementById("votes-list")) import("./app.js").then((m) => m.initApp());
if (document.getElementById("addr-form")) import("./wallets.js").then((x) => x.initWallets());
