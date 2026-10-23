// Deterministic frame renderer: calls window.seek(t) per frame in headless Chromium and encodes with ffmpeg.
// Usage: node render.mjs [--out out/final.mp4] [--w 1080] [--h 1920] [--fps 60] [--dur 15] [--sub 4] [--frame N] [--page index.html]
import { chromium } from "playwright";
import { spawnSync } from "node:child_process";
import { mkdirSync, rmSync, existsSync, copyFileSync } from "node:fs";
import { pathToFileURL } from "node:url";
import { dirname, resolve } from "node:path";

const argv = process.argv.slice(2);
const args = {};
for (let i = 0; i < argv.length; i++) {
  if (!argv[i].startsWith("--")) continue;
  const key = argv[i].slice(2);
  const val = argv[i + 1];
  if (val === undefined || val.startsWith("--")) {
    console.error(`[FAIL] --${key} needs a value`);
    process.exit(2);
  }
  args[key] = val;
  i++;
}
function num(key, fallback, { integer = false, min = 0 } = {}) {
  if (args[key] === undefined) return fallback;
  const v = Number(args[key]);
  if (!Number.isFinite(v) || v < min || (integer && !Number.isInteger(v))) {
    console.error(`[FAIL] --${key} must be a ${integer ? "whole " : ""}number >= ${min}, got "${args[key]}"`);
    process.exit(2);
  }
  return v;
}
const W = num("w", 1080, { integer: true, min: 16 });
const H = num("h", 1920, { integer: true, min: 16 });
const FPS = num("fps", 60, { integer: true, min: 1 });
const DUR = num("dur", 15, { min: 0.1 });
const SUB = num("sub", 4, { integer: true, min: 1 });
const ONE = args.frame === undefined ? null : num("frame", 0, { integer: true, min: 0 });
const OUT = resolve(args.out ?? (ONE === null ? "out/final.mp4" : `out/frame-${ONE}.png`));
const page = resolve(args.page ?? "index.html");

if (!existsSync(page)) {
  console.error(`[FAIL] ${page} not found`);
  process.exit(1);
}
if (ONE === null && spawnSync("ffmpeg", ["-version"]).status !== 0) {
  console.error("[FAIL] ffmpeg not found on PATH");
  process.exit(1);
}
const tmp = resolve("out/.frames");
rmSync(tmp, { recursive: true, force: true });
mkdirSync(tmp, { recursive: true });
mkdirSync(dirname(OUT), { recursive: true });

const browser = await chromium.launch();
const ctx = await browser.newContext({ viewport: { width: W, height: H }, deviceScaleFactor: 1 });
const tab = await ctx.newPage();
tab.on("pageerror", (e) => {
  console.error(`[FAIL] page error: ${e.message}`);
  process.exit(1);
});
await tab.goto(pathToFileURL(page).href);
await tab.waitForFunction(() => typeof window.seek === "function");

const total = ONE === null ? Math.round(FPS * DUR) : 1;
const subs = ONE === null ? SUB : 1; // single-frame mode keeps only the first subframe
const pad = (n) => String(n).padStart(6, "0");
let i = 0;
for (let f = 0; f < total; f++) {
  const base = ONE === null ? f : ONE;
  for (let s = 0; s < subs; s++) {
    const t = (base + s / SUB) / FPS;
    await tab.evaluate((tt) => window.seek(tt), t);
    await tab.screenshot({ path: `${tmp}/${pad(i++)}.png`, fullPage: false });
  }
}
await browser.close();

if (ONE !== null) {
  // Single frame: the first subframe, exact time ONE / FPS.
  copyFileSync(`${tmp}/${pad(0)}.png`, OUT);
  rmSync(tmp, { recursive: true, force: true });
  console.log(`[OK] frame ${ONE} written to ${OUT}`);
  process.exit(0);
}

// Motion blur: tmix averages a sliding window of SUB subframes; selecting every frame whose index n satisfies
// (n + 1) mod SUB == 0 keeps exactly one output per base frame, averaged over subframes 0..SUB-1 of that frame.
const vf =
  SUB > 1
    ? `tmix=frames=${SUB}:weights='${Array(SUB).fill(1).join(" ")}',select='eq(mod(n+1\\,${SUB})\\,0)',setpts=N/${FPS}/TB`
    : null;
const ff = ["-y", "-loglevel", "error", "-framerate", String(FPS * SUB), "-i", `${tmp}/%06d.png`];
if (vf) ff.push("-vf", vf);
ff.push("-r", String(FPS), "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "16", "-movflags", "+faststart", OUT);
const r = spawnSync("ffmpeg", ff, { stdio: "inherit" });
if (r.status !== 0) {
  console.error("[FAIL] ffmpeg failed");
  process.exit(1);
}
rmSync(tmp, { recursive: true, force: true });
console.log(`[OK] ${OUT} ${W}x${H} ${FPS}fps ${DUR}s`);
