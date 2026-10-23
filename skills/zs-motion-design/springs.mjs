// Closed-form damped springs so motion stays a pure function of time.
// spring(t, k, d) returns the progress of a unit step started at t=0.
// Three regimes: underdamped (zeta < 1), critically damped (zeta ~ 1), overdamped (zeta > 1).
export function spring(t, k = 170, d = 26) {
  if (!Number.isFinite(t) || !(k > 0) || !(d >= 0)) throw new Error(`spring: bad input t=${t} k=${k} d=${d}`);
  if (t <= 0) return 0;
  const w0 = Math.sqrt(k);
  const zeta = d / (2 * w0);
  if (zeta < 1 - 1e-6) {
    const wd = w0 * Math.sqrt(1 - zeta * zeta);
    const e = Math.exp(-zeta * w0 * t);
    return 1 - e * (Math.cos(wd * t) + ((zeta * w0) / wd) * Math.sin(wd * t));
  }
  if (zeta <= 1 + 1e-6) {
    const e = Math.exp(-w0 * t);
    return 1 - e * (1 + w0 * t);
  }
  const s = Math.sqrt(zeta * zeta - 1);
  const r1 = -w0 * (zeta - s);
  const r2 = -w0 * (zeta + s);
  return 1 - (r2 * Math.exp(r1 * t) - r1 * Math.exp(r2 * t)) / (r2 - r1);
}

export const presets = {
  snappy: { k: 320, d: 30 },
  default: { k: 170, d: 26 },
  heavy: { k: 120, d: 24 },
  playful: { k: 220, d: 14 },
};

// track(changes, t): one spring per value change, summed, never restarted.
// changes = [{ at: 0, to: 0 }, { at: 1.2, to: 320 }, { at: 2.4, to: 80 }], sorted by `at` ascending.
export function track(changes, t, p = presets.default) {
  if (!Array.isArray(changes) || changes.length === 0) throw new Error("track: changes must be a non-empty array");
  let value = changes[0].to;
  for (let i = 1; i < changes.length; i++) {
    const c = changes[i];
    if (c.at < changes[i - 1].at) throw new Error(`track: changes must be sorted by at (index ${i})`);
    value += (c.to - changes[i - 1].to) * spring(t - c.at, p.k, p.d);
  }
  return value;
}

// loopT wraps time so the last frame equals the first.
export function loopT(t, duration) {
  if (!(duration > 0) || !Number.isFinite(duration)) throw new Error(`loopT: duration must be a positive number, got ${duration}`);
  return ((t % duration) + duration) % duration;
}

// Seeded noise. Never Math.random in render mode.
export function mulberry32(seed) {
  let a = seed >>> 0;
  return function () {
    a = (a + 0x6d2b79f5) >>> 0;
    let x = a;
    x = Math.imul(x ^ (x >>> 15), x | 1);
    x ^= x + Math.imul(x ^ (x >>> 7), x | 61);
    return ((x ^ (x >>> 14)) >>> 0) / 4294967296;
  };
}
