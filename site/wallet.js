// Connexion wallet : EIP-6963 (découverte) + EIP-1193 (requêtes). Aucune clé, aucun stockage, aucune dépendance.
import { CONFIG } from "./config.js";
import { t } from "./i18n.js";

const BASE = {
  chainId: CONFIG.CHAIN_ID,
  chainName: "Base",
  nativeCurrency: { name: "Ether", symbol: "ETH", decimals: 18 },
  rpcUrls: ["https://mainnet.base.org"],
  blockExplorerUrls: ["https://basescan.org"]
};

export const state = { provider: null, name: "", account: null, chainId: null, err: "", busy: false };
const found = new Map();
let bound = null;

export const shortAddr = (a) => (a ? a.slice(0, 6) + "…" + a.slice(-4) : "");
const emit = () => document.dispatchEvent(new CustomEvent("bp:wallet", { detail: state }));

function discover() {
  window.addEventListener("eip6963:announceProvider", (e) => {
    const d = e.detail;
    if (d && d.info && d.provider) found.set(d.info.uuid, d);
  });
  window.dispatchEvent(new Event("eip6963:requestProvider"));
}

function choose() {
  const list = [...found.values()];
  if (list.length === 0) return Promise.resolve(window.ethereum ? { provider: window.ethereum, info: { name: "Wallet" } } : null);
  if (list.length === 1) return Promise.resolve(list[0]);
  return new Promise((resolve) => {
    const dlg = document.createElement("dialog");
    dlg.className = "picker";
    dlg.setAttribute("aria-label", t("w_pick"));
    const h = document.createElement("h2");
    h.textContent = t("w_pick");
    dlg.appendChild(h);
    list.forEach((d) => {
      const b = document.createElement("button");
      b.type = "button";
      b.className = "btn ghost";
      if (d.info.icon && /^data:image\//.test(d.info.icon)) {
        const im = document.createElement("img");
        im.src = d.info.icon; im.alt = ""; im.width = 24; im.height = 24;
        b.appendChild(im);
      }
      b.appendChild(document.createTextNode(d.info.name));
      b.addEventListener("click", () => { dlg.close("ok"); resolve(d); });
      dlg.appendChild(b);
    });
    const c = document.createElement("button");
    c.type = "button"; c.className = "btn"; c.textContent = t("w_cancel");
    c.addEventListener("click", () => dlg.close());
    dlg.appendChild(c);
    dlg.addEventListener("close", () => { dlg.remove(); resolve(null); });
    document.body.appendChild(dlg);
    dlg.showModal();
  });
}

function fail(e, key) {
  state.err = e && e.code === 4001 ? "w_rejected" : key;
  state.busy = false;
  emit();
}

function onAccounts(accs) {
  state.account = accs && accs.length ? accs[0] : null;
  if (!state.account) state.provider = null;
  emit();
}

export async function connect() {
  state.err = "";
  state.busy = true;
  emit();
  const d = await choose();
  if (!d) {
    state.busy = false;
    state.err = found.size || window.ethereum ? "" : "w_none";
    emit();
    return;
  }
  try {
    const p = d.provider;
    const accs = await p.request({ method: "eth_requestAccounts" });
    state.provider = p;
    state.name = d.info.name;
    state.chainId = await p.request({ method: "eth_chainId" });
    if (bound !== p && p.on) {
      bound = p;
      p.on("accountsChanged", onAccounts);
      p.on("chainChanged", (c) => { state.chainId = c; emit(); });
    }
    state.busy = false;
    onAccounts(accs);
  } catch (e) { fail(e, "w_error"); }
}

export function disconnect() {
  state.account = null; state.provider = null; state.err = "";
  emit();
}

export async function switchToBase() {
  state.err = "";
  try {
    try {
      await state.provider.request({ method: "wallet_switchEthereumChain", params: [{ chainId: BASE.chainId }] });
    } catch (e) {
      if (e && e.code === 4902) await state.provider.request({ method: "wallet_addEthereumChain", params: [BASE] });
      else throw e;
    }
  } catch (e) { fail(e, "w_error"); }
}

export const onBase = () => state.chainId && state.chainId.toLowerCase() === BASE.chainId;

// Branche le bouton d'en-tête et le message d'état.
export function initWallet() {
  discover();
  const btn = document.getElementById("wallet-btn");
  const sw = document.getElementById("wallet-switch");
  const st = document.getElementById("wallet-status");
  if (!btn) return;
  const render = () => {
    btn.disabled = state.busy;
    btn.textContent = "";
    if (state.account) {
      btn.textContent = shortAddr(state.account);
      btn.title = state.account + " · " + t("w_disconnect");
      btn.setAttribute("aria-label", shortAddr(state.account) + " — " + t("w_disconnect"));
    } else {
      btn.textContent = state.busy ? t("w_connecting") : t("w_connect");
      btn.removeAttribute("title");
      btn.removeAttribute("aria-label");
    }
    sw.hidden = !(state.account && !onBase());
    sw.textContent = t("w_switch");
    let msg = "";
    if (state.err) msg = t(state.err);
    else if (state.account && !onBase()) msg = t("w_wrong");
    st.textContent = msg;
    st.className = "status" + (msg ? " err" : "");
  };
  btn.addEventListener("click", () => (state.account ? disconnect() : connect()));
  sw.addEventListener("click", switchToBase);
  document.addEventListener("bp:wallet", render);
  document.addEventListener("bp:lang", render);
  render();
}
