import { describe, expect, it } from "vitest";
import { StatsReader } from "../src/reader.js";
import { A, cfg, fakeClient, k, LIQ, LOTS, OPS, PAIR, SOL, TOKEN, USDC, WETH, WPAIR, type FakeState } from "./helpers.js";

const E = 10n ** 18n;

function base(): FakeState {
  const v: Record<string, unknown> = {
    [k(TOKEN, "totalSupply")]: 900n * E,
    [k(TOKEN, "operationsWallet")]: OPS,
    [k(TOKEN, "liquidityReserve")]: LIQ,
    [k(PAIR, "token0")]: USDC,
    [k(PAIR, "token1")]: TOKEN,
    [k(PAIR, "getReserves")]: [5_000_000n, 300n * E, 0],
    [k(WPAIR, "token0")]: TOKEN,
    [k(WPAIR, "token1")]: WETH,
    [k(WPAIR, "getReserves")]: [100n * E, 2n * E, 0],
    [k(SOL, "requestCount")]: 3n,
    [k(SOL, "requests(0)")]: [A(1), 5n, "0x0", 0n, 0, 3],
    [k(SOL, "requests(1)")]: [A(2), 7n * E, "0x0", 1n, 5, 1],
    [k(SOL, "requests(2)")]: [A(3), 1n, "0x0", 0n, 2, 1],
    [k(SOL, "approvalWeight(1)")]: 4n,
    [k(SOL, "approvalWeight(2)")]: 0n,
    [k(LOTS, "seriesStart")]: 1000n,
    [k(LOTS, "openedSeries")]: 2n,
    [k(LOTS, "availablePaidLots")]: 150n,
    [k(LOTS, "pioneerSold")]: 40n,
    [k(LOTS, "paidSold")]: 30n,
    [k(LOTS, "outstanding")]: 9n,
    [k(LOTS, "lotTokens")]: 100_000n * E,
  };
  for (const a of ["0x000000000000000000000000000000000000dead", PAIR, WPAIR, LOTS, SOL, OPS, LIQ]) v[k(TOKEN, `balanceOf(${a.toLowerCase()})`)] = 10n * E;
  return {
    head: 250n, values: v, calls: [],
    logs: {
      [k(TOKEN, "Transfer")]: [
        { args: { from: A(0), to: A(7) }, blockNumber: 5n, logIndex: 0, transactionHash: "0xa" },
        { args: { from: A(7), to: A(8) }, blockNumber: 120n, logIndex: 0, transactionHash: "0xb" },
        { args: { from: A(8), to: A(0) }, blockNumber: 121n, logIndex: 0, transactionHash: "0xc" },
      ],
    },
  };
}

describe("StatsReader", () => {
  it("computes burned, circulating, liquidity, holders and pending proposals", async () => {
    const r = new StatsReader(fakeClient(base()), cfg);
    const s = await r.stats(new Date("2026-01-01T00:00:00Z"));
    expect(s.burned).toBe((100n * E).toString());
    expect(s.excludedBalance).toBe((70n * E).toString());
    expect(s.circulatingSupply).toBe((830n * E).toString());
    expect(s.liquidity.usdc).toMatchObject({ billReserve: (300n * E).toString(), otherReserve: "5000000", otherToken: USDC });
    expect(s.liquidity.eth).toMatchObject({ billReserve: (100n * E).toString(), otherReserve: (2n * E).toString(), otherToken: WETH });
    expect(s.holders).toMatchObject({ approximate: true, everReceived: 2, scannedToBlock: "250" });
    expect(s.pendingProposals.map((p) => p.id)).toEqual([2, 1]);
    expect(s.pendingProposals[1]).toMatchObject({ validators: 5, validated: true, approvalWeight: "4" });
  });

  it("scans holders incrementally without rescanning", async () => {
    const st = base();
    const r = new StatsReader(fakeClient(st), cfg);
    await r.stats();
    st.calls.length = 0;
    st.head = 260n;
    await r.stats();
    const scans = st.calls.filter((c) => c.startsWith("logs:"));
    expect(scans).toEqual(["logs:Transfer:251-260"]);
  });

  it("reports lots state and tolerates lotTokens revert", async () => {
    const st = base();
    st.values[k(LOTS, "lotTokens")] = new Error("no price");
    const l = await new StatsReader(fakeClient(st), cfg).lots();
    expect(l).toMatchObject({ openedSeries: 2, seriesOpen: true, lotTokens: null, pioneer: { sold: 40, total: 100 }, paid: { sold: 30, total: 1260, available: 150 } });
    expect(l.series).toHaveLength(14);
    expect(l.series[1]).toMatchObject({ open: true, opensAt: 1000 + 30 * 86400 });
    expect(l.series[2]?.open).toBe(false);
  });
});
