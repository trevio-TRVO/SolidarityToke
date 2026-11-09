import { parseAbi } from "viem";

export const tokenAbi = parseAbi([
  "function totalSupply() view returns (uint256)",
  "function balanceOf(address) view returns (uint256)",
  "function solidarityWallet() view returns (address)",
  "function operationsWallet() view returns (address)",
  "function liquidityReserve() view returns (address)",
  "event Transfer(address indexed from, address indexed to, uint256 value)",
  "event Contribution(address indexed trader, uint256 aid, uint256 burned, uint256 ops, uint256 liquidity)",
]);

export const lotsAbi = parseAbi([
  "function seriesStart() view returns (uint256)",
  "function openedSeries() view returns (uint256)",
  "function availablePaidLots() view returns (uint256)",
  "function pioneerSold() view returns (uint256)",
  "function paidSold() view returns (uint256)",
  "function outstanding() view returns (uint256)",
  "function lotTokens() view returns (uint256)",
  "event Purchased(address indexed buyer, bool pioneer, uint256 price)",
  "event SeriesOpened(uint256 time)",
]);

export const solidarityAbi = parseAbi([
  "function requestCount() view returns (uint256)",
  "function requests(uint256) view returns (address payee, uint256 amount, bytes32 invoiceHash, uint64 validatedAt, uint32 validators, uint8 status)",
  "function approvalWeight(uint256) view returns (uint256)",
  "event Paid(uint256 indexed id, address indexed payee, uint256 amount)",
]);

export const pairAbi = parseAbi([
  "function token0() view returns (address)",
  "function token1() view returns (address)",
  "function getReserves() view returns (uint112, uint112, uint32)",
]);
