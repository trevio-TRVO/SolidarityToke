import type { Address } from "viem";
import type { ChainClient, LogEntry } from "../src/client.js";
import type { Config } from "../src/config.js";

export const A = (n: number) => `0x${n.toString(16).padStart(40, "0")}` as Address;
export const TOKEN = A(0x10), LOTS = A(0x20), SOL = A(0x30), PAIR = A(0x40), WPAIR = A(0x41), USDC = A(0x50), WETH = A(0x51), OPS = A(0x60), LIQ = A(0x61);

export const cfg: Config = {
  rpcUrl: "http://x", chainId: 8453, token: TOKEN, lots: LOTS, solidarity: SOL, pairUsdc: PAIR, pairWeth: WPAIR,
  usdc: USDC, initialSupply: 1000n * 10n ** 18n, excluded: [], deployBlock: 0n, logChunk: 100n, port: 0, corsOrigin: "*", cacheTtlMs: 1000,
};

export interface FakeState {
  head: bigint;
  values: Record<string, unknown>;
  logs: Record<string, LogEntry[]>;
  calls: string[];
}

export function fakeClient(s: FakeState): ChainClient {
  return {
    async getBlockNumber() { return s.head; },
    async readContract({ address, functionName, args }) {
      const key = `${address.toLowerCase()}.${functionName}${args?.length ? `(${args.map(String).join(",").toLowerCase()})` : ""}`;
      s.calls.push(key);
      const v = s.values[key];
      if (v instanceof Error) throw v;
      if (v === undefined) throw new Error(`no fake for ${key}`);
      return v;
    },
    async getLogs({ address, event, fromBlock, toBlock }) {
      s.calls.push(`logs:${(event as { name: string }).name}:${fromBlock}-${toBlock}`);
      return (s.logs[`${address.toLowerCase()}.${(event as { name: string }).name}`] ?? []).filter((l) => l.blockNumber >= fromBlock && l.blockNumber <= toBlock);
    },
  };
}

export const k = (a: Address, rest: string) => `${a.toLowerCase()}.${rest}`;
