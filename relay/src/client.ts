import { createPublicClient, http, type Abi, type AbiEvent, type Address } from "viem";

export interface LogEntry {
  args: Record<string, unknown>;
  blockNumber: bigint;
  logIndex: number;
  transactionHash: string;
}

/** Minimal read-only surface: no wallet, no signing, no writes. */
export interface ChainClient {
  readContract(a: { address: Address; abi: Abi | readonly unknown[]; functionName: string; args?: readonly unknown[] }): Promise<unknown>;
  getLogs(a: { address: Address; event: AbiEvent; fromBlock: bigint; toBlock: bigint }): Promise<LogEntry[]>;
  getBlockNumber(): Promise<bigint>;
}

export function createReadClient(rpcUrl: string): ChainClient {
  return createPublicClient({ transport: http(rpcUrl) }) as unknown as ChainClient;
}
