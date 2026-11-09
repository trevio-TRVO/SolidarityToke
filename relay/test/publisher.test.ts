import { mkdtemp, readFile, rm } from "node:fs/promises";
import { join } from "node:path";
import { describe, expect, it } from "vitest";
import { TelegramChannel, XChannel, channelsFromEnv, type Channel } from "../src/publisher/channels.js";
import { collect, flush, optionsFromEnv, type PublisherOptions } from "../src/publisher/publisher.js";
import { Queue } from "../src/publisher/queue.js";
import { render } from "../src/publisher/templates.js";
import { A, cfg, fakeClient, k, LOTS, SOL, type FakeState } from "./helpers.js";

const E = 10n ** 18n;
const mem = () => new Queue("/nonexistent/never-saved.json");
const noSave = (q: Queue) => { q.save = async () => {}; return q; };

function recorder(langs: ("fr" | "en" | "ru")[] = ["fr", "en", "ru"]) {
  const sent: string[] = [];
  const ch: Channel = { name: "rec", langs, send: async (t, l) => void sent.push(`${l}:${t}`) };
  return { ch, sent };
}
const opts = (o: Partial<PublisherOptions>): PublisherOptions => ({ dryRun: true, approve: false, milestones: [], channels: [], log: () => {}, ...o });

describe("templates", () => {
  it("renders FR/EN/RU for every event kind with shortened addresses", () => {
    const evs = [
      { kind: "lot_sold", key: "a", block: 1n, buyer: A(0xabcdef), pioneer: true, priceUsdc: 10_000_000n },
      { kind: "bill_paid", key: "b", block: 1n, requestId: 4n, payee: A(5), amount: 12345n * E },
      { kind: "burn_milestone", key: "c", block: 1n, milestone: 1_000_000n * E, burned: 1_000_001n * E },
    ] as const;
    for (const e of evs) {
      const p = render(e);
      expect(p.fr).toMatch(/[éèà]|BILL/);
      expect(p.ru).toMatch(/[а-я]/);
      expect(p.en.length).toBeLessThanOrEqual(280);
    }
    expect(render(evs[0]).en).toContain("0x0000…cdef");
    expect(render(evs[0]).en).not.toContain(A(0xabcdef));
    expect(render(evs[1]).fr).toContain("12\u202f345 BILL");
  });
});

describe("queue + flush gating", () => {
  const ev = { kind: "bill_paid", key: "paid:1", block: 1n, requestId: 1n, payee: A(1), amount: E } as const;

  it("enqueue is idempotent and starts pending", () => {
    const q = mem();
    expect(q.enqueue(ev)?.status).toBe("pending");
    expect(q.enqueue(ev)).toBeNull();
  });

  it("never posts pending items, even with approve=true and dryRun=false", async () => {
    const q = noSave(mem()); q.enqueue(ev);
    const { ch, sent } = recorder();
    await flush(q, opts({ approve: true, dryRun: false, channels: [ch] }));
    expect(sent).toHaveLength(0);
  });

  it("never posts approved items without APPROVE=true", async () => {
    const q = noSave(mem()); q.enqueue(ev); q.decide("paid:1", "approved");
    const { ch, sent } = recorder();
    const r = await flush(q, opts({ approve: false, dryRun: false, channels: [ch] }));
    expect(sent).toHaveLength(0);
    expect(r.skipped).toMatch(/APPROVE/);
  });

  it("dry-run logs only and keeps the item approved", async () => {
    const q = noSave(mem()); q.enqueue(ev); q.decide("paid:1", "approved");
    const { ch, sent } = recorder();
    const logs: string[] = [];
    await flush(q, opts({ approve: true, dryRun: true, channels: [ch], log: (s) => logs.push(s) }));
    expect(sent).toHaveLength(0);
    expect(logs).toHaveLength(3);
    expect(q.list("approved")).toHaveLength(1);
  });

  it("posts per channel language and marks posted; rejected items are ignored", async () => {
    const q = noSave(mem()); q.enqueue(ev); q.enqueue({ ...ev, key: "paid:2" });
    q.decide("paid:1", "approved"); q.decide("paid:2", "rejected");
    const { ch, sent } = recorder(["en", "ru"]);
    await flush(q, opts({ approve: true, dryRun: false, channels: [ch] }));
    expect(sent.map((s) => s.slice(0, 2))).toEqual(["en", "ru"]);
    expect(q.list("posted")).toHaveLength(1);
    expect(() => q.decide("paid:1", "rejected")).toThrow();
  });

  it("failed sends stay approved for retry", async () => {
    const q = noSave(mem()); q.enqueue(ev); q.decide("paid:1", "approved");
    const ch: Channel = { name: "bad", langs: ["en"], send: async () => { throw new Error("nope"); } };
    await flush(q, opts({ approve: true, dryRun: false, channels: [ch] }));
    expect(q.list("approved")).toHaveLength(1);
  });

  it("persists state to disk", async () => {
    const dir = await mkdtemp(join(process.cwd(), "test-state-"));
    const f = join(dir, "s", "state.json");
    const q = new Queue(f); q.enqueue(ev); await q.save();
    expect((await Queue.load(f)).list()).toHaveLength(1);
    expect(JSON.parse(await readFile(f, "utf8")).items[0].status).toBe("pending");
    await rm(dir, { recursive: true });
  });

  it("defaults are safe", () => {
    const o = optionsFromEnv({}, []);
    expect(o.dryRun).toBe(true);
    expect(o.approve).toBe(false);
    expect(optionsFromEnv({ DRY_RUN: "false", APPROVE: "true" }, [])).toMatchObject({ dryRun: false, approve: true });
  });
});

