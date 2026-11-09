import type { Address } from "viem";
import { lotsAbi, pairAbi, solidarityAbi, tokenAbi } from "./abi.js";
import type { ChainClient } from "./client.js";
import type { Config } from "./config.js";
import { getLogsChunked } from "./events.js";

const DEAD: Address = "0x000000000000000000000000000000000000dEaD";
const SERIES_INTERVAL = 30 * 24 * 3600;
const SERIES_COUNT = 14;
const PAID_LOTS = 90;
const PIONEER_LOTS = 100;

export interface PairLiquidity {
  pair: Address;
  billReserve: string;
  otherReserve: string;
  otherToken: Address;
}

export interface Stats {
  updatedAt: string;
  block: string;
  totalSupply: string;
  burned: string;
  circulatingSupply: string;
  excludedBalance: string;
  liquidity: { usdc: PairLiquidity | null; eth: PairLiquidity | null };
  holders: { approximate: true; everReceived: number; scannedToBlock: string };
  pendingProposals: Proposal[];
}

export interface Proposal {
  id: number;
  payee: Address;
  amount: string;
  validators: number;
  validated: boolean;
  approvalWeight: string;
}

export interface LotsState {
  seriesStart: number;
  seriesOpen: boolean;
  openedSeries: number;
  seriesCount: number;
  pioneer: { sold: number; total: number };
  paid: { sold: number; total: number; available: number };
  freeLotsPerSeries: number;
  lotTokens: string | null;
  outstanding: string;
  series: { index: number; opensAt: number | null; open: boolean }[];
}

const num = (v: unknown) => Number(v as bigint);

export class StatsReader {
  private recipients = new Set<string>();
  private scanned: bigint;

  constructor(
    private client: ChainClient,
    private cfg: Config,
  ) {
    this.scanned = cfg.deployBlock > 0n ? cfg.deployBlock - 1n : -1n;
  }

  private requireToken(): Address {
    if (!this.cfg.token) throw new Error("TOKEN_ADDRESS not configured");
    return this.cfg.token;
  }

  private read(address: Address, abi: readonly unknown[], functionName: string, args?: readonly unknown[]) {
    return this.client.readContract({ address, abi, functionName, args });
  }

  private async pair(pair: Address | undefined): Promise<PairLiquidity | null> {
    if (!pair) return null;
    const token = this.requireToken();
    const [t0, t1, res] = await Promise.all([
      this.read(pair, pairAbi, "token0"),
      this.read(pair, pairAbi, "token1"),
      this.read(pair, pairAbi, "getReserves"),
    ]);
    const [r0, r1] = res as readonly [bigint, bigint, number];
    const billIs0 = (t0 as string).toLowerCase() === token.toLowerCase();
    return {
      pair,
      billReserve: (billIs0 ? r0 : r1).toString(),
      otherReserve: (billIs0 ? r1 : r0).toString(),
      otherToken: (billIs0 ? t1 : t0) as Address,
    };
  }

  /** Incremental Transfer scan; bounded per call so the first refresh never hammers the RPC. */
  private async scanHolders(head: bigint, maxChunks = 20): Promise<void> {
    const token = this.requireToken();
    const event = tokenAbi.find((x) => x.type === "event" && x.name === "Transfer") as never;
    const limit = this.cfg.logChunk * BigInt(maxChunks);
    const from = this.scanned + 1n;
    if (from > head) return;
    const to = head - from + 1n > limit ? from + limit - 1n : head;
    const logs = await getLogsChunked(this.client, token, event, from, to, this.cfg.logChunk);
    for (const l of logs) this.recipients.add((l.args.to as string).toLowerCase());
    this.recipients.delete("0x0000000000000000000000000000000000000000");
    this.scanned = to;
  }

