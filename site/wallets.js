// Page « Wallets & coffre-fort » : validation de format locale + lecture Safe via SAFE_PROXY_URL (aucune clé ici).
import { CONFIG } from "./config.js";
import { t } from "./i18n.js";

const ADDR = /^0x[0-9a-fA-F]{40}$/;
let last = { addr: "", kind: "" };

async function readSafe(addr) {
  const msg = document.getElementById("safe-msg");
  if (!CONFIG.SAFE_PROXY_URL) { last.kind = "off"; msg.textContent = t("wl_safe_off"); return; }
  try {
    const r = await fetch(CONFIG.SAFE_PROXY_URL.replace(/\/$/, "") + "/api/v1/safes/" + addr + "/", { headers: { accept: "application/json" } });
    if (r.status === 404) { last.kind = "none"; msg.textContent = t("wl_safe_none"); return; }
    if (!r.ok) throw new Error("http");
    const s = await r.json();
    last.kind = "info"; last.o = (s.owners || []).length; last.t = s.threshold;
    msg.textContent = t("wl_safe_info", { t: s.threshold, o: (s.owners || []).length });
  } catch (e) { last.kind = "err"; msg.textContent = t("wl_safe_err"); }
}

export function initWallets() {
  const form = document.getElementById("addr-form");
  const input = document.getElementById("addr");
  const msg = document.getElementById("addr-msg");
  document.getElementById("bot-link").href = CONFIG.BOT_URL;
  const show = (key) => { msg.dataset.k = key; msg.textContent = t(key); msg.className = "status" + (key === "wl_invalid" ? " err" : ""); };
  form.addEventListener("submit", (e) => {
    e.preventDefault();
    const a = input.value.trim();
    document.getElementById("safe-msg").textContent = "";
    if (!ADDR.test(a)) { last = { addr: "", kind: "" }; show("wl_invalid"); return; }
    last = { addr: a, kind: "" };
    show("wl_valid");
    readSafe(a);
  });
  document.addEventListener("bp:lang", () => {
    if (msg.dataset.k) msg.textContent = t(msg.dataset.k);
    const sm = document.getElementById("safe-msg");
    if (last.kind === "off") sm.textContent = t("wl_safe_off");
    else if (last.kind === "none") sm.textContent = t("wl_safe_none");
    else if (last.kind === "err") sm.textContent = t("wl_safe_err");
    else if (last.kind === "info") sm.textContent = t("wl_safe_info", { t: last.t, o: last.o });
  });
}
