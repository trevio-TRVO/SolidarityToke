import type { AddressInfo } from "node:net";
import { afterEach, describe, expect, it } from "vitest";
import { createApiServer } from "../src/server.js";

let close: () => void = () => {};
afterEach(() => close());

async function start(api: Parameters<typeof createApiServer>[0], now = () => 0) {
  const srv = createApiServer(api, { corsOrigin: "https://billpay.example", cacheTtlMs: 30_000 }, now);
  await new Promise<void>((r) => srv.listen(0, r));
  close = () => srv.close();
  return `http://127.0.0.1:${(srv.address() as AddressInfo).port}`;
}

describe("API", () => {
  it("serves health, stats, lots with CORS and cache headers", async () => {
    let n = 0;
    const base = await start({ stats: async () => ({ n: ++n }), lots: async () => ({ lots: true }) });
    const h = await fetch(`${base}/api/health`);
    expect(h.status).toBe(200);
    expect(h.headers.get("access-control-allow-origin")).toBe("https://billpay.example");
    const s = await fetch(`${base}/api/stats`);
    expect(s.headers.get("cache-control")).toContain("max-age=30");
    expect(await s.json()).toEqual({ n: 1 });
    expect(await (await fetch(`${base}/api/stats`)).json()).toEqual({ n: 1 }); // cached
    expect(await (await fetch(`${base}/api/lots`)).json()).toEqual({ lots: true });
  });

  it("handles OPTIONS, 404, 405", async () => {
    const base = await start({ stats: async () => 1, lots: async () => 1 });
    expect((await fetch(`${base}/api/stats`, { method: "OPTIONS" })).status).toBe(204);
    expect((await fetch(`${base}/nope`)).status).toBe(404);
    expect((await fetch(`${base}/api/stats`, { method: "POST" })).status).toBe(405);
  });

  it("serves stale data on upstream failure and hides errors otherwise", async () => {
    let t = 0, fail = false;
    const base = await start({ stats: async () => { if (fail) throw new Error("rpc http://secret-rpc"); return { ok: 1 }; }, lots: async () => { throw new Error("boom http://secret-rpc"); } }, () => t);
    await fetch(`${base}/api/stats`);
    t = 60_000; fail = true;
    const s = await fetch(`${base}/api/stats`);
    expect(s.status).toBe(200);
    expect(s.headers.get("x-cache-stale")).toBe("true");
    const l = await fetch(`${base}/api/lots`);
    expect(l.status).toBe(502);
    expect(await l.text()).not.toContain("secret");
  });
});
