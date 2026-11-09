import { createReadClient } from "../client.js";
import { loadConfig } from "../config.js";
import { StatsReader } from "../reader.js";
import { channelsFromEnv } from "./channels.js";
import { collect, flush, optionsFromEnv } from "./publisher.js";
import { Queue } from "./queue.js";

const USAGE = `usage: publisher <collect|list|approve <id>|reject <id>|flush|run>
  collect  fetch on-chain events and queue drafts (never posts)
  list     show the queue
  approve  human approval of a draft;  reject  discard it
  flush    send approved drafts (needs APPROVE=true; DRY_RUN=false for real posts)
  run      collect then flush`;

async function main() {
  const [cmd, arg] = process.argv.slice(2);
  const cfg = loadConfig();
  const queue = await Queue.load(process.env.STATE_FILE || "data/publisher-state.json");
  const opts = optionsFromEnv(process.env, channelsFromEnv());
  const doCollect = async () => {
    const reader = new StatsReader(createReadClient(cfg.rpcUrl), cfg);
    const n = await collect(createReadClient(cfg.rpcUrl), cfg, queue, () => reader.stats(), opts);
    console.log(`${n} new draft(s) queued`);
  };
  switch (cmd) {
    case "collect":
      return doCollect();
    case "list":
      for (const i of queue.list()) console.log(`${i.id}\t${i.status}\t${i.kind}\n  FR ${i.posts.fr}\n  EN ${i.posts.en}\n  RU ${i.posts.ru}`);
      return;
    case "approve":
    case "reject":
      if (!arg) throw new Error("missing id");
      queue.decide(arg, cmd === "approve" ? "approved" : "rejected");
      await queue.save();
      console.log(`${arg}: ${cmd}d`);
      return;
    case "flush":
      return void console.log(await flush(queue, opts));
    case "run":
      await doCollect();
      return void console.log(await flush(queue, opts));
    default:
      console.log(USAGE);
  }
}

main().catch((e) => {
  console.error(e instanceof Error ? e.message : e);
  process.exit(1);
});
