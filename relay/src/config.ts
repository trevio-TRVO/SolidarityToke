import type { Address } from "viem";

export interface Config {
  rpcUrl: string;
  chainId: number;
  token?: Address;
  lots?: Address;
  solidarity?: Address;
  autoLiq?: Address;
  pairUsdc?: Address;
  pairWeth?: Address;
  usdc: Address;
  initialSupply: bigint;
  excluded: Address[];
  deployBlock: bigint;
  logChunk: bigint;
  port: number;
  corsOrigin: string;
  cacheTtlMs: number;
}

type Env = Record<string, string | undefined>;

const ADDR = /^0x[0-9a-fA-F]{40}$/;

function addr(env: Env, key: string): Address | undefined {
  const v = env[key]?.trim();
  if (!v) return undefined;
  if (!ADDR.test(v)) throw new Error(`${key} is not a valid address`);
  return v as Address;
}

function int(env: Env, key: string, def: number): number {
  const v = env[key]?.trim();
  if (!v) return def;
  const n = Number(v);
  if (!Number.isInteger(n) || n < 0) throw new Error(`${key} must be a non-negative integer`);
  return n;
}

export function loadConfig(env: Env = process.env): Config {
  const excluded = (env.EXCLUDED_ADDRESSES ?? "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean)
    .map((s) => {
      if (!ADDR.test(s)) throw new Error("EXCLUDED_ADDRESSES contains an invalid address");
      return s as Address;
    });
  return {
    rpcUrl: env.RPC_URL?.trim() || "https://mainnet.base.org",
    chainId: int(env, "CHAIN_ID", 8453),
    token: addr(env, "TOKEN_ADDRESS"),
    lots: addr(env, "LOTS_ADDRESS"),
    solidarity: addr(env, "SOLIDARITY_ADDRESS"),
    autoLiq: addr(env, "AUTOLIQ_ADDRESS"),
    pairUsdc: addr(env, "PAIR_USDC_ADDRESS"),
    pairWeth: addr(env, "PAIR_WETH_ADDRESS"),
    usdc: addr(env, "USDC_ADDRESS") ?? "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",
    initialSupply: BigInt(env.INITIAL_SUPPLY?.trim() || "1000000000") * 10n ** 18n,
    excluded,
    deployBlock: BigInt(int(env, "DEPLOY_BLOCK", 0)),
    logChunk: BigInt(Math.max(1, int(env, "LOG_CHUNK", 5000))),
    port: int(env, "PORT", 8787),
    corsOrigin: env.CORS_ORIGIN?.trim() || "*",
    cacheTtlMs: int(env, "CACHE_TTL_SECONDS", 30) * 1000,
  };
}