  async stats(now = new Date()): Promise<Stats> {
    const token = this.requireToken();
    const block = await this.client.getBlockNumber();
    const totalSupply = (await this.read(token, tokenAbi, "totalSupply")) as bigint;
    const burned = this.cfg.initialSupply > totalSupply ? this.cfg.initialSupply - totalSupply : 0n;

    const excluded = new Set<string>([DEAD.toLowerCase(), ...this.cfg.excluded.map((a) => a.toLowerCase())]);
    const addExcluded = (a?: Address) => a && excluded.add(a.toLowerCase());
    addExcluded(this.cfg.autoLiq);
    addExcluded(this.cfg.lots);
    addExcluded(this.cfg.solidarity);
    addExcluded(this.cfg.pairUsdc);
    addExcluded(this.cfg.pairWeth);
    const [ops, liq] = await Promise.all([
      this.read(token, tokenAbi, "operationsWallet"),
      this.read(token, tokenAbi, "liquidityReserve"),
    ]);
    addExcluded(ops as Address);
    addExcluded(liq as Address);

    let excludedBalance = 0n;
    for (const a of excluded) {
      excludedBalance += (await this.read(token, tokenAbi, "balanceOf", [a])) as bigint;
    }
    const circulating = totalSupply > excludedBalance ? totalSupply - excludedBalance : 0n;

    await this.scanHolders(block);

    return {
      updatedAt: now.toISOString(),
      block: block.toString(),
      totalSupply: totalSupply.toString(),
      burned: burned.toString(),
      circulatingSupply: circulating.toString(),
      excludedBalance: excludedBalance.toString(),
      liquidity: { usdc: await this.pair(this.cfg.pairUsdc), eth: await this.pair(this.cfg.pairWeth) },
      holders: { approximate: true, everReceived: this.recipients.size, scannedToBlock: this.scanned.toString() },
      pendingProposals: await this.proposals(),
    };
  }

  async proposals(): Promise<Proposal[]> {
    const w = this.cfg.solidarity;
    if (!w) return [];
    const count = num(await this.read(w, solidarityAbi, "requestCount"));
    const out: Proposal[] = [];
    // Newest first, bounded so a huge history cannot stall the API.
    for (let id = count - 1; id >= 0 && out.length < 50 && count - id <= 200; id--) {
      const r = (await this.read(w, solidarityAbi, "requests", [BigInt(id)])) as readonly [Address, bigint, string, bigint, number, number];
      if (r[5] !== 1) continue; // Status.Open
      const weight = (await this.read(w, solidarityAbi, "approvalWeight", [BigInt(id)])) as bigint;
      out.push({
        id,
        payee: r[0],
        amount: r[1].toString(),
        validators: Number(r[4]),
        validated: r[3] !== 0n,
        approvalWeight: weight.toString(),
      });
    }
    return out;
  }

  async lots(): Promise<LotsState> {
    const l = this.cfg.lots;
    if (!l) throw new Error("LOTS_ADDRESS not configured");
    const get = async (fn: string) => (await this.read(l, lotsAbi, fn)) as bigint;
    const [seriesStart, opened, available, pioneerSold, paidSold, outstanding] = await Promise.all(
      ["seriesStart", "openedSeries", "availablePaidLots", "pioneerSold", "paidSold", "outstanding"].map(get),
    ) as bigint[];
    // lotTokens reverts while the TWAP has no price yet.
    const lotTokens = await get("lotTokens").then((v) => v.toString(), () => null);
    const start = num(seriesStart);
    const openN = num(opened);
    return {
      seriesStart: start,
      seriesOpen: start > 0,
      openedSeries: openN,
      seriesCount: SERIES_COUNT,
      pioneer: { sold: num(pioneerSold), total: PIONEER_LOTS },
      paid: { sold: num(paidSold), total: SERIES_COUNT * PAID_LOTS, available: num(available) },
      freeLotsPerSeries: 10,
      lotTokens,
      outstanding: outstanding!.toString(),
      series: Array.from({ length: SERIES_COUNT }, (_, i) => ({
        index: i + 1,
        opensAt: start > 0 ? start + i * SERIES_INTERVAL : null,
        open: i < openN,
      })),
    };
  }
}
