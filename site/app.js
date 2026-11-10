// Landing : chiffres lus via le relais (GET /api/stats, GET /api/votes). Repli « — » si indisponible.
import { CONFIG } from "./config.js";
import { t, getLang } from "./i18n.js";
import { state } from "./wallet.js";

const DASH = "—";
let stats = null;
let votes = [];

const num = (v, max = 0) => (v === null || v === undefined || v === "" || isNaN(Number(v)) ? DASH : new Intl.NumberFormat(getLang(), { maximumFractionDigits: max }).format(Number(v)));

async function getJson(path) {
  if (!CONFIG.API_URL) return null;
  try {
    const r = await fetch(CONFIG.API_URL.replace(/\/$/, "") + path, { headers: { accept: "application/json" } });
    return r.ok ? await r.json() : null;
  } catch (e) { return null; }
}

// Les montants du relais sont des chaînes en wei (18 décimales).
function fromWei(v) {
  if (v === null || v === undefined || v === "" || !/^\d+$/.test(String(v))) return v;
  const s = String(v).padStart(19, "0");
  return s.slice(0, -18) + "." + s.slice(-18);
}

function normStats(raw) {
  if (!raw) return {};
  const liq = raw.liquidity && raw.liquidity.eth;
  const h = raw.holders && typeof raw.holders === "object" ? raw.holders.everReceived : raw.holders;
  return {
    burned: fromWei(raw.burned),
    liquidityEth: raw.liquidityEth ?? (liq ? fromWei(liq.otherReserve) : undefined),
    circulating: fromWei(raw.circulating ?? raw.circulatingSupply),
    holders: h,
    solidarity: raw.solidarity
  };
}

function normVotes(raw) {
  const list = Array.isArray(raw) ? raw : raw && Array.isArray(raw.pendingProposals) ? raw.pendingProposals : [];
  return list.map((p) => ({
    id: p.id,
    title: p.title || t("vote_bill", { n: p.id }),
    forVotes: p.forVotes ?? fromWei(p.approvalWeight),
    againstVotes: p.againstVotes,
    spam: !!p.spam
  }));
}

function renderStats() {
  const s = stats || {};
  const set = (id, v) => { document.getElementById(id).textContent = v; };
  set("st-burned", num(s.burned));
  set("st-liq", num(s.liquidityEth, 4));
  set("st-supply", num(s.circulating));
  set("st-holders", num(s.holders));
  const f = s.solidarity || {};
  const inv = document.getElementById("fund-invoice");
  inv.textContent = f.invoice ? t("fund_invoice", { n: f.invoice }) : t("fund_invoice_none");
  const addr = f.address || "";
  document.getElementById("fund-p").textContent = t("fund_p", { a: addr ? addr.slice(0, 6) + "…" + addr.slice(-4) : t("fund_addr_none") });
  const pct = f.target > 0 && f.balance >= 0 ? Math.min(100, Math.round((f.balance / f.target) * 100)) : 0;
  const bar = document.getElementById("fund-bar");
  bar.style.width = pct + "%";
  const pb = bar.parentElement;
  if (f.target > 0) { pb.setAttribute("aria-valuenow", String(pct)); pb.removeAttribute("aria-valuetext"); }
  else { pb.removeAttribute("aria-valuenow"); pb.setAttribute("aria-valuetext", DASH); }
}

function renderVotes() {
  const box = document.getElementById("votes-list");
  box.textContent = "";
  const list = votes.length ? votes : [{ placeholder: true }, { placeholder: true }];
  const connected = !!state.account;
  list.forEach((v) => {
    const card = document.createElement("article");
    card.className = "glass vote";
    const h = document.createElement("h3");
    h.textContent = v.placeholder ? t("vote_placeholder") : v.title;
    const nums = document.createElement("p");
    nums.className = "muted";
    nums.textContent = t("vote_for") + " " + num(v.forVotes) + " · " + t("vote_against") + " " + num(v.againstVotes);
    const row = document.createElement("div");
    row.className = "row";
    [["vote_do_for", "pri"], ["vote_do_against", "ghost"]].forEach(([k, cls]) => {
      const b = document.createElement("button");
      b.type = "button";
      b.className = "btn " + cls;
      b.textContent = t(k);
      b.disabled = !connected || !!v.placeholder;
      b.addEventListener("click", () => { document.getElementById("vote-msg").textContent = t("vote_soon"); });
      row.appendChild(b);
    });
    card.append(h, nums, row);
    box.appendChild(card);
  });
  document.getElementById("vote-msg").textContent = connected ? "" : t("vote_need_wallet");
}

function renderLinks() {
  const a = CONFIG.CONTRACT_ADDRESS;
  const c = document.getElementById("foot-contract");
  c.textContent = "";
  if (a) {
    const link = document.createElement("a");
    link.href = CONFIG.EXPLORER_URL + "/address/" + a;
    link.rel = "noopener";
    link.textContent = a;
    c.append(link, " · " + t("foot_verified"));
  } else c.textContent = t("foot_addr_none");
  const buy = document.getElementById("cta-buy");
  buy.href = CONFIG.BUY_URL || "#contract";
  const g = document.getElementById("foot-group");
  g.href = CONFIG.GROUP_URL || "#";
  g.textContent = CONFIG.GROUP_URL ? t("foot_group") : t("foot_group_none");
  if (!CONFIG.GROUP_URL) g.setAttribute("aria-disabled", "true");
}

export async function initApp() {
  document.getElementById("foot-bot").href = CONFIG.BOT_URL;
  document.querySelectorAll("[data-github]").forEach((a) => { a.href = CONFIG.GITHUB_URL; });
  const renderAll = () => { renderStats(); renderVotes(); renderLinks(); };
  document.addEventListener("bp:lang", renderAll);
  document.addEventListener("bp:wallet", renderVotes);
  renderAll();
  const raw = await getJson("/api/stats");
  stats = normStats(raw);
  votes = normVotes(raw);
  renderAll();
}
