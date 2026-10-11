// Run with: node --test springs.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { spring, track, loopT, mulberry32, presets } from "./springs.mjs";

test("spring starts at 0 and settles at 1 in every regime", () => {
  for (const [k, d] of [[170, 26], [120, 24], [320, 30], [100, 20], [100, 60]]) {
    assert.equal(spring(0, k, d), 0);
    assert.equal(spring(-1, k, d), 0);
    assert.ok(Math.abs(spring(30, k, d) - 1) < 1e-6, `k=${k} d=${d} settles`);
    assert.ok(spring(0.05, k, d) > 0 && spring(0.05, k, d) < 1);
  }
});
test("regimes are continuous at the critical boundary", () => {
  const k = 100; // w0 = 10, critical d = 20
  const a = spring(0.2, k, 19.999), b = spring(0.2, k, 20), c = spring(0.2, k, 20.001);
  assert.ok(Math.abs(a - b) < 1e-3 && Math.abs(b - c) < 1e-3);
});
test("overdamped never overshoots, playful does", () => {
  let max = 0; for (let t = 0; t < 3; t += 0.01) max = Math.max(max, spring(t, presets.heavy.k, presets.heavy.d));
  assert.ok(max <= 1 + 1e-9);
  let maxP = 0; for (let t = 0; t < 3; t += 0.01) maxP = Math.max(maxP, spring(t, presets.playful.k, presets.playful.d));
  assert.ok(maxP > 1.01);
});
test("track sums one spring per change and rejects bad input", () => {
  const ch = [{ at: 0, to: 0 }, { at: 1, to: 100 }, { at: 2, to: 50 }];
  assert.equal(track(ch, 0), 0);
  assert.ok(Math.abs(track(ch, 1.9) - 100) < 1);
  assert.ok(Math.abs(track(ch, 5) - 50) < 1e-3);
  assert.throws(() => track([], 1));
  assert.throws(() => track([{ at: 2, to: 0 }, { at: 1, to: 1 }], 1));
});
test("loopT wraps and guards duration", () => {
  assert.equal(loopT(16, 15), 1);
  assert.equal(loopT(-1, 15), 14);
  assert.throws(() => loopT(1, 0));
  assert.throws(() => loopT(1, NaN));
});
test("mulberry32 is deterministic", () => {
  assert.equal(mulberry32(7)(), mulberry32(7)());
});
