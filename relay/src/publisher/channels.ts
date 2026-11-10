import type { Lang } from "./templates.js";

export interface Channel {
  name: string;
  langs: Lang[];
  send(text: string, lang: Lang): Promise<void>;
}

export type Fetch = typeof fetch;

function redact(msg: string, secrets: string[]): string {
  return secrets.filter(Boolean).reduce((m, s) => m.split(s).join("***"), msg);
}

async function post(f: Fetch, url: string, init: RequestInit, secrets: string[], label: string): Promise<void> {
  try {
    const r = await f(url, init);
    if (!r.ok) throw new Error(`HTTP ${r.status}`);
  } catch (err) {
    throw new Error(`${label} failed: ${redact(err instanceof Error ? err.message : String(err), secrets)}`);
  }
}

export class TelegramChannel implements Channel {
  name = "telegram";
  constructor(
    private token: string,
    private chatId: string,
    public langs: Lang[] = ["fr", "en", "ru"],
    private f: Fetch = fetch,
  ) {}
  send(text: string): Promise<void> {
    return post(
      this.f,
      `https://api.telegram.org/bot${this.token}/sendMessage`,
      { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ chat_id: this.chatId, text, disable_web_page_preview: true }) },
      [this.token],
      "telegram",
    );
  }
}

export class XChannel implements Channel {
  name = "x";
  constructor(
    private accessToken: string,
    public langs: Lang[] = ["en"],
    private f: Fetch = fetch,
  ) {}
  send(text: string): Promise<void> {
    if ([...text].length > 280) return Promise.reject(new Error("x: post exceeds 280 characters"));
    return post(
      this.f,
      "https://api.x.com/2/tweets",
      { method: "POST", headers: { "Content-Type": "application/json", Authorization: `Bearer ${this.accessToken}` }, body: JSON.stringify({ text }) },
      [this.accessToken],
      "x",
    );
  }
}

export class ConsoleChannel implements Channel {
  name = "console";
  langs: Lang[] = ["fr", "en", "ru"];
  constructor(private log: (s: string) => void = console.log) {}
  async send(text: string, lang: Lang): Promise<void> {
    this.log(`[dry-run:${lang}] ${text}`);
  }
}

const parseLangs = (v: string | undefined, def: Lang[]): Lang[] => {
  const l = (v ?? "").split(",").map((s) => s.trim()).filter((s): s is Lang => ["fr", "en", "ru"].includes(s));
  return l.length ? l : def;
};

export function channelsFromEnv(env: Record<string, string | undefined> = process.env, f: Fetch = fetch): Channel[] {
  const out: Channel[] = [];
  if (env.TELEGRAM_BOT_TOKEN && env.TELEGRAM_CHAT_ID) {
    out.push(new TelegramChannel(env.TELEGRAM_BOT_TOKEN, env.TELEGRAM_CHAT_ID, parseLangs(env.TELEGRAM_LANGS, ["fr", "en", "ru"]), f));
  }
  if (env.X_ACCESS_TOKEN) out.push(new XChannel(env.X_ACCESS_TOKEN, parseLangs(env.X_LANGS, ["en"]), f));
  return out;
}
