import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import { loadConfig } from "../src/config.js";

describe("config", () => {
  it("has sane defaults and validates addresses", () => {
    const c = loadConfig({});
    expect(c.chainId).toBe(8453);
    expect(c.initialSupply).toBe(1_000_000_000n * 10n ** 18n);
    expect(() => loadConfig({ TOKEN_ADDRESS: "0x123" })).toThrow();
  });
});

describe("n8n workflow", () => {
  const wf = JSON.parse(readFileSync(new URL("../n8n/billpay-stats-approval.json", import.meta.url), "utf8"));
  it("is importable JSON with an approval step before posting and no secrets", () => {
    const names = wf.nodes.map((n: { name: string }) => n.name);
    expect(names).toContain("Human approval (Telegram)");
    const toApproval = wf.connections["Compose FR/EN/RU"].main[0][0].node;
    expect(toApproval).toBe("Human approval (Telegram)");
    expect(JSON.stringify(wf)).not.toMatch(/\d{8,}:[A-Za-z0-9_-]{30,}/);
  });
});
