import type { Address } from "viem";
import { lotsAbi, solidarityAbi } from "./abi.js";
import type { ChainClient, LogEntry } from "./client.js";
import type { Config } from "./config.js";

export type ChainEvent =
  | { kind: "lot_sold"; key: string; block: bigint; buyer: Address; pioneer: boolean; priceUsdc: bigint }
  | { kind: "bill_paid"; key: string; block: bigint; requestId: bigint; payee: Address; amount: bigint }
  | { kind: "burn_milestone"; key: string; block: bigint; milestone: bigint; burned: bigint };

const evt = <T extends readonly { type: string; name?: string }[]>(abi: T, name: string) => {
  const e = abi.find((x) => x.type === "event" && x.name === name);
  if (!e) throw new Error(`event ${name} missing`);
  return e as never;
};

const keyOf = (l: LogEntry) => `${l.transactionHash}:${l.logIndex}`;

export async function getLogsChunked(
  client: ChainClient,
  address: Address,
  event: never,
  from: bigint,
  to: bigint,
  chunk: bigint,
): Promise<LogEntry[]> {
  const out: LogEntry[] = [];
  for (let s = from; s <= to; s += chunk) {
    const e = s + chunk - 1n < to ? s + chunk - 1n : to;
    out.push(...(await client.getLogs({ address, event, fromBlock: s, toBlock: e })));
  }
  return out;
}

/** Fetches lot purchases and solidarity payments in [from, to]. Read-only. */
export async function fetchChainEvents(client: ChainClient, cfg: Config, from: bigint, to: bigint): Promise<ChainEvent[]> {
  const events: ChainEvent[] = [];
  if (cfg.lots) {
    const logs = await getLogsChunked(client, cfg.lots, evt(lotsAbi, "Purchased"), from, to, cfg.logChunk);
    for (const l of logs) {
      events.push({
        kind: "lot_sold",
        key: `lot:${keyOf(l)}`,
        block: l.blockNumber,
        buyer: l.args.buyer as Address,
        pioneer: Boolean(l.args.pioneer),
        priceUsdc: BigInt(l.args.price as bigint),
      });
    }
  }
  if (cfg.solidarity) {
    const logs = await getLogsChunked(client, cfg.solidarity, evt(solidarityAbi, "Paid"), from, to, cfg.logChunk);
    for (const l of logs) {
      events.push({
        kind: "bill_paid",
        key: `paid:${keyOf(l)}`,
        block: l.blockNumber,
        requestId: BigInt(l.args.id as bigint),
        payee: l.args.payee as Address,
        amount: BigInt(l.args.amount as bigint),
      });
    }
  }
  return events.sort((a, b) => (a.block < b.block ? -1 : a.block > b.block ? 1 : 0));
}

/** Milestones (in wei) crossed by `burned`. */
export function crossedMilestones(burned: bigint, milestonesTokens: bigint[]): bigint[] {
  return milestonesTokens.map((m) => m * 10n ** 18n).filter((m) => burned >= m);
}