describe("collect", () => {
  it("starts at head, then queues lot, payment and burn milestone events once", async () => {
    const st: FakeState = { head: 100n, values: {}, calls: [], logs: {} };
    const q = noSave(mem());
    const client = fakeClient(st);
    const o = { milestones: [10n, 1000n] };
    const stats = async () => ({ burned: (50n * E).toString() });
    expect(await collect(client, cfg, q, stats, o)).toBe(0); // first run: silent baseline
    expect(q.state.milestonesDone).toEqual([(10n * E).toString()]);

    st.head = 110n;
    st.logs[k(LOTS, "Purchased")] = [{ args: { buyer: A(9), pioneer: false, price: 50_000_000n }, blockNumber: 105n, logIndex: 1, transactionHash: "0xaa" }];
    st.logs[k(SOL, "Paid")] = [{ args: { id: 3n, payee: A(8), amount: 7n * E }, blockNumber: 106n, logIndex: 0, transactionHash: "0xbb" }];
    const stats2 = async () => ({ burned: (1500n * E).toString() });
    expect(await collect(client, cfg, q, stats2, o)).toBe(3);
    expect(q.list().map((i) => i.kind).sort()).toEqual(["bill_paid", "burn_milestone", "lot_sold"]);
    expect(await collect(client, cfg, q, stats2, o)).toBe(0);
    expect(q.state.cursor).toBe("110");
  });
});

describe("channels", () => {
  it("telegram posts to the bot API and redacts the token on error", async () => {
    let url = "";
    const ok = new TelegramChannel("TOKEN123", "42", ["fr"], (async (u: string) => { url = u; return new Response("{}"); }) as never);
    await ok.send("hi");
    expect(url).toBe("https://api.telegram.org/botTOKEN123/sendMessage");
    const bad = new TelegramChannel("TOKEN123", "42", ["fr"], (async () => { throw new Error("fetch failed https://api.telegram.org/botTOKEN123/x"); }) as never);
    await expect(bad.send("hi")).rejects.toThrow(/\*\*\*/);
    await expect(bad.send("hi")).rejects.not.toThrow(/TOKEN123/);
  });

  it("x enforces 280 chars", async () => {
    const x = new XChannel("t", ["en"], (async () => new Response("{}")) as never);
    await expect(x.send("a".repeat(281))).rejects.toThrow(/280/);
    await expect(x.send("ok")).resolves.toBeUndefined();
  });

  it("builds channels from env only when configured", () => {
    expect(channelsFromEnv({})).toHaveLength(0);
    expect(channelsFromEnv({ TELEGRAM_BOT_TOKEN: "a", TELEGRAM_CHAT_ID: "b", X_ACCESS_TOKEN: "c", X_LANGS: "fr,en" }).map((c) => c.name)).toEqual(["telegram", "x"]);
  });
});
