import { mkdir, readFile, rename, writeFile } from "node:fs/promises";
import { dirname } from "node:path";
import type { ChainEvent } from "../events.js";
import { render, type Posts } from "./templates.js";

export type Status = "pending" | "approved" | "rejected" | "posted";

export interface QueueItem {
  id: string; // = event key, guarantees idempotence
  kind: ChainEvent["kind"];
  status: Status;
  posts: Posts;
  createdAt: string;
  decidedAt?: string;
  postedTo?: string[];
}

export interface State {
  cursor: string | null; // last scanned block
  milestonesDone: string[];
  items: QueueItem[];
}

export const emptyState = (): State => ({ cursor: null, milestonesDone: [], items: [] });

/** JSON-file backed approval queue. Items start `pending`; only a human decision changes that. */
export class Queue {
  constructor(
    private path: string,
    public state: State = emptyState(),
  ) {}

  static async load(path: string): Promise<Queue> {
    try {
      return new Queue(path, { ...emptyState(), ...JSON.parse(await readFile(path, "utf8")) });
    } catch (err) {
      if ((err as NodeJS.ErrnoException).code === "ENOENT") return new Queue(path);
      throw err;
    }
  }

  async save(): Promise<void> {
    await mkdir(dirname(this.path), { recursive: true });
    const tmp = `${this.path}.tmp`;
    await writeFile(tmp, JSON.stringify(this.state, null, 2));
    await rename(tmp, this.path);
  }

  enqueue(e: ChainEvent, now = new Date()): QueueItem | null {
    if (this.state.items.some((i) => i.id === e.key)) return null;
    const item: QueueItem = { id: e.key, kind: e.kind, status: "pending", posts: render(e), createdAt: now.toISOString() };
    this.state.items.push(item);
    return item;
  }

  list(status?: Status): QueueItem[] {
    return this.state.items.filter((i) => !status || i.status === status);
  }

  decide(id: string, status: "approved" | "rejected", now = new Date()): QueueItem {
    const item = this.state.items.find((i) => i.id === id);
    if (!item) throw new Error(`unknown item ${id}`);
    if (item.status === "posted") throw new Error("already posted");
    item.status = status;
    item.decidedAt = now.toISOString();
    return item;
  }
}
