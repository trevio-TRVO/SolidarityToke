import { createServer, type Server } from "node:http";
import { pathToFileURL } from "node:url";
import { createReadClient } from "./client.js";
import { loadConfig, type Config } from "./config.js";
import { StatsReader } from "./reader.js";

export interface Api {
  stats(): Promise<unknown>;
  lots(): Promise<unknown>;
}

interface Entry {
  at: number;
  value: unknown;
}

/** TTL cache that serves the last good value if the RPC fails (stale-if-error). */
export class TtlCache {
  private entries = new Map<string, Entry>();
  private inflight = new Map<string, Promise<unknown>>();
  constructor(
    private ttlMs: number,
    private now: () => number = Date.now,
  ) {}

  async get<T>(key: string, load: () => Promise<T>): Promise<{ value: T; stale: boolean; ageMs: number }> {
    const hit = this.entries.get(key);
    if (hit && this.now() - hit.at < this.ttlMs) return { value: hit.value as T, stale: false, ageMs: this.now() - hit.at };
    let p = this.inflight.get(key) as Promise<T> | undefined;
    if (!p) {
      p = load().finally(() => this.inflight.delete(key));
      this.inflight.set(key, p);
    }
    try {
      const value = await p;
      this.entries.set(key, { at: this.now(), value });
      return { value, stale: false, ageMs: 0 };
    } catch (err) {
      if (hit) return { value: hit.value as T, stale: true, ageMs: this.now() - hit.at };
      throw err;
    }
  }
}

export function createApiServer(api: Api, cfg: Pick<Config, "corsOrigin" | "cacheTtlMs">, now: () => number = Date.now): Server {
  const cache = new TtlCache(cfg.cacheTtlMs, now);
  const maxAge = Math.floor(cfg.cacheTtlMs / 1000);
  return createServer(async (req, res) => {
    const headers: Record<string, string> = {
      "Access-Control-Allow-Origin": cfg.corsOrigin,
      "Access-Control-Allow-Methods": "GET, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type",
      Vary: "Origin",
      "X-Content-Type-Options": "nosniff",
    };
    const send = (status: number, body: unknown, extra: Record<string, string> = {}) => {
      res.writeHead(status, { "Content-Type": "application/json; charset=utf-8", ...headers, ...extra });
      res.end(JSON.stringify(body));
    };
    if (req.method === "OPTIONS") {
      res.writeHead(204, { ...headers, "Access-Control-Max-Age": "86400" });
      res.end();
      return;
    }
    if (req.method !== "GET" && req.method !== "HEAD") return send(405, { error: "method not allowed" }, { Allow: "GET, OPTIONS" });
    const path = new URL(req.url ?? "/", "http://localhost").pathname;
    try {
      if (path === "/api/health") return send(200, { ok: true, time: new Date(now()).toISOString() }, { "Cache-Control": "no-store" });
      const loaders: Record<string, () => Promise<unknown>> = { "/api/stats": () => api.stats(), "/api/lots": () => api.lots() };
      const load = loaders[path];
      if (!load) return send(404, { error: "not found" });
      const r = await cache.get(path, load);
      send(200, r.value, {
        "Cache-Control": `public, max-age=${maxAge}, stale-while-error=300`,
        "X-Cache-Stale": String(r.stale),
      });
    } catch {
      // Never leak RPC URLs or internals.
      send(502, { error: "upstream unavailable" }, { "Cache-Control": "no-store" });
    }
  });
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const cfg = loadConfig();
  const reader = new StatsReader(createReadClient(cfg.rpcUrl), cfg);
  const server = createApiServer({ stats: () => reader.stats(), lots: () => reader.lots() }, cfg);
  server.listen(cfg.port, () => console.log(`billpay-relay API on :${cfg.port}`));
}
