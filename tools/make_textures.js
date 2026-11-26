// Builds SkinDeep's effect textures as 32-bit TGA (white, shape in alpha,
// tinted in game with SetVertexColor). No dependencies.
// Usage: node tools/make_textures.js [outDir]   (default: Media/Textures)
'use strict';
const fs = require('fs');
const path = require('path');

const clamp = (v, a = 0, b = 1) => Math.max(a, Math.min(b, v));
const smooth = (e0, e1, x) => { const t = clamp((x - e0) / (e1 - e0)); return t * t * (3 - 2 * t); };

// Deterministic pseudo-random, so rebuilds give identical files.
let seed = 1337;
const rand = () => { seed = (seed * 1103515245 + 12345) & 0x7fffffff; return seed / 0x7fffffff; };

// alphaFn(u, v, w, h) gets coordinates in [-1, 1] (v up) and returns either
// an alpha 0..1 (white texture), [alpha, luminance] for shaded art that is
// still tinted in game (luminance multiplies the vertex color), or
// [alpha, r, g, b] for full-color art (the legendary weapons, drawn white).
function render(w, h, alphaFn, ss = 4) {
  const px = Buffer.alloc(w * h * 4);
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      let a = 0, l = 0, cr = 0, cg = 0, cb = 0, color = false;
      for (let sy = 0; sy < ss; sy++) for (let sx = 0; sx < ss; sx++) {
        const u = ((x + (sx + 0.5) / ss) / w) * 2 - 1;
        const v = 1 - ((y + (sy + 0.5) / ss) / h) * 2;
        const r = alphaFn(u, v, w, h);
        const al = clamp(Array.isArray(r) ? r[0] : r);
        a += al;
        l += al * clamp(Array.isArray(r) ? r[1] : 1);
        if (Array.isArray(r) && r.length === 4) {
          color = true;
          cr += al * clamp(r[1]); cg += al * clamp(r[2]); cb += al * clamp(r[3]);
        } else {
          const k = al * clamp(Array.isArray(r) ? r[1] : 1);
          cr += k; cg += k; cb += k;
        }
      }
      const lum = a > 0 ? l / a : 1;
      const aSum = a;
      a /= ss * ss;
      // TGA stores rows bottom-up; y here counts from the top.
      const i = ((h - 1 - y) * w + x) * 4;
      const c = Math.round(lum * 255);
      if (color) {
        const n = aSum > 0 ? aSum : 1;
        px[i] = Math.round(cb / n * 255); px[i + 1] = Math.round(cg / n * 255); px[i + 2] = Math.round(cr / n * 255);
      } else {
        px[i] = c; px[i + 1] = c; px[i + 2] = c;
      }
      px[i + 3] = Math.round(a * 255);
    }
  }
  const header = Buffer.alloc(18);
  header[2] = 2;                    // uncompressed true-colour
  header.writeUInt16LE(w, 12);
  header.writeUInt16LE(h, 14);
  header[16] = 32;                  // bits per pixel
  header[17] = 0x08;                // 8 alpha bits, bottom-left origin
  return Buffer.concat([header, px]);
}

const polar = (u, v) => [Math.hypot(u, v), Math.atan2(v, u)];

// Distance from (px, py) to the segment a-b.
function segDist(px, py, ax, ay, bx, by) {
  const dx = bx - ax, dy = by - ay;
  const t = clamp(((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy || 1));
  return Math.hypot(px - ax - t * dx, py - ay - t * dy);
}

// Polyline segments for jagged cracks radiating from the center.
const crackSegs = (() => {
  const segs = [];
  for (let i = 0; i < 9; i++) {
    let a = (i / 9) * Math.PI * 2 + rand() * 0.4, x = 0, y = 0;
    const steps = 4 + Math.floor(rand() * 2);
    for (let j = 0; j < steps; j++) {
      a += (rand() - 0.5) * 0.9;
      const len = 0.14 + rand() * 0.1;
      const nx = x + Math.cos(a) * len, ny = y + Math.sin(a) * len;
      segs.push([x, y, nx, ny, Math.hypot(nx, ny)]);
      // Occasional side branch.
      if (rand() < 0.3) {
        const b = a + (rand() < 0.5 ? 0.8 : -0.8);
        segs.push([nx, ny, nx + Math.cos(b) * 0.12, ny + Math.sin(b) * 0.12, Math.hypot(nx, ny) + 0.1]);
      }
      x = nx; y = ny;
    }
  }
  return segs;
})();

// A zigzag lightning bolt from bottom to top.
const boltPts = (() => {
  const pts = [[0, -0.95]];
  for (let i = 1; i < 7; i++) pts.push([(i % 2 ? 1 : -1) * (0.25 + rand() * 0.3), -0.95 + i * 0.27]);
  pts.push([0, 0.95]);
  return pts;
})();

// Signed distance to a rounded box (pixels), negative inside.
function roundBox(px, py, bx, by, r) {
  const qx = Math.abs(px) - bx + r, qy = Math.abs(py) - by + r;
  return Math.hypot(Math.max(qx, 0), Math.max(qy, 0)) + Math.min(Math.max(qx, qy), 0) - r;
}

const TEXTURES = {
  // Soft round glow.
  glow: [64, 64, (u, v) => { const r = Math.hypot(u, v); return Math.pow(clamp(1 - r), 2.2); }],
  // Small hot spark: bright core, quick falloff.
  spark: [32, 32, (u, v) => { const r = Math.hypot(u, v); return clamp(1 - r) ** 3 + 0.9 * (1 - smooth(0, 0.3, r)); }],
  // Shockwave ring.
  ring: [128, 128, (u, v) => { const r = Math.hypot(u, v); return Math.exp(-Math.pow((r - 0.78) / 0.07, 2)); }],
  // Twelve-point star burst.
  burst: [128, 128, (u, v) => {
    const [r, a] = polar(u, v);
    const rays = Math.pow(Math.abs(Math.cos(a * 6)), 18) * (1 - smooth(0.15, 1.0, r));
    const rays2 = Math.pow(Math.abs(Math.cos(a * 6 + Math.PI / 2)), 30) * (1 - smooth(0.1, 0.6, r)) * 0.7;
    const core = 1 - smooth(0.0, 0.32, r);
    return rays + rays2 + core;
  }],
  // Rune circle: double ring, eight notches, inner dashed ring.
  rune: [128, 128, (u, v) => {
    const [r, a] = polar(u, v);
    const line = (c, w) => 1 - smooth(w * 0.6, w, Math.abs(r - c));
    let al = line(0.9, 0.035) + line(0.8, 0.02);
    const seg = (a / (Math.PI * 2) * 8 % 1 + 1) % 1;               // 8 sectors
    if (Math.abs(seg - 0.5) < 0.07 && r > 0.8 && r < 0.9) al += 1; // notches between rings
    const dash = (a / (Math.PI * 2) * 24 % 1 + 1) % 1;
    if (dash < 0.55) al += line(0.6, 0.025);
    // Diamond studs on the inner ring.
    const sa = Math.round(a / (Math.PI / 4)) * (Math.PI / 4);
    const sx = u - Math.cos(sa) * 0.6, sy = v - Math.sin(sa) * 0.6;
    if (Math.abs(sx) + Math.abs(sy) < 0.07) al += 1;
    return al;
  }],
  // Ink splat: lumpy blob plus flung droplets.
  splat: [128, 128, (() => {
    const lumps = Array.from({ length: 7 }, () => [1 + Math.floor(rand() * 6), rand() * 6.28, 0.04 + rand() * 0.07]);
    const drops = Array.from({ length: 9 }, () => {
      const a = rand() * 6.28, d = 0.62 + rand() * 0.3;
      return [Math.cos(a) * d, Math.sin(a) * d, 0.04 + rand() * 0.06];
    });
    return (u, v) => {
      const [r, a] = polar(u, v);
      let edge = 0.5;
      for (const [k, ph, amp] of lumps) edge += amp * Math.sin(k * a + ph);
      let al = 1 - smooth(edge - 0.03, edge + 0.03, r);
      for (const [dx, dy, s] of drops) al += 1 - smooth(s * 0.7, s, Math.hypot(u - dx, v - dy));
      return al;
    };
  })()],
  // Ice shard: a long faceted diamond.
  shard: [32, 64, (u, v) => {
    const d = Math.abs(u) / 0.45 + Math.abs(v) / 0.95;
    return (1 - smooth(0.85, 1.0, d)) * (0.65 + 0.35 * (u < 0 ? 1 : 0.5));
  }],
  // Blade streak: horizontal, tapered at both ends.
  slash: [128, 32, (u, v) => {
    const width = 0.55 * Math.pow(clamp(1 - Math.abs(u)), 0.6) * (0.5 + 0.5 * (1 - (u + 1) / 2));
    return (1 - smooth(width * 0.4, width, Math.abs(v))) * (1 - smooth(0.85, 1, Math.abs(u)));
  }],
  // Hard square pixel (retro sparkle).
  pixel: [8, 8, () => 1, 1],
  // Slot machine window: filled rounded panel, lit from the top.
  panel: [256, 64, (u, v, w, h) => {
    const px = u * w / 2, py = v * h / 2;
    const d = roundBox(px, py, w / 2 - 6, h / 2 - 4, 12);
    return [1 - smooth(-1, 1, d), 0.72 + 0.28 * clamp(0.5 + py / (h * 0.9))];
  }],
  // Its bevelled border.
  frame: [256, 64, (u, v, w, h) => {
    const px = u * w / 2, py = v * h / 2;
    const d = roundBox(px, py, w / 2 - 6, h / 2 - 4, 12);
    const ring = 1 - smooth(2.2, 3.2, Math.abs(d + 3));
    const shine = 0.6 + 0.4 * clamp(0.5 + py / (h * 0.6));
    return [ring, d + 3 > 0 ? shine : shine * 0.8];
  }],
  // Gold coin: rim, face, inner ring and a highlight.
  coin: [32, 32, (u, v) => {
    const r = Math.hypot(u, v);
    let l = 0.95;
    if (r > 0.72) l = 0.7;
    if (Math.abs(r - 0.55) < 0.06) l = 0.72;
    l += 0.3 * (1 - smooth(0, 0.45, Math.hypot(u + 0.3, v - 0.3)));
    return [1 - smooth(0.88, 0.95, r), l];
  }],
  // --- Class skins ---------------------------------------------------------
  // Ground crack (Warrior): jagged lines that thin out toward their ends.
  crack: [128, 128, (u, v) => {
    let al = 1 - smooth(0.05, 0.12, Math.hypot(u, v));
    for (const [ax, ay, bx, by, far] of crackSegs) {
      const w = 0.035 * (1.15 - far);
      al = Math.max(al, 1 - smooth(w * 0.5, w, segDist(u, v, ax, ay, bx, by)));
    }
    return al;
  }],
  // Column of light (Paladin): soft vertical beam with a bright core.
  beam: [64, 256, (u, v) => {
    const ends = 1 - smooth(0.55, 1, Math.abs(v));
    return (Math.exp(-Math.pow(u / 0.45, 2)) * 0.6 + Math.exp(-Math.pow(u / 0.12, 2))) * ends;
  }],
  // Crosshair (Hunter): two rings, four ticks, a center dot.
  reticle: [128, 128, (u, v) => {
    const r = Math.hypot(u, v);
    const line = (c, w) => 1 - smooth(w * 0.5, w, Math.abs(r - c));
    let al = line(0.78, 0.05) + line(0.42, 0.035) + (1 - smooth(0.04, 0.07, r));
    const tick = (a, b) => (Math.abs(a) < 0.035 && Math.abs(b) > 0.5 && Math.abs(b) < 0.98) ? 1 : 0;
    al += tick(u, v) + tick(v, u);
    return al;
  }],
  // Lightning bolt (Shaman): zigzag core with a glow.
  bolt: [32, 128, (u, v) => {
    let d = 9;
    for (let i = 0; i < boltPts.length - 1; i++) {
      const [ax, ay] = boltPts[i], [bx, by] = boltPts[i + 1];
      // u is stretched (texture is 4x taller than wide), so squash it back.
      d = Math.min(d, segDist(u, v * 4, ax, ay * 4, bx, by * 4));
    }
    return (1 - smooth(0.08, 0.16, d)) + 0.5 * Math.exp(-d * 6);
  }],
  // Feather (Priest): vane with a darker shaft.
  feather: [32, 64, (u, v) => {
    const vane = Math.pow(u / (0.75 * Math.sqrt(clamp(1 - Math.pow((v - 0.1) / 0.85, 2)))), 2);
    const inVane = vane < 1 ? 1 - smooth(0.8, 1, vane) : 0;
    const shaft = Math.abs(u) < 0.08 && v < 0.98 && v > -0.98 ? 1 : 0;
    return [Math.max(inVane, shaft), shaft ? 0.65 : 0.95 - 0.1 * Math.abs(u)];
  }],
  // Leaf (Druid): pointed oval with a midrib.
  leaf: [32, 64, (u, v) => {
    const half = 0.85 * Math.sqrt(clamp(1 - v * v)) * (1 - 0.3 * Math.abs(v));
    const inside = 1 - smooth(half - 0.08, half, Math.abs(u));
    const rib = Math.abs(u) < 0.07 ? 0.6 : 0.95;
    return [inside * (1 - smooth(0.9, 1, Math.abs(v))), rib];
  }],
  // Flower (Druid crit): six petals around a lighter heart.
  bloom: [128, 128, (u, v) => {
    const [r, a] = polar(u, v);
    let al = 0;
    for (let i = 0; i < 6; i++) {
      const pa = i * Math.PI / 3;
      const lx = Math.cos(pa) * u + Math.sin(pa) * v, ly = -Math.sin(pa) * u + Math.cos(pa) * v;
      al = Math.max(al, 1 - smooth(0.9, 1, Math.pow((lx - 0.48) / 0.46, 2) + Math.pow(ly / 0.22, 2)));
    }
    const heart = 1 - smooth(0.16, 0.2, r);
    return [Math.max(al, heart), heart > 0.5 ? 1 : 0.7 + 0.3 * (1 - r)];
  }],
  // --- Faction skins -------------------------------------------------------
  // Crusade sigil (original design): a ring around a flame, over a bar.
  sigil: [128, 128, (u, v) => {
    const r = Math.hypot(u, v);
    let al = 1 - smooth(0.035, 0.06, Math.abs(r - 0.86));
    al += 1 - smooth(0.015, 0.03, Math.abs(r - 0.74));
    // Flame: round below, pointed above, centred a little high.
    const fy = v - 0.1;
    const w = fy < -0.15 ? 0.3 * Math.sqrt(clamp(1 - Math.pow((fy + 0.15) / 0.3, 2)))
                         : 0.3 * Math.pow(clamp(1 - (fy + 0.15) / 0.6), 1.4);
    if (fy > -0.45 && fy < 0.45) al += 1 - smooth(w - 0.03, w, Math.abs(u));
    // Bar and post beneath the flame.
    if (Math.abs(u) < 0.42 && Math.abs(v + 0.42) < 0.045) al += 1;
    if (Math.abs(u) < 0.045 && v < -0.36 && v > -0.62) al += 1;
    return al;
  }],
  // Flame tongue: round base, pointed tip, hotter core.
  flame: [32, 64, (u, v) => {
    const w = v < -0.35 ? 0.62 * Math.sqrt(clamp(1 - Math.pow((v + 0.35) / 0.62, 2)))
                        : 0.62 * Math.pow(clamp(1 - (v + 0.35) / 1.35), 1.3);
    const inside = 1 - smooth(w * 0.8, w, Math.abs(u));
    return [inside, 1 - 0.45 * clamp(Math.abs(u) / (w || 1))];
  }],
  // Soft smoke / plague puff: three overlapping soft blobs.
  puff: [64, 64, (u, v) => {
    const blob = (cx, cy, rad) => 1 - smooth(rad * 0.4, rad, Math.hypot(u - cx, v - cy));
    return 0.85 * Math.max(blob(0, 0.05, 0.62), blob(0.35, -0.15, 0.45), blob(-0.38, -0.12, 0.42));
  }],
  // Skull: cranium, jaw, hollow eyes and nose.
  skull: [64, 64, (u, v) => {
    const head = 1 - smooth(0.52, 0.56, Math.hypot(u, (v - 0.12) * 1.05));
    const jaw = (Math.abs(u) < 0.32 && v < -0.2 && v > -0.62) ? 1 : 0;
    let al = Math.max(head, jaw);
    for (const ex of [-0.2, 0.2]) al -= 1 - smooth(0.11, 0.14, Math.hypot(u - ex, v - 0.05));
    if (v < -0.08 && v > -0.24 && Math.abs(u) < (v + 0.24) * 0.4) al = 0;   // nose
    if (v < -0.42 && v > -0.62 && Math.abs(u) < 0.3 && Math.abs((u * 6) % 1) < 0.25) al = 0; // teeth gaps
    return [clamp(al), 0.95];
  }],
  // --- PvP skins (original designs) ----------------------------------------
  // Heater shield with a cross, bevel-lit.
  shield: [64, 64, (u, v) => {
    const top = 0.78, half = 0.72;
    let w = half;
    if (v < 0.1) w = half * Math.sqrt(clamp(1 - Math.pow((0.1 - v) / 0.95, 2)));
    const inside = v < top && v > -0.88 && Math.abs(u) < w ? 1 : 0;
    const edge = inside && (Math.abs(u) > w - 0.12 || v > top - 0.12) ? 1 : 0;
    const cross = inside && (Math.abs(u) < 0.08 || Math.abs(v - 0.22) < 0.08) ? 1 : 0;
    return [inside, edge || cross ? 1 : 0.55 + 0.25 * (v + 1) / 2];
  }],
  // War ring: a thick ring crowned with ten spikes.
  spikes: [128, 128, (u, v) => {
    const [r, a] = polar(u, v);
    const ring = 1 - smooth(0.06, 0.09, Math.abs(r - 0.5));
    const seg = ((a / (Math.PI * 2)) * 10 % 1 + 1) % 1;
    const tri = 1 - Math.abs(seg - 0.5) * 2;          // 0 at the gaps, 1 mid-spike
    const spike = r > 0.55 && r < 0.55 + 0.42 * tri ? 1 : 0;
    return Math.max(ring, spike);
  }],
  // Rank chevrons: three stacked V stripes.
  chevron: [64, 64, (u, v) => {
    let al = 0;
    for (const off of [-0.45, 0, 0.45]) {
      const d = Math.abs((v - off) - (0.25 - Math.abs(u) * 0.6));
      if (Math.abs(u) < 0.8) al = Math.max(al, 1 - smooth(0.06, 0.1, d));
    }
    return al;
  }],
  // Battle flag on a pole.
  flag: [64, 64, (u, v) => {
    const pole = Math.abs(u + 0.7) < 0.06 && v > -0.95 && v < 0.9 ? 1 : 0;
    const wave = 0.08 * Math.sin((u + 0.7) * 5);
    const cloth = u > -0.66 && u < 0.85 && v > 0.05 + wave && v < 0.85 + wave ? 1 : 0;
    return [Math.max(pole, cloth), pole ? 0.7 : 1];
  }],
  // Five capture nodes on a ring.
  nodes: [128, 128, (u, v) => {
    const r = Math.hypot(u, v);
    let al = 0.6 * (1 - smooth(0.02, 0.035, Math.abs(r - 0.78)));
    for (let i = 0; i < 5; i++) {
      const a = -Math.PI / 2 + i * 2 * Math.PI / 5;
      al = Math.max(al, 1 - smooth(0.11, 0.14, Math.hypot(u - Math.cos(a) * 0.78, v - Math.sin(a) * 0.78)));
    }
    return al;
  }],
  // Crossed blades.
  blades: [128, 128, (u, v) => {
    let al = 0;
    for (const ang of [Math.PI / 4, -Math.PI / 4]) {
      const x = Math.cos(ang) * u + Math.sin(ang) * v, y = -Math.sin(ang) * u + Math.cos(ang) * v;
      const blade = y > -0.55 && y < 0.9 && Math.abs(x) < 0.07 * (y > 0.75 ? (0.9 - y) / 0.15 : 1) ? 1 : 0;
      const guard = Math.abs(y + 0.55) < 0.04 && Math.abs(x) < 0.22 ? 1 : 0;
      const grip = y < -0.55 && y > -0.85 && Math.abs(x) < 0.05 ? 1 : 0;
      al = Math.max(al, blade, guard, grip);
    }
    return al;
  }],
  // Six-armed snowflake.
  snowflake: [64, 64, (u, v) => {
    const [r, a] = polar(u, v);
    const arm = Math.abs(Math.sin(a * 3)) * r;           // distance to the nearest of 6 arms
    let al = r < 0.92 ? 1 - smooth(0.09, 0.14, arm) : 0;
    al = Math.max(al, 1 - smooth(0.16, 0.22, r));          // solid heart
    // Little side twigs two-thirds out on each arm.
    for (let i = 0; i < 6; i++) {
      const ca = i * Math.PI / 3, px = Math.cos(ca) * 0.6, py = Math.sin(ca) * 0.6;
      for (const s of [-1, 1]) {
        const ta = ca + s * Math.PI / 4;
        const dx = u - px, dy = v - py;
        const along = dx * Math.cos(ta) + dy * Math.sin(ta), across = -dx * Math.sin(ta) + dy * Math.cos(ta);
        if (along > 0 && along < 0.28) al = Math.max(al, 1 - smooth(0.05, 0.09, Math.abs(across)));
      }
    }
    return al;
  }],
  // --- Round 3 (original designs) -----------------------------------------
  // Five-pointed star.
  star: [64, 64, (u, v) => {
    const [r, a] = polar(u, -v);
    const k = Math.cos(Math.PI / 5) / Math.cos(((a + Math.PI / 2) % (2 * Math.PI / 5) + 2 * Math.PI / 5) % (2 * Math.PI / 5) - Math.PI / 5);
    return 1 - smooth(0.9, 1, r / (0.92 * (0.45 + 0.55 * Math.pow(clamp(k - 0.809) / 0.191, 1.6))));
  }],
  // Cog with twelve teeth and a hub.
  gear: [128, 128, (u, v) => {
    const [r, a] = polar(u, v);
    const tooth = (((a / (Math.PI * 2)) * 12 % 1) + 1) % 1 < 0.5 ? 0.92 : 0.74;
    const body = 1 - smooth(tooth - 0.03, tooth, r);
    const hole = 1 - smooth(0.2, 0.24, r);
    const spoke = r < 0.6 && r > 0.24 && (Math.abs(u) < 0.07 || Math.abs(v) < 0.07) ? 0 : 1;
    const window_ = r > 0.3 && r < 0.6 ? 0.35 : 1;
    return [body * (1 - hole) * Math.max(window_, 1 - spoke), 0.75 + 0.25 * (r > 0.6 ? 1 : 0.6)];
  }],
  // Soap bubble: thin rim with a highlight.
  bubble: [64, 64, (u, v) => {
    const r = Math.hypot(u, v);
    const rim = 1 - smooth(0.05, 0.1, Math.abs(r - 0.82));
    const shine = 1 - smooth(0.06, 0.14, Math.hypot(u + 0.32, v - 0.34));
    return Math.max(rim, shine, 0.12 * (r < 0.82 ? 1 : 0));
  }],
  // Bat in flight.
  bat: [64, 32, (u, v) => {
    const body = 1 - smooth(0.16, 0.2, Math.hypot(u * 1.4, v + 0.1));
    const span = Math.abs(u);
    // Flat leading edge sloping to the tip, scalloped trailing edge below.
    const wingTop = 0.55 - 0.35 * span;
    const wingBot = -0.35 + 0.5 * span - 0.22 * Math.abs(Math.sin(span * 7.85));
    const wing = span < 0.98 && v < wingTop && v > wingBot ? 1 : 0;
    const ear = Math.abs(Math.abs(u) - 0.09) < 0.05 && v > 0.05 && v < 0.35 - Math.abs(u) ? 1 : 0;
    return Math.max(body, wing, ear);
  }],
  // Jack-o'-lantern: ribbed pumpkin, stem, carved face (hollow).
  pumpkin: [64, 64, (u, v) => {
    let body = 0;
    for (const ox of [-0.32, 0, 0.32]) body = Math.max(body, 1 - smooth(0.95, 1.05, Math.hypot((u - ox) / 0.5, (v + 0.08) / 0.72)));
    const stem = Math.abs(u) < 0.08 && v > 0.55 && v < 0.88 ? 1 : 0;
    let face = 0;
    for (const ex of [-0.3, 0.3]) if (v > 0.02 && v < 0.24 && Math.abs(u - ex) < (0.24 - v) * 0.7) face = 1;
    if (v < -0.2 && v > -0.42 && Math.abs(u) < 0.42 && !(v > -0.3 && Math.abs((u * 5) % 1) < 0.2)) face = 1;
    return [Math.max(stem, body * (1 - face)), stem ? 0.55 : 0.8 + 0.2 * Math.cos(u * 9)];
  }],
  // Wrapped gift: box, ribbon cross, bow.
  gift: [64, 64, (u, v) => {
    const box = Math.abs(u) < 0.7 && v > -0.85 && v < 0.35 ? 1 : 0;
    const ribbon = box && (Math.abs(u) < 0.12 || Math.abs(v + 0.25) < 0.1) ? 1 : 0;
    let bow = 0;
    for (const s of [-1, 1]) bow = Math.max(bow, 1 - smooth(0.9, 1.05, Math.hypot((u - s * 0.25) / 0.26, (v - 0.55) / 0.17)));
    return [Math.max(box, bow), ribbon || bow ? 1 : 0.6];
  }],
  // Heart.
  heart: [64, 64, (u, v) => {
    const x = u * 1.15, y = v * 1.15 + 0.15;
    const f = Math.pow(x * x + y * y - 0.55, 3) - x * x * y * y * y;
    return f < 0 ? 1 : 1 - smooth(0, 0.004, f);
  }],
  // Voodoo hex mask: tall face, slit eyes, bared teeth.
  mask: [64, 64, (u, v) => {
    const face = 1 - smooth(0.95, 1.05, Math.hypot(u / 0.62, v / 0.95));
    let holes = 0;
    for (const ex of [-0.25, 0.25]) if (Math.abs(v - 0.2) < 0.08 - Math.abs(u - ex) * 0.25 && Math.abs(u - ex) < 0.2) holes = 1;
    if (v < -0.35 && v > -0.55 && Math.abs(u) < 0.3 && Math.abs((u * 6) % 1) > 0.25) holes = 1;
    const stripe = Math.abs(u) < 0.05 && v > 0.35 ? 1 : 0;
    return [face * (1 - holes), stripe ? 1 : 0.7 + 0.3 * (1 - Math.abs(u))];
  }],
  // Watching eye with a slit pupil.
  eye: [64, 32, (u, v) => {
    const lid = Math.abs(v) < 0.95 * Math.sqrt(clamp(1 - u * u)) ? 1 : 0;
    const pupil = Math.abs(u) < 0.12 * Math.sqrt(clamp(1 - v * v)) ? 1 : 0;
    const iris = 1 - smooth(0.4, 0.45, Math.hypot(u, v * 0.5));
    return [lid * (1 - pupil * 0.95), iris ? 1 : 0.65];
  }],
  // Beetle: shell, head, six legs.
  bug: [32, 32, (u, v) => {
    const shell = 1 - smooth(0.9, 1.05, Math.hypot(u / 0.38, (v + 0.1) / 0.62));
    const head = 1 - smooth(0.17, 0.21, Math.hypot(u, v - 0.6));
    let legs = 0;
    for (const ly of [-0.35, -0.05, 0.25]) for (const s of [-1, 1]) {
      const d = segDist(u, v, s * 0.3, ly, s * 0.8, ly + 0.15);
      legs = Math.max(legs, 1 - smooth(0.04, 0.07, d));
    }
    const seam = Math.abs(u) < 0.03 && v < 0.45 ? 1 : 0;
    return [Math.max(shell, head, legs), seam ? 0.5 : 0.9];
  }],
  // Water droplet.
  drop: [32, 64, (u, v) => {
    const w = v < -0.35 ? 0.6 * Math.sqrt(clamp(1 - Math.pow((v + 0.35) / 0.6, 2)))
                        : 0.6 * Math.pow(clamp(1 - (v + 0.35) / 1.3), 1.2);
    const inside = 1 - smooth(w * 0.85, w, Math.abs(u));
    const shine = 1 - smooth(0.06, 0.12, Math.hypot(u + 0.2, v + 0.35));
    return [Math.max(inside, shine), 0.75 + 0.25 * shine];
  }],
  // Five tally marks: four strokes and a slash.
  tally: [64, 64, (u, v) => {
    let al = 0;
    for (let i = 0; i < 4; i++) al = Math.max(al, 1 - smooth(0.05, 0.08, segDist(u, v, -0.55 + i * 0.32, -0.7, -0.5 + i * 0.32, 0.7)));
    al = Math.max(al, 1 - smooth(0.05, 0.08, segDist(u, v, -0.85, -0.5, 0.7, 0.45)));
    return al;
  }],
  // --- Spec variants (original designs) -----------------------------------
  // Three parallel claw rakes, tapered at both ends.
  claws: [128, 128, (u, v) => {
    let al = 0;
    for (const off of [-0.32, 0, 0.32]) {
      const x = (u - off) * Math.cos(0.6) - v * Math.sin(0.6), y = (u - off) * Math.sin(0.6) + v * Math.cos(0.6);
      const len = 0.85, t = clamp(1 - Math.abs(y) / len);
      if (Math.abs(y) < len) al = Math.max(al, 1 - smooth(0.05 * t, 0.075 * t + 0.005, Math.abs(x)));
    }
    return al;
  }],
  // Crescent moon.
  moon: [64, 64, (u, v) => {
    const outer = 1 - smooth(0.82, 0.88, Math.hypot(u, v));
    const bite = 1 - smooth(0.66, 0.72, Math.hypot(u - 0.36, v - 0.2));
    return [clamp(outer - bite), 0.85 + 0.15 * (u < 0 ? 1 : 0)];
  }],
  // Round bark shield: wood grain lines on a disc.
  bark: [64, 64, (u, v) => {
    const r = Math.hypot(u, v);
    const disc = 1 - smooth(0.86, 0.92, r);
    const grain = 0.5 + 0.5 * Math.sin((u + 0.08 * Math.sin(v * 5)) * 22);
    const rim = r > 0.74 ? 1 : 0;
    return [disc, rim ? 0.55 : 0.6 + 0.3 * grain];
  }],
  // --- Profession skins (original designs) ---------------------------------
  // Round-bottomed flask with a neck; liquid shaded lighter below the line.
  flask: [64, 64, (u, v) => {
    const bulb = 1 - smooth(0.52, 0.58, Math.hypot(u, v + 0.3));
    const neck = (Math.abs(u) < 0.16 && v > 0 && v < 0.78) ? 1 : 0;
    const lip = (Math.abs(u) < 0.26 && v > 0.7 && v < 0.84) ? 1 : 0;
    const al = Math.max(bulb, neck, lip);
    return [al, v < -0.25 ? 1 : 0.55];
  }],
  // Anvil: flat face, horn to the left, waist and foot.
  anvil: [64, 32, (u, v) => {
    const face = (u > -0.55 && u < 0.85 && v > 0.25 && v < 0.75) ? 1 : 0;
    const horn = (u <= -0.55 && u > -0.98 && v > 0.25 + (-0.55 - u) * 0.7 && v < 0.75) ? 1 : 0;
    const waist = (Math.abs(u - 0.15) < 0.28 && v > -0.4 && v <= 0.25) ? 1 : 0;
    const foot = (Math.abs(u - 0.15) < 0.6 && v > -0.85 && v <= -0.4) ? 1 : 0;
    return [Math.max(face, horn, waist, foot), v > 0.6 ? 1 : 0.7];
  }],
  // Dashed stitching around a rounded patch.
  stitch: [128, 64, (u, v) => {
    const d = roundBox(u, v, 0.86, 0.72, 0.18);
    const line = 1 - smooth(0.02, 0.045, Math.abs(d));
    const along = Math.abs(u) / 0.86 > Math.abs(v) / 0.72 ? v * 3.4 : u * 3.4;
    const dash = Math.sin(along * Math.PI * 2) > -0.2 ? 1 : 0;
    return line * dash;
  }],
  // A curved knife stroke, thick in the middle and tapered to points.
  arc: [128, 128, (u, v) => {
    const [r, a] = polar(u, v + 0.6);
    const t = (a - 0.35) / (Math.PI - 0.7);
    if (t < 0 || t > 1) return 0;
    const w = 0.07 * Math.sin(t * Math.PI);
    return 1 - smooth(w * 0.6, w + 0.01, Math.abs(r - 1.05));
  }],
  // Flat elliptical ripple ring.
  ripple: [128, 64, (u, v) => {
    const r = Math.hypot(u, v);
    return 1 - smooth(0.035, 0.08, Math.abs(r - 0.82));
  }],
  // Fishing bobber: a ball (darker top half) with a short quill.
  bobber: [32, 32, (u, v) => {
    const ball = 1 - smooth(0.5, 0.6, Math.hypot(u, v + 0.15));
    const quill = (Math.abs(u) < 0.08 && v > 0.3 && v < 0.9) ? 1 : 0;
    return [Math.max(ball, quill), quill ? 0.8 : (v > -0.15 ? 0.45 : 1)];
  }],
  // Leaping fish silhouette with a forked tail, head up (particles fly it
  // head first along their path).
  fish: [32, 64, (x, y) => {
    const u = -y, v = x;
    const body = 1 - smooth(0.9, 1.0, Math.hypot((u + 0.15) / 0.62, v / 0.5));
    const tx = u - 0.5;
    const tail = (tx > 0 && tx < 0.45 && Math.abs(v) < tx * 1.6 && Math.abs(v) > tx * 0.5) ? 1 : 0;
    const eye = Math.hypot(u + 0.55, v - 0.1) < 0.07 ? 0.3 : 1;
    return [Math.max(body, tail), eye];
  }],
  // Plain plus sign.
  cross: [32, 32, (u, v) => {
    const bar = (a, b) => (Math.abs(a) < 0.24 && Math.abs(b) < 0.78) ? 1 : 0;
    return Math.max(bar(u, v), bar(v, u));
  }],
  // Bandage strip: soft edges, stitched border, faint weave.
  bandage: [128, 32, (u, v) => {
    const band = (1 - smooth(0.9, 0.98, Math.abs(u))) * (1 - smooth(0.62, 0.72, Math.abs(v)));
    const edge = Math.abs(Math.abs(v) - 0.5) < 0.06 && Math.sin(u * 40) > 0 ? 0.7 : 1;
    const weave = 0.9 + 0.1 * Math.sin(u * 90) * Math.sin(v * 30);
    return [band, edge * weave];
  }],
  // A ribbon of cloth: a wavy band with a light fold line.
  ribbon: [128, 32, (u, v) => {
    const mid = Math.sin(u * Math.PI * 1.5) * 0.35;
    const d = Math.abs(v - mid);
    const band = (1 - smooth(0.32, 0.4, d)) * (1 - smooth(0.88, 0.98, Math.abs(u)));
    return [band, 0.7 + 0.3 * Math.cos(u * Math.PI * 1.5)];
  }],
  // Wavy thread.
  thread: [128, 32, (u, v) => {
    const y = Math.sin(u * Math.PI * 3) * 0.55;
    return (1 - smooth(0.05, 0.11, Math.abs(v - y))) * (1 - smooth(0.9, 0.99, Math.abs(u)));
  }],
  // A curling stem with two leaves, growing up from the bottom.
  sprout: [64, 64, (u, v) => {
    const sx = 0.18 * Math.sin((v + 1) * 2.2);
    const stem = (v < 0.75) ? 1 - smooth(0.04, 0.08, Math.abs(u - sx)) : 0;
    const leaf = (cx, cy, dir) => {
      const x = (u - cx) * dir, y = v - cy;
      const rx = x * Math.cos(0.5) + y * Math.sin(0.5), ry = -x * Math.sin(0.5) + y * Math.cos(0.5);
      return 1 - smooth(0.9, 1.0, Math.hypot(rx / 0.32, ry / 0.13));
    };
    return Math.max(stem, leaf(0.3, 0.15, 1), leaf(-0.28, -0.25, -1), leaf(0.1, 0.78, 1) * 0.9);
  }],
  // --- Loot and set skins (original designs) -------------------------------
  // Cut gem: a kite shape with facet lines, the table lighter.
  gem: [64, 64, (u, v) => {
    const top = v > 0.3;
    const inside = top ? (Math.abs(u) < 0.8 - (v - 0.3) * 1.0 && v < 0.82) : (Math.abs(u) < 0.8 * (v + 0.95) / 1.25 && v > -0.95);
    if (!inside) return 0;
    const facet = Math.abs(v - 0.3) < 0.035 || Math.abs(u) < 0.03 || Math.abs(Math.abs(u) - (v + 0.95) * 0.32) < 0.03;
    return [1, facet ? 1 : (top ? 0.85 : 0.6 + 0.25 * (u > 0 ? 1 : 0))];
  }],
  // Three motes spaced round a circle (spun as a whole: an orbiting aura).
  orbit: [64, 64, (u, v) => {
    let al = 0;
    for (let i = 0; i < 3; i++) {
      const a = i / 3 * Math.PI * 2;
      al = Math.max(al, 1 - smooth(0.06, 0.13, Math.hypot(u - Math.cos(a) * 0.78, v - Math.sin(a) * 0.78)));
    }
    return al;
  }],
  // Eight armor-piece pips round a ring.
  setring: [128, 128, (u, v) => {
    let al = 0;
    for (let i = 0; i < 8; i++) {
      const a = i / 8 * Math.PI * 2 + Math.PI / 8;
      const x = u - Math.cos(a) * 0.8, y = v - Math.sin(a) * 0.8;
      const rx = x * Math.cos(a) + y * Math.sin(a), ry = -x * Math.sin(a) + y * Math.cos(a);
      al = Math.max(al, (Math.abs(rx) < 0.1 && Math.abs(ry) < 0.1) ? 1 : 0);
    }
    const ring = (1 - smooth(0.015, 0.035, Math.abs(Math.hypot(u, v) - 0.8))) * 0.6;
    return Math.max(al, ring);
  }],
  // --- Rank 13 and secret skins (original designs) ---------------------------
  // Laurel wreath: two curved rows of leaves, open at the top.
  laurel: [64, 64, (u, v) => {
    let al = 0;
    for (const side of [-1, 1]) {
      for (let i = 0; i < 7; i++) {
        const a = -Math.PI / 2 + side * (0.35 + i * 0.36);
        const cx = Math.cos(a) * 0.72, cy = Math.sin(a) * 0.72;
        const x = u - cx, y = v - cy, ang = a + side * Math.PI / 2;
        const rx = x * Math.cos(ang) + y * Math.sin(ang), ry = -x * Math.sin(ang) + y * Math.cos(ang);
        al = Math.max(al, 1 - smooth(0.85, 1, Math.hypot(rx / 0.17, ry / 0.08)));
      }
    }
    return al;
  }],
  // A d20 seen face-on: a hexagon split into facets.
  d20: [64, 64, (u, v) => {
    const r = Math.max(Math.abs(u) * 0.866 + Math.abs(v) * 0.5, Math.abs(v));
    if (r > 0.9) return 0;
    const edge = r > 0.84 ? 1 : 0;
    const inner = Math.abs(v + 0.15) < 0.03 && Math.abs(u) < 0.5 || Math.abs(v - (0.62 - Math.abs(u) * 1.55)) < 0.035 && v > -0.2;
    const face = v > -0.15 && v < 0.62 - Math.abs(u) * 1.55 ? 1 : 0.7;
    return [1, edge || inner ? 1 : 0.55 * face + 0.15];
  }],
  // Neon sun: a disc banded with gaps toward the bottom (tinted in game).
  synthsun: [64, 64, (u, v) => {
    const disc = 1 - smooth(0.86, 0.92, Math.hypot(u, v));
    if (v < 0) {
      const stripe = (v + 1) * 6;
      if (stripe % 1 < (0.15 + -v * 0.35)) return 0;
    }
    return [disc, 0.6 + 0.4 * (v + 1) / 2];
  }],
  // Perspective grid: lines converging to the horizon, rows bunching up.
  synthgrid: [128, 64, (u, v) => {
    if (v > 0.6) return 0;
    const depth = (0.6 - v) / 1.6;
    const x = u / (0.15 + depth);
    const vert = Math.abs(x * 3 - Math.round(x * 3)) < 0.06 / (0.3 + depth) ? 1 : 0;
    const row = Math.abs(Math.log(depth + 0.05) * 4 % 1) < 0.08 ? 1 : 0;
    const horizon = Math.abs(v - 0.6) < 0.025 ? 1 : 0;
    return Math.max(vert, row, horizon) * (0.4 + 0.6 * depth);
  }],
  // Disco ball: a sphere of mirror tiles, one bright highlight.
  discoball: [64, 64, (u, v) => {
    const r = Math.hypot(u, v);
    if (r > 0.88) return 0;
    const z = Math.sqrt(Math.max(0, 1 - (r / 0.88) ** 2));
    const lon = Math.atan2(u, z) * 6, lat = Math.asin(v / 0.88) * 6;
    const grout = Math.abs(lon - Math.round(lon)) < 0.08 || Math.abs(lat - Math.round(lat)) < 0.08;
    const shine = Math.max(0, 1 - Math.hypot(u + 0.3, v - 0.35) * 2.5);
    return [1, grout ? 0.25 : 0.55 + 0.45 * shine + 0.15 * ((Math.round(lon) + Math.round(lat)) % 2)];
  }],
  // Coiled spring, seen from the side.
  spring: [32, 64, (u, v) => {
    const t = (v + 0.9) / 1.8;
    if (t < 0 || t > 1) return 0;
    const x = Math.sin(t * Math.PI * 12) * 0.62;
    const back = Math.cos(t * Math.PI * 12) < 0;
    return [1 - smooth(0.1, 0.18, Math.abs(u - x)), back ? 0.55 : 1];
  }],
  // Rounded tombstone with a cross carved in.
  tombstone: [48, 64, (u, v) => {
    const body = (Math.abs(u) < 0.62 && v < 0.35 && v > -0.95) || Math.hypot(u, (v - 0.35) / 1.0) < 0.62;
    if (!body) return 0;
    const cross = (Math.abs(u) < 0.07 && v > -0.35 && v < 0.55) || (Math.abs(v - 0.28) < 0.07 && Math.abs(u) < 0.27);
    return [1, cross ? 0.35 : 0.8];
  }],
  // --- Anime and music skins (original designs) -----------------------------
  // Rising energy aura: a round base that wraps the number, tapering up
  // into a flickering flame tip.
  aura: [64, 96, (u, v) => {
    const y = (v + 1) / 2;                       // 0 bottom .. 1 top
    let body;
    if (y < 0.32) body = 0.9 * Math.sqrt(Math.max(0, 1 - ((0.32 - y) / 0.32) ** 2));
    else body = 0.9 * Math.pow(1 - (y - 0.32) / 0.68, 0.9);
    body += 0.1 * Math.max(0, Math.sin(u * 12 + y * 9)) * Math.min(1, y * 2);
    const edge = Math.abs(u) / Math.max(0.01, body);
    if (edge > 1) return 0;
    return [1 - smooth(0.65, 1, edge) * 0.75, 0.5 + 0.5 * (1 - edge)];
  }],
  // Cut-in band: a long flat bar with dark rims.
  band: [128, 32, (u, v) => {
    const body = (1 - smooth(0.92, 0.99, Math.abs(u))) * (Math.abs(v) < 0.8 ? 1 : 0);
    return [body, Math.abs(v) > 0.62 ? 0.15 : 1];
  }],
  // Speed lines: horizontal streaks of varied length.
  speedlines: [128, 64, (u, v) => {
    const row = Math.floor((v + 1) * 6);
    const len = 0.35 + ((row * 37) % 10) / 16;
    const off = ((row * 53) % 10) / 20 - 0.25;
    const inLine = Math.abs(((v + 1) * 6) % 1 - 0.5) < 0.12;
    return inLine && u > off - len / 2 && u < off + len / 2 ? 1 - smooth(off + len / 2 - 0.15, off + len / 2, u) : 0;
  }],
  // Cherry petal: a rounded petal with a notch at the tip.
  petal: [32, 32, (u, v) => {
    const body = 1 - smooth(0.9, 1, Math.hypot(u / 0.62, (v + 0.05) / 0.85));
    const notch = Math.hypot(u, v - 0.82) < 0.22 ? 0 : 1;
    return [body * notch, 0.75 + 0.25 * (1 - Math.hypot(u, v))];
  }],
  // HUD brackets: four corner marks around a target.
  brackets: [64, 48, (u, v) => {
    const t = 0.07, l = 0.32;
    const cx = Math.abs(u) > 0.92 - t && Math.abs(u) < 0.92 && Math.abs(v) > 0.88 - l && Math.abs(v) < 0.88;
    const cy = Math.abs(v) > 0.88 - t * 1.4 && Math.abs(v) < 0.88 && Math.abs(u) > 0.92 - l && Math.abs(u) < 0.92;
    return cx || cy ? 1 : 0;
  }],
  // Equalizer: nine bars of different heights.
  eqbars: [128, 64, (u, v) => {
    const i = Math.floor((u + 1) / 2 * 9);
    const cx = -1 + (i + 0.5) * 2 / 9;
    if (Math.abs(u - cx) > 0.075) return 0;
    const h = [0.35, 0.7, 0.5, 0.95, 0.6, 0.85, 0.4, 0.65, 0.3][i] * 2 - 1;
    if (v > h || v < -1) return 0;
    const seg = ((v + 1) * 8) % 1 < 0.2 ? 0.4 : 1;
    return [1, seg * (0.6 + 0.4 * (v + 1) / 2)];
  }],
  // Vinyl record: grooves, a label and a spindle hole.
  vinyl: [64, 64, (u, v) => {
    const r = Math.hypot(u, v);
    if (r > 0.92 || r < 0.05) return 0;
    if (r < 0.32) return [1, 1];
    const groove = 0.18 + 0.12 * (Math.sin(r * 90) > 0 ? 1 : 0);
    const shine = Math.abs(Math.sin(Math.atan2(v, u) * 2)) > 0.92 ? 0.35 : 0;
    return [1, groove + shine];
  }],
  // Eighth note.
  note: [32, 48, (u, v) => {
    const head = 1 - smooth(0.85, 1, Math.hypot((u + 0.25) / 0.45, (v + 0.62) / 0.3));
    const stem = Math.abs(u - 0.17) < 0.07 && v > -0.62 && v < 0.85 ? 1 : 0;
    const flag = v > 0.35 && v < 0.85 && u > 0.17 && u < 0.17 + (0.85 - v) * 0.9 && u > 0.17 + (v - 0.35) * 0.6 ? 1 : 0;
    return Math.max(head, stem, flag);
  }],
  // Microphone on a short stand.
  mic: [32, 64, (u, v) => {
    const head = Math.hypot(u / 0.5, (v - 0.55) / 0.36) < 1;
    const handle = Math.abs(u) < 0.2 - (0.55 - v) * 0.1 && v < 0.3 && v > -0.6;
    const base = Math.abs(u) < 0.55 && v > -0.9 && v < -0.78;
    const grille = head && (Math.sin(u * 30) > 0.6 || Math.sin(v * 30) > 0.6) ? 0.7 : 1;
    return head || handle || base ? [1, head ? grille : 0.8] : 0;
  }],
  // Four-point twinkle.
  twinkle: [64, 64, (u, v) => {
    const r = Math.hypot(u, v);
    const cross = Math.exp(-Math.abs(u) * 14) * (1 - Math.abs(v)) + Math.exp(-Math.abs(v) * 14) * (1 - Math.abs(u));
    return cross + (1 - smooth(0, 0.25, r));
  }],
  // --- Pieces for the 1.5 redesigns (original designs) ---------------------
  // Storm cloud: overlapping puffs, darker underneath.
  cloud: [128, 64, (u, v) => {
    const X = u * 2, Y = v;
    let al = 0;
    for (const [bx, by, br] of [[-1.15, -0.2, 0.62], [-0.45, 0.2, 0.78], [0.4, 0.15, 0.72], [1.15, -0.2, 0.58], [0, -0.32, 0.62]]) {
      al = Math.max(al, 1 - smooth(br * 0.82, br, Math.hypot(X - bx, Y - by)));
    }
    return [al, 0.5 + 0.5 * clamp((Y + 0.8) / 1.6)];
  }],
  // Arrow pointing right: head, shaft, fletching.
  arrow: [128, 32, (u, v) => {
    const X = u * 4, Y = Math.abs(v);
    if (X > 2.35 && X < 3.95 && Y < (3.95 - X) / 1.6 * 0.85) return [1, 1];
    if (X > -3.3 && X <= 2.4 && Y < 0.13) return [1, 0.72];
    const s = X + 3.9 - (Y - 0.1) * 0.9;
    if (Y > 0.1 && Y < 0.8 && s > 0 && s < 1.1) return [1, 0.92];
    return 0;
  }],
  // A soft glint band (swept across a number).
  glint: [64, 128, (u, v) => {
    const ends = 1 - smooth(0.55, 1, Math.abs(v));
    return (0.55 * Math.exp(-Math.pow(u / 0.32, 2)) + Math.exp(-Math.pow(u / 0.08, 2))) * ends;
  }],
  // War banner: cloth with a swallowtail, a lighter trim and soft folds.
  banner: [64, 128, (u, v) => {
    const bottom = -0.97 + 0.38 * (1 - Math.abs(u) / 0.82);
    if (Math.abs(u) > 0.82 || v < bottom || v > 0.97) return 0;
    const edge = Math.min(0.82 - Math.abs(u), v - bottom, 0.97 - v);
    const trim = edge < 0.09;
    return [1, trim ? 1 : 0.55 * (0.85 + 0.15 * Math.sin(u * 7))];
  }],
  // Longsword, tip up: blade with a fuller, crossguard, grip, pommel.
  sword: [32, 128, (u, v) => {
    const X = u, Y = v * 4;
    const half = 0.26 * Math.min(1, (3.95 - Y) / 0.7);
    if (Y > -1.45 && Y < 3.95 && Math.abs(X) < half) return [1, Math.abs(X) < 0.05 ? 0.7 : 1];
    if (Math.abs(Y + 1.6) < 0.15 && Math.abs(X) < 0.9) return [1, 0.82];
    if (Math.abs(X) < 0.13 && Y < -1.6 && Y > -3.3) return [1, 0.45];
    if (Math.hypot(X, Y + 3.5) < 0.26) return [1, 0.82];
    return 0;
  }],
  // Spear, head up: leaf-shaped head, tassel, long shaft.
  spear: [32, 128, (u, v) => {
    const X = Math.abs(u), Y = v * 4;
    if (Y > 2.3 && Y < 3.95) { const q = (Y - 2.3) / 1.65; if (X < 0.5 * Math.pow(Math.sin(Math.PI * q), 0.7) * (1 - 0.45 * q) + 0.06) return [1, 1]; }
    if (Y > 1.55 && Y < 2.3 && X < 0.32 * (2.3 - Y) / 0.75 + 0.05 && Math.sin(u * 40) > -0.4) return [1, 0.62];
    if (X < 0.09 && Y > -4 && Y <= 2.35) return [1, 0.5];
    return 0;
  }],
  // A stroke of war paint: thick, ragged, dry at the tail.
  brush: [128, 32, (u, v) => {
    const X = u * 4;
    const half = 0.78 * smooth(-4, -3.1, X) * (1 - 0.55 * smooth(1.5, 4, X)) + 0.06 * Math.sin(X * 6.3);
    if (Math.abs(v) > half) return 0;
    const dry = 1 - smooth(2.2, 3.9, X) * (0.5 + 0.5 * Math.sin(v * 38));
    return [clamp(dry), 0.75 + 0.25 * Math.sin(v * 31 + X)];
  }],
  // A wing spreading left from its shoulder (right, low): five long feathers.
  wingleft: [64, 64, (u, v) => {
    let al = 0, lum = 0.9;
    for (let j = 0; j < 5; j++) {
      const th = Math.PI - 0.05 - j * 0.26, L = 1.7 - j * 0.12, sx = 0.85, sy = -0.3;
      const dx = Math.cos(th), dy = Math.sin(th), px = u - sx, py = v - sy;
      const along = px * dx + py * dy, across = -px * dy + py * dx;
      const f = Math.pow((along - L / 2) / (L / 2), 2) + Math.pow(across / 0.17, 2);
      const a = 1 - smooth(0.5, 1, f);
      if (a > al) { al = a; lum = (j % 2 ? 0.75 : 0.9) * (0.65 + 0.35 * clamp(along / L)); }
    }
    return [al, lum];
  }],
  wingright: [64, 64, (u, v) => TEXTURES.wingleft[2](-u, v)],
  // A curling vine growing up from the bottom right, with two leaves.
  vineleft: [64, 128, (() => {
    const pts = [];
    for (let s = 0; s <= 0.82; s += 0.02) pts.push([0.55 - 0.95 * s + 0.22 * Math.sin(s * 6), -1.95 + 3.3 * s]);
    const [ex, ey] = pts[pts.length - 1];
    for (let q = 0; q <= 1.6; q += 0.05) pts.push([ex - 0.22 + Math.cos(q * 4) * 0.22 * (1 - q / 2), ey + Math.sin(q * 4) * 0.22 * (1 - q / 2)]);
    const leaf = (X, Y, cx, cy, rot) => {
      const rx = (X - cx) * Math.cos(rot) + (Y - cy) * Math.sin(rot), ry = -(X - cx) * Math.sin(rot) + (Y - cy) * Math.cos(rot);
      return 1 - smooth(0.85, 1, Math.hypot(rx / 0.3, ry / 0.12));
    };
    return (u, v) => {
      const X = u, Y = v * 2;
      let d = 9;
      for (let i = 0; i < pts.length - 1; i++) d = Math.min(d, segDist(X, Y, pts[i][0], pts[i][1], pts[i + 1][0], pts[i + 1][1]));
      const stem = 1 - smooth(0.06, 0.1, d);
      const lv = Math.max(leaf(X, Y, 0.55, -0.85, 0.5), leaf(X, Y, -0.55, 0.15, -0.5));
      return [Math.max(stem, lv), lv > stem ? 1 : 0.7];
    };
  })()],
  vineright: [64, 128, (u, v) => TEXTURES.vineleft[2](-u, v)],
};

// --- Anime-inspired skins (original designs) ----------------------------------
// A polyline's distance (for stroked marks).
const polyDist = (u, v, pts) => {
  let d = Infinity;
  for (let i = 0; i < pts.length - 1; i++) d = Math.min(d, segDist(u, v, pts[i][0], pts[i][1], pts[i + 1][0], pts[i + 1][1]));
  return d;
};
// Their own generator (32-bit, mulberry32): rand() above loses precision
// after many calls, and the older textures must not change.
let seed2 = 2024;
const rand2 = () => {
  seed2 = (seed2 + 0x6D2B79F5) >>> 0;
  let t = seed2;
  t = Math.imul(t ^ (t >>> 15), t | 1);
  t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
};
// Lines from the center out, each at its own angle, width and start.
const radialLines = Array.from({ length: 46 }, () => [rand2() * Math.PI * 2, 0.006 + rand2() * 0.016, 0.42 + rand2() * 0.25]);
// A jagged comic starburst: ten long points with deep notches between.
const impactPts = Array.from({ length: 20 }, (_, i) => i % 2 ? 0.3 + rand2() * 0.12 : 0.72 + rand2() * 0.26);
Object.assign(TEXTURES, {
  // Wanted poster: ragged parchment, a dark border, a frame for the face
  // (the number) and lines of small print below.
  poster: [64, 80, (u, v) => {
    const ex = 0.9 + 0.04 * Math.sin(v * 23) + 0.03 * Math.sin(u * 31), ey = 0.93 + 0.03 * Math.sin(u * 19);
    if (Math.abs(u) > ex || Math.abs(v) > ey) return 0;
    const border = Math.abs(u) > ex - 0.1 || Math.abs(v) > ey - 0.1;
    const frame = Math.abs(u) < 0.74 && v > -0.52 && v < 0.42 && (Math.abs(u) > 0.68 || v < -0.46 || v > 0.36);
    const print = v < -0.62 && v > -0.78 && Math.abs(u) < 0.6 && Math.sin(u * 40) > -0.4;
    return [1, border ? 0.6 : frame || print ? 0.42 : 0.92 + 0.06 * Math.sin(u * 7 + v * 5)];
  }],
  // Crescent wave: a moon-shaped blade of energy opening to the left (it
  // sweeps right), dark inside with a bright leading edge.
  crescent: [64, 128, (u, v) => {
    const outer = Math.hypot((u + 0.55) / 1.45, v / 0.95);
    const inner = Math.hypot((u + 1.15) / 1.45, v / 1.05);
    const a = (1 - smooth(0.96, 1.0, outer)) * smooth(0.98, 1.02, inner);
    if (a <= 0) return 0;
    return [a, 1 - smooth(0.86, 0.95, outer) > 0.5 ? 0.12 : 1];
  }],
  // Kunai: a leaf blade with a centre ridge, a wrapped grip and a ring.
  kunai: [32, 64, (u, v) => {
    const hw = v < 0.3 ? 0.62 * clamp((v - 0.02) / 0.28) : 0.62 * clamp((0.95 - v) / 0.65);
    if (v > 0.02 && Math.abs(u) < hw) return [1, u < 0 ? 1 : 0.7];
    if (Math.abs(u) < 0.16 && v > -0.62 && v <= 0.02) return [1, Math.sin(v * 40) > 0 ? 0.35 : 0.5];
    const ring = Math.abs(Math.hypot(u / 2, v + 0.78) - 0.13);
    return ring < 0.035 ? [1, 0.75] : 0;
  }],
  // Spiral orb: three arms swirling into a bright core.
  spiralorb: [128, 128, (u, v) => {
    const [r, a] = polar(u, v);
    if (r > 0.95) return 0;
    const arms = Math.pow(0.5 + 0.5 * Math.sin(a * 3 - r * 9), 3);
    return clamp((arms * 0.8 + (1 - smooth(0, 0.45, r))) * (1 - smooth(0.7, 0.95, r)));
  }],
  // Rumble mark: a heavy zigzag stroke with two dots, drifting beside an
  // ominous number.
  rumble: [64, 64, (u, v) => {
    const d = polyDist(u, v, [[-0.3, 0.86], [0.32, 0.52], [-0.32, 0.16], [0.32, -0.2], [-0.32, -0.56], [0.2, -0.88]]);
    const dots = Math.min(Math.hypot(u - 0.62, v - 0.78), Math.hypot(u - 0.82, v - 0.56));
    return Math.max(1 - smooth(0.1, 0.14, d), 1 - smooth(0.08, 0.11, dots));
  }],
  // Woodblock wave: a curling crest over a striped swell, foam lines
  // running along the curl.
  wavecurl: [128, 128, (u, v) => {
    let best = 0, lum = 0.5;
    const [r, a] = polar(u - 0.05, v + 0.05);
    const base = ((Math.PI - a) % (Math.PI * 2) + Math.PI * 2) % (Math.PI * 2);
    for (let k = 0; k < 2; k++) {
      const th = base + k * Math.PI * 2;
      if (th > Math.PI * 2.6) continue;
      const R = 0.84 * Math.exp(-0.2 * th), w = 0.2 * Math.exp(-0.2 * th);
      const q = (r - R) / w;
      if (Math.abs(q) < 1) {
        const al = 1 - smooth(0.85, 1, Math.abs(q));
        if (al > best) { best = al; lum = Math.sin(q * Math.PI * 2.5) > 0.3 ? 1 : 0.5; }
      }
    }
    const swell = -0.55 + 0.08 * Math.sin(u * 8);
    if (v < swell && v > -0.98) { best = 1; lum = Math.sin(v * 40) > 0.4 ? 1 : 0.5; }
    return best > 0 ? [best, lum] : 0;
  }],
  // Monster capsule, two halves (tinted apart in game): a dark rim, a
  // band between them and a button in the middle.
  capsuletop: [64, 64, (u, v) => {
    const r = Math.hypot(u, v);
    if (r > 0.86 || v < 0.07) return 0;
    const b = Math.hypot(u, v - 0.0);
    if (b < 0.26) return b < 0.15 ? [1, 0.95] : [1, 0.18];
    return [1, r > 0.78 ? 0.2 : 0.8 + 0.2 * clamp(1 - Math.hypot(u + 0.35, v - 0.5) * 2)];
  }],
  capsulebot: [64, 64, (u, v) => {
    const r = Math.hypot(u, v);
    if (r > 0.86 || v > 0.07) return 0;
    const b = Math.hypot(u, v);
    if (b < 0.26) return b < 0.15 ? [1, 0.95] : [1, 0.18];
    return [1, r > 0.78 || v > -0.07 ? 0.2 : 0.95];
  }],
  // Soot sprite: a spiky fuzzball with two big eyes.
  soot: [64, 64, (u, v) => {
    const [r, a] = polar(u, v);
    const edge = 0.62 + 0.09 * Math.sin(a * 13) + 0.05 * Math.sin(a * 29 + 1);
    const body = 1 - smooth(edge - 0.04, edge + 0.02, r);
    if (body <= 0) return 0;
    const eye = Math.min(Math.hypot(u + 0.24, v - 0.06), Math.hypot(u - 0.24, v - 0.06)) < 0.17;
    const pupil = Math.hypot(u + 0.2, v + 0.0) < 0.075 || Math.hypot(u - 0.28, v + 0.0) < 0.075;
    return [body, pupil ? 0 : eye ? 1 : 0.07];
  }],
  // Transmutation circle: two rings, a square and a triangle inscribed,
  // a small inner ring and ticks between the rings.
  alchemy: [128, 128, (u, v) => {
    const [r, a] = polar(u, v);
    const line = (d, w) => 1 - smooth(w * 0.6, w, d);
    let al = Math.max(line(Math.abs(r - 0.92), 0.03), line(Math.abs(r - 0.78), 0.022), line(Math.abs(r - 0.3), 0.02));
    const sq = [0, 1, 2, 3, 0].map(i => [Math.cos(Math.PI / 4 + i * Math.PI / 2) * 0.78, Math.sin(Math.PI / 4 + i * Math.PI / 2) * 0.78]);
    const tri = [0, 1, 2, 0].map(i => [Math.cos(Math.PI / 2 + i * Math.PI * 2 / 3) * 0.78, Math.sin(Math.PI / 2 + i * Math.PI * 2 / 3) * 0.78]);
    al = Math.max(al, line(polyDist(u, v, sq), 0.02), line(polyDist(u, v, tri), 0.02));
    const tick = ((a / (Math.PI * 2) * 16) % 1 + 1) % 1;
    if (r > 0.8 && r < 0.9 && Math.abs(tick - 0.5) < 0.06) al = 1;
    return al;
  }],
  // Notebook page: ruled lines, a margin, a torn bottom edge.
  notepage: [128, 64, (u, v, w, h) => {
    if (Math.abs(u) > 0.97) return 0;
    const tear = -0.78 + 0.24 * Math.abs(((u + 1) * 7) % 1 - 0.5) + 0.03 * Math.sin(u * 41);
    if (v < tear || v > 0.92) return 0;
    const py = (v + 1) * h / 2;
    const rule = Math.abs((py % 10) - 5) < 0.6 && v < 0.75;
    return [1, Math.abs(u + 0.72) < 0.012 ? 0.5 : rule ? 0.7 : 0.97];
  }],
  // Wish orb: a shaded sphere with a darker star inside and a highlight.
  starorb: [64, 64, (u, v) => {
    const [r, a] = polar(u, v);
    if (r > 0.86) return 0;
    const pts = 0.15 + 0.24 * Math.pow(Math.abs(Math.cos(2.5 * (a - Math.PI / 2))), 6);
    const shine = clamp(1 - Math.hypot(u + 0.32, v - 0.36) * 3);
    return [1 - smooth(0.82, 0.86, r), r < pts ? 0.35 : 0.72 + 0.28 * shine];
  }],
  // Barrier hexagon: a bright edge over a faint fill.
  hex: [64, 64, (u, v) => {
    const d = Math.max(Math.abs(u), Math.abs(u) * 0.5 + Math.abs(v) * 0.866);
    if (d > 0.92) return 0;
    return Math.max(0.18, 1 - smooth(0.04, 0.08, Math.abs(d - 0.86)));
  }],
  // Saw ring: a hollow blade with raked teeth.
  sawring: [128, 128, (u, v) => {
    const [r, a] = polar(u, v);
    const tooth = ((a / (Math.PI * 2) * 24) % 1 + 1) % 1;
    const out = 0.76 + 0.18 * tooth;
    if (r > out || r < 0.58) return 0;
    return [1 - smooth(out - 0.02, out, r), r > 0.76 ? 1 : (r < 0.62 ? 0.4 : 0.75)];
  }],
  // Drill: a cone with spiral flutes.
  drill: [64, 128, (u, v) => {
    const t = (v + 0.92) / 1.85;
    if (t < 0 || t > 1) return 0;
    const hw = 0.92 * (1 - t);
    if (Math.abs(u) > hw) return 0;
    const flute = ((v * 4 + u / Math.max(0.05, hw) * 0.6) % 1 + 1) % 1;
    return [1, (flute < 0.5 ? 1 : 0.5) * (0.75 + 0.25 * (u < 0 ? 1 : 0.4))];
  }],
  // HP bar frame: a thin rounded outline (the fill is a stretched pixel).
  hpframe: [128, 16, (u, v, w, h) => {
    const d = roundBox(u * w / 2, v * h / 2, w / 2 - 1.5, h / 2 - 1.5, 3);
    return 1 - smooth(0.6, 1.4, Math.abs(d));
  }],
  // Polygon shard: a triangle with a lighter edge.
  tri: [32, 32, (u, v) => {
    const d = Math.max(-v - 0.7, (v * 0.5 + Math.abs(u) * 0.866) - 0.45);
    if (d > 0) return 0;
    return [1, d > -0.1 ? 1 : 0.7];
  }],
  // Ribbon twirl: a wave of ribbon that twists, front and back shaded.
  twirl: [128, 64, (u, v) => {
    const y = 0.45 * Math.sin(u * Math.PI * 1.25);
    const w = 0.16 + 0.16 * Math.abs(Math.cos(u * Math.PI * 2.5));
    const d = Math.abs(v - y);
    if (d > w || Math.abs(u) > 0.96) return 0;
    return [1 - smooth(w * 0.7, w, d), Math.cos(u * Math.PI * 2.5) > 0 ? 1 : 0.6];
  }],
  // Speed lines bursting out from an empty centre.
  radial: [128, 128, (u, v) => {
    const [r, a] = polar(u, v);
    if (r > 1) return 0;
    let al = 0;
    for (const [ang, w, start] of radialLines) {
      const da = Math.abs((((a - ang) % (Math.PI * 2)) + Math.PI * 3) % (Math.PI * 2) - Math.PI);
      if (r > start && da < w * (1 + r)) al = Math.max(al, smooth(start, start + 0.15, r) * (1 - smooth(0.85, 1, r)));
    }
    return al;
  }],
  // Comic impact: a jagged ten-point starburst.
  impact: [64, 64, (u, v) => {
    const [r, a] = polar(u, v);
    const f = (a / (Math.PI * 2) * 20 % 20 + 20) % 20, i = Math.floor(f), q = f - i;
    const R = impactPts[i] * (1 - q) + impactPts[(i + 1) % 20] * q;
    return [1 - smooth(R - 0.04, R, r), r < R * 0.5 ? 1 : 0.8];
  }],
  // Stone spikes bursting from the ground, lit from the left.
  stonespikes: [128, 64, (u, v) => {
    for (const [x, hgt, w] of [[-0.62, 0.55, 0.2], [-0.25, 0.95, 0.24], [0.12, 0.7, 0.22], [0.5, 0.88, 0.24], [0.8, 0.45, 0.16]]) {
      const t = (v + 0.95) / (hgt + 0.95);
      if (t >= 0 && t <= 1 && Math.abs(u - x) < w * (1 - t)) return [1, u < x ? 0.95 : 0.6];
    }
    return 0;
  }],
});

// --- Race skins (original designs) ----------------------------------------------
Object.assign(TEXTURES, {
  // Wax seal: a lumpy disc of wax with a raised ring and a rosette pressed in.
  waxseal: [64, 64, (u, v) => {
    const [r, a] = polar(u, v);
    const edge = 0.86 + 0.05 * Math.sin(a * 7 + 1) + 0.03 * Math.sin(a * 13);
    if (r > edge) return 0;
    const ring = Math.abs(r - 0.62) < 0.05;
    const petals = r < 0.42 && r > 0.12 && Math.cos(a * 6) > 0.3 - r;
    const shine = clamp(1 - Math.hypot(u + 0.35, v - 0.35) * 2.2);
    return [1 - smooth(edge - 0.04, edge, r), ring || petals ? 1 : 0.62 + 0.25 * shine];
  }],
  // Tankard: a banded body, a handle on the right and a foamy head.
  mug: [64, 64, (u, v) => {
    const body = Math.abs(u + 0.12) < 0.48 && v > -0.82 && v < 0.42;
    const handle = Math.abs(Math.hypot((u - 0.42) / 0.9, (v + 0.2) / 1.1) - 0.3) < 0.07 && u > 0.36;
    // A head of foam: overlapping puffs, one spilling over the rim.
    const foam = [[-0.48, 0.46, 0.2], [-0.22, 0.56, 0.24], [0.08, 0.52, 0.22], [0.3, 0.44, 0.17], [-0.5, 0.3, 0.12]]
      .some(([x, y, r]) => Math.hypot(u - x, v - y) < r) || (Math.abs(u + 0.12) < 0.52 && v >= 0.36 && v < 0.5);
    if (foam) return [1, 1];
    if (!body && !handle) return 0;
    const band = Math.abs(v - 0.2) < 0.06 || Math.abs(v + 0.6) < 0.06;
    return [1, handle || band ? 0.4 : 0.66 + 0.12 * (u < -0.1 ? 1 : 0)];
  }],
  // Pocket rocket: a nose cone, a porthole and two fins.
  rocket: [32, 64, (u, v) => {
    const nose = v > 0.4 && Math.abs(u) < 0.5 * (0.95 - v) / 0.55;
    const body = v > -0.55 && v <= 0.4 && Math.abs(u) < 0.5;
    const fin = v > -0.9 && v < -0.2 && Math.abs(u) >= 0.5 && Math.abs(u) < 0.5 + 0.45 * (-0.2 - v) / 0.7;
    if (!nose && !body && !fin) return 0;
    const port = Math.hypot(u * 0.5, v - 0.05) < 0.12;
    return [1, nose || fin ? 0.5 : port ? 0.3 : (u < 0 ? 1 : 0.8)];
  }],
  // Throwing axe: a haft with a bearded blade at the top.
  throwaxe: [64, 64, (u, v) => {
    const haft = Math.abs(u + 0.1) < 0.07 && v > -0.92 && v < 0.75;
    // A bearded blade: edges curving out from the haft to a rounded cutting edge.
    const bx = u + 0.04, by = v - 0.36;
    const blade = bx > -0.06 && Math.abs(by) < 0.16 + 1.2 * Math.pow(Math.max(0, bx), 1.5) && Math.hypot(bx + 0.12, by * 0.72) < 0.92;
    if (haft) return [1, 0.38];
    if (!blade) return 0;
    return [1, bx > 0.6 ? 1 : 0.72];
  }],
  // Totem: three carved faces stacked, wings at the top.
  totem: [32, 96, (u, v) => {
    const post = Math.abs(u) < 0.62 && v > -0.98 && v < 0.62;
    const wing = v > 0.42 && v < 0.62 + (Math.abs(u) - 0.6) * 0.5 && Math.abs(u) < 0.98 && Math.abs(u) >= 0.62;
    const cap = v >= 0.62 && v < 0.82 && Math.abs(u) < 0.62 - (v - 0.62) * 1.5;
    if (!post && !wing && !cap) return 0;
    if (!post) return [1, 0.7];
    const seg = ((v + 1) / 0.54) % 1;
    const eyes = seg > 0.55 && seg < 0.72 && Math.abs(Math.abs(u) - 0.26) < 0.14;
    const mouth = seg > 0.2 && seg < 0.3 && Math.abs(u) < 0.34;
    const groove = seg < 0.06;
    return [1, eyes || mouth ? 0.25 : groove ? 0.45 : 0.75 + 0.2 * (u < 0 ? 1 : 0)];
  }],
  // Tusk: a curved horn, broad at the base, curling up to a point (left side;
  // mirrored with a half-turn rotation for the right).
  tusk: [32, 64, (u, v) => {
    const t = (v + 0.9) / 1.8;
    if (t < 0 || t > 1) return 0;
    const cx = 0.45 * Math.sin(t * Math.PI * 0.9) - 0.1, w = 0.42 * (1 - t) + 0.03;
    const d = Math.abs(u - cx);
    if (d > w) return 0;
    return [1 - smooth(w * 0.8, w, d), u < cx ? 1 : 0.75];
  }],
  // The same tusk and tankard, facing the other way.
  tuskright: [32, 64, (u, v) => TEXTURES.tusk[2](-u, v)],
  mugleft: [64, 64, (u, v) => TEXTURES.mug[2](-u, v)],
  // Sound waves: three arcs out to each side.
  soundwave: [128, 64, (u, v) => {
    let al = 0;
    for (const side of [-1, 1]) {
      const [r, a] = polar((u * side) + 0.1, v * 2);
      if (Math.abs(a) > 0.9) continue;
      for (const R of [0.45, 0.68, 0.9]) al = Math.max(al, (1 - smooth(0.03, 0.06, Math.abs(r - R))) * (1 - Math.abs(a) / 0.9));
    }
    return al;
  }],
});

// --- Pop skins and more anime (original designs) --------------------------------
// Point in polygon, a piecewise-linear curve, and a stroked distance.
const pip = (x, y, pts) => {
  let inside = false;
  for (let i = 0, j = pts.length - 1; i < pts.length; j = i++) {
    const [xi, yi] = pts[i], [xj, yj] = pts[j];
    if ((yi > y) !== (yj > y) && x < (xj - xi) * (y - yi) / (yj - yi) + xi) inside = !inside;
  }
  return inside;
};
const pl = (pts, x) => {
  if (x <= pts[0][0]) return pts[0][1];
  for (let i = 1; i < pts.length; i++) {
    if (x <= pts[i][0]) { const [x0, y0] = pts[i - 1], [x1, y1] = pts[i]; return y0 + (y1 - y0) * (x - x0) / (x1 - x0); }
  }
  return pts[pts.length - 1][1];
};
const stroke = (d, w) => 1 - smooth(w * 0.7, w, d);
// Their own generator, so nothing above changes.
let seed3 = 4711;
const rand3 = () => {
  seed3 = (seed3 + 0x6D2B79F5) >>> 0;
  let t = seed3;
  t = Math.imul(t ^ (t >>> 15), t | 1);
  t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
};
const scratchSpecks = Array.from({ length: 16 }, () => [rand3() * 1.8 - 0.9, rand3() * 1.8 - 0.9, 0.01 + rand3() * 0.02]);

// Toy blocks: a cube with a grooved front face and a painted letter.
const LETTERS = {
  A: [[[-0.45, -0.55], [0, 0.55], [0.45, -0.55]], [[-0.24, -0.12], [0.24, -0.12]]],
  B: [[[-0.35, -0.55], [-0.35, 0.55], [0.12, 0.55], [0.34, 0.4], [0.34, 0.17], [0.12, 0.02], [-0.35, 0.02]],
      [[-0.35, 0.02], [0.18, 0.02], [0.42, -0.16], [0.42, -0.4], [0.18, -0.55], [-0.35, -0.55]]],
};
function toyBlock(letter) {
  const F = [-0.85, 0.42, -0.92, 0.36], dx = 0.42, dy = 0.44;
  const top = [[F[0], F[3]], [F[1], F[3]], [F[1] + dx, F[3] + dy], [F[0] + dx, F[3] + dy]];
  const side = [[F[1], F[2]], [F[1] + dx, F[2] + dy], [F[1] + dx, F[3] + dy], [F[1], F[3]]];
  const face = (u, v) => u > F[0] && u < F[1] && v > F[2] && v < F[3] ? 1 : pip(u, v, top) ? 2 : pip(u, v, side) ? 3 : 0;
  return (u, v) => {
    const f = face(u, v);
    if (!f) return 0;
    const e = 0.045;
    if (!face(u + e, v) || !face(u - e, v) || !face(u, v + e) || !face(u, v - e)) return [1, 0.3];
    if (f === 2) return [1, 1];
    if (f === 3) return [1, 0.58];
    const fu = (u - (F[0] + F[1]) / 2) / ((F[1] - F[0]) / 2), fv = (v - (F[2] + F[3]) / 2) / ((F[3] - F[2]) / 2);
    const edge = Math.max(Math.abs(fu), Math.abs(fv));
    if (edge > 0.74 && edge < 0.81) return [1, 0.62];
    let d;
    if (letter === 'C') {
      const [r, a] = polar(fu, fv);
      const ex = 0.48 * Math.cos(0.75), ey = 0.48 * Math.sin(0.75);
      d = Math.abs(a) < 0.75 ? Math.min(Math.hypot(fu - ex, fv - ey), Math.hypot(fu - ex, fv + ey)) : Math.abs(r - 0.48);
    } else {
      d = Math.min(...LETTERS[letter].map(p => polyDist(fu, fv, p)));
    }
    return [1, d < 0.13 ? 0.36 : 0.9];
  };
}

// Fitness rings: a 30-degree piece of a ring (with a round leading cap)
// and the dim track it fills. t: the ring's thickness (share of radius).
const fitSeg = t => (u, v) => {
  const [r, a] = polar(u, v), rc = 0.96 - t / 2, ht = t / 2;
  const a0 = Math.PI / 2 - Math.PI / 6, a1 = Math.PI / 2 + 0.02;
  let d;
  if (a >= a0 && a <= a1) d = Math.abs(r - rc);
  else if (a < a0 && a > a0 - 1) d = Math.hypot(u - rc * Math.cos(a0), v - rc * Math.sin(a0));
  else return 0;
  return 1 - smooth(ht - 0.025, ht, d);
};
const fitTrack = t => (u, v) => {
  const r = Math.hypot(u, v), rc = 0.96 - t / 2, ht = t / 2;
  return 1 - smooth(ht - 0.025, ht, Math.abs(r - rc));
};

// The katana and its scabbard share one gentle curve.
const bladeCurve = x => x < 16 ? 2.4 * Math.pow((16 - x) / 76, 2) : 0;

Object.assign(TEXTURES, {
  // Fairytale castle: a crenellated wall, a tall central keep with a spire
  // and pennant, flanking towers with conical roofs, an arched gate.
  castle: [128, 128, (u, v) => {
    const inR = (x0, x1, y0, y1) => u > x0 && u < x1 && v > y0 && v < y1;
    const cone = (cx, hw, y0, y1) => v > y0 && v < y1 && Math.abs(u - cx) < hw * (1 - (v - y0) / (y1 - y0));
    const crenel = (x0, x1, y, h, n) => u > x0 && u < x1 && v >= y && v < y + h && Math.floor((u - x0) / (x1 - x0) * n) % 2 === 0;
    if (Math.abs(u) < 0.012 && v > 0.86 && v < 0.99) return [1, 1];
    if (u > 0.012 && u < 0.17 && v > 0.9 + u * 0.22 && v < 0.98 - u * 0.22) return [1, 1];
    const roof = cone(0, 0.15, 0.42, 0.9) || cone(-0.43, 0.15, -0.02, 0.42) || cone(0.43, 0.15, -0.02, 0.42)
      || cone(-0.73, 0.1, -0.3, 0.0) || cone(0.73, 0.1, -0.3, 0.0);
    if (roof) return [1, 1];
    const body = inR(-0.7, 0.7, -0.95, -0.42) || crenel(-0.7, 0.7, -0.42, 0.07, 11)
      || inR(-0.28, 0.28, -0.95, 0.12) || crenel(-0.28, 0.28, 0.12, 0.07, 5)
      || inR(-0.11, 0.11, 0.12, 0.42)
      || inR(-0.53, -0.33, -0.95, -0.02) || inR(0.33, 0.53, -0.95, -0.02)
      || inR(-0.8, -0.66, -0.95, -0.3) || inR(0.66, 0.8, -0.95, -0.3);
    if (!body) return 0;
    if (Math.abs(u) < 0.1 && v < -0.66 + 0.06 * Math.sqrt(Math.max(0, 1 - (u / 0.1) ** 2))) return 0;   // the gate
    const win = (cx, cy) => Math.abs(u - cx) < 0.028 && v > cy - 0.06 && v < cy + 0.04 + 0.02 * Math.sqrt(Math.max(0, 1 - ((u - cx) / 0.028) ** 2));
    if (win(-0.12, -0.18) || win(0.12, -0.18) || win(0, 0.26) || win(-0.43, -0.32) || win(0.43, -0.32) || win(-0.43, -0.6) || win(0.43, -0.6)) return [1, 0.32];
    const shade = (u > 0.02 && u < 0.28) || (u > 0.45 && u < 0.53) || (u > -0.41 && u < -0.33) || u > 0.73;
    return [1, shade ? 0.66 : 0.8];
  }],
  // Shooting star: a bright four-point head trailing a widening tail.
  shootstar: [128, 32, (u, v) => {
    const hx = 0.74, du = (u - hx) * 4;
    const core = 1 - smooth(0.12, 0.5, Math.hypot(du, v));
    const spikeH = (1 - smooth(0.02, 0.1, Math.abs(v))) * (1 - smooth(0.1, 0.9, Math.abs(du)));
    const spikeV = (1 - smooth(0.02, 0.09, Math.abs(du))) * (1 - smooth(0.2, 0.95, Math.abs(v)));
    let tail = 0;
    if (u < hx) {
      const t = (u + 1) / (hx + 1), w = 0.08 + 0.32 * t;
      tail = Math.pow(t, 1.8) * (1 - smooth(w * 0.25, w, Math.abs(v)));
    }
    return clamp(Math.max(core, spikeH, spikeV, tail));
  }],
  // Firework: dashed rays from a gap in the middle, each ending in a spark.
  firework: [128, 128, (u, v) => {
    const [r, a] = polar(u, v);
    if (r < 0.22 || r > 0.97) return 0;
    const n = 18, k = ((a / (Math.PI * 2) * n) % 1 + 1) % 1;
    const across = Math.abs(k - 0.5) * (Math.PI * 2 / n) * r;
    const ray = 1 - smooth(0.012, 0.028, across);
    const dash = Math.sin(r * 40) > -0.3 ? 1 : 0.2;
    const tip = 1 - smooth(0.025, 0.05, Math.hypot(across, r - 0.87));
    return clamp(Math.max(ray * dash * smooth(0.22, 0.6, r) * 0.85, tip));
  }],
  // Clock face: a heavy rim, a fine inner ring, hour ticks (long at the
  // quarters), minute dots and a hub, over a faint glass face.
  clockface: [128, 128, (u, v) => {
    const [r, a] = polar(u, v);
    if (r > 0.96) return 0;
    let al = Math.max(stroke(Math.abs(r - 0.9), 0.045), stroke(Math.abs(r - 0.8), 0.016));
    const step = Math.PI / 6, idx = Math.round(a / step), da = a - idx * step;
    const quarter = ((idx % 3) + 3) % 3 === 0;
    const across = Math.abs(r * Math.sin(da));
    if (r > (quarter ? 0.56 : 0.63) && r < 0.76) al = Math.max(al, stroke(across, quarter ? 0.034 : 0.02));
    const m = Math.PI / 30, mi = Math.round(a / m);
    if (Math.abs(r - 0.72) < 0.03) al = Math.max(al, stroke(Math.hypot(r * Math.sin(a - mi * m), r - 0.72), 0.014));
    if (r < 0.07) al = 1;
    return al > 0.05 ? [Math.max(al, 0.16), al > 0.4 ? 1 : 0.7] : [0.16, 0.7];
  }],
  // Clock hand pointing up from a pivot ring near the bottom, with a
  // pierced diamond near its spear tip.
  clockhand: [32, 128, (u, v) => {
    const x = u * 16, y = v * 64;
    const ring = Math.hypot(x, y + 51);
    if (ring < 5.2) return ring < 1.8 ? 0 : 1;
    const dia = Math.abs(x) / 4.6 + Math.abs(y - 34) / 9;
    if (dia < 1) return Math.abs(x) / 2.2 + Math.abs(y - 34) / 5 < 1 ? 0 : 1;
    if (y > 54 && y < 63 && Math.abs(x) < 2.8 * (63 - y) / 9) return 1;
    if (y > -60 && y < 54) {
      const hw = y < -51 ? 1.8 : 2.6 - 1.3 * (y + 51) / 105;
      return Math.abs(x) < hw ? 1 : 0;
    }
    return 0;
  }],
  // Glass slipper: a high-heeled shoe in profile, a bright rim and a long
  // highlight over clear glass.
  slipper: [128, 64, (u, v) => {
    const TOP = [[-0.88, 0.62], [-0.74, 0.58], [-0.5, 0.12], [-0.1, -0.12], [0.3, -0.06], [0.62, -0.14], [0.86, -0.34], [0.96, -0.6]];
    const BOT = [[-0.88, 0.1], [-0.62, -0.18], [-0.3, -0.58], [0.1, -0.8], [0.7, -0.84], [0.96, -0.6]];
    const hx = pl([[0.1, -0.8], [-0.95, -0.72]], v), heel = v < 0.1 && v > -0.95 && u > -0.86 && u < hx * 0 + (-0.86 + 0.12 * (v + 0.95) / 1.05 + 0.07);
    if (heel && u < -0.62) return [1, u < -0.8 ? 1 : 0.75];
    if (u < -0.88 || u > 0.96) return 0;
    const t = pl(TOP, u), b = pl(BOT, u);
    if (v > t || v < b) return 0;
    const rim = Math.min(t - v, v - b) < 0.075;
    const open = u > -0.74 && u < 0.2 && t - v < 0.2;
    const hi = u > -0.2 && u < 0.75 && Math.abs(v - (b + 0.2)) < 0.035;
    return rim || hi ? [1, 1] : open ? [0.85, 0.4] : [0.75, 0.62];
  }],
  // Ornate snowflake: six arms, each with three pairs of branches, a
  // diamond tip and a hexagon at the heart.
  flakeornate: [128, 128, (u, v) => {
    const [r, a0] = polar(u, v);
    if (r > 0.98) return 0;
    const sector = Math.PI / 3;
    let a = ((a0 % sector) + sector) % sector;
    if (a > sector / 2) a = sector - a;
    const x = r * Math.cos(a), y = r * Math.sin(a);
    let d = segDist(x, y, 0.15, 0, 0.86, 0);
    for (const [bx, L] of [[0.36, 0.26], [0.56, 0.2], [0.73, 0.12]]) d = Math.min(d, segDist(x, y, bx, 0, bx + L * 0.5, L * 0.866));
    d = Math.min(d, segDist(x, y, 0.46, 0.1, 0.52, 0.2));
    let al = stroke(d, 0.03);
    if (Math.abs(x - 0.88) + Math.abs(y) * 1.8 < 0.08) al = 1;
    const hex = Math.abs(r * Math.cos(a - Math.PI / 6) - 0.15 * Math.cos(Math.PI / 6));
    al = Math.max(al, stroke(hex, 0.022), r < 0.05 ? 1 : 0);
    return al > 0 ? [al, 0.85 + 0.15 * (1 - r)] : 0;
  }],
  // Rising sun: a disc with long and short rays between gaps.
  sundisc: [128, 128, (u, v) => {
    const [r, a] = polar(u, v);
    const disc = 1 - smooth(0.46, 0.5, r);
    const n = 16, f = a / (Math.PI * 2) * n, idx = Math.floor(f), k = f - idx;
    const len = ((idx % 2) + 2) % 2 ? 0.8 : 0.97;
    let ray = 0;
    if (r > 0.56 && r < len) ray = 1 - smooth(0.0, 0.03, Math.abs(k - 0.5) * (Math.PI * 2 / n) * r - 0.045 * (1 - (r - 0.56) / (len - 0.56)));
    const al = Math.max(disc, ray * 0.75);
    return al > 0 ? [al, disc > 0.5 ? 1 - 0.22 * r / 0.5 : 0.9] : 0;
  }],
  // Rock ledge jutting to the right, with a lit top edge.
  ledge: [128, 64, (u, v) => {
    const P = [[-1, -1], [-1, -0.22], [-0.62, -0.06], [-0.26, 0.12], [0.1, 0.3], [0.44, 0.44], [0.64, 0.36], [0.56, 0.2],
               [0.3, 0.04], [0.16, -0.26], [0.1, -0.62], [0.14, -1]];
    if (!pip(u, v, P)) return 0;
    const lit = !pip(u, v + 0.1, P);
    const crack = Math.abs(v + 0.35 + 0.25 * Math.sin(u * 5)) < 0.02 && u < 0;
    return [1, lit ? 0.8 : crack ? 0.18 : 0.3];
  }],
  // A distant bird in flight.
  bird: [32, 32, (u, v) => {
    const d = polyDist(u, v, [[-0.92, 0.22], [-0.5, 0.38], [-0.12, 0.08], [0, -0.06], [0.12, 0.08], [0.5, 0.38], [0.92, 0.22]]);
    return stroke(d, 0.14 * (1 - Math.abs(u) * 0.7));
  }],
  // Iris: a black ring round a round hole, soft at its outer edge.
  iris: [256, 256, (u, v) => {
    const r = Math.hypot(u, v);
    return [smooth(0.34, 0.38, r) * (1 - smooth(0.84, 1, r)), 0.04];
  }],
  // Old film: wavering vertical scratches and dust specks.
  filmscratch: [128, 128, (u, v) => {
    let al = 0;
    [-0.62, -0.1, 0.38, 0.71].forEach((x0, i) => {
      const x = x0 + 0.02 * Math.sin(v * 9 + i * 2);
      if (Math.sin(v * 3 + i * 2.1) > -0.35) al = Math.max(al, stroke(Math.abs(u - x), 0.009) * 0.9);
    });
    for (const [x, y, s] of scratchSpecks) al = Math.max(al, stroke(Math.hypot(u - x, v - y), s));
    return al;
  }],
  // Wooden letter blocks.
  blockA: [64, 64, toyBlock('A')],
  blockB: [64, 64, toyBlock('B')],
  blockC: [64, 64, toyBlock('C')],
  // Black pill (the notification island).
  pill: [128, 32, (u, v) => roundBox(u * 64, v * 16, 62, 14, 14) < 0 ? 1 : 0],
  // Check mark.
  check: [64, 64, (u, v) => stroke(polyDist(u, v, [[-0.6, 0.02], [-0.18, -0.42], [0.62, 0.46]]), 0.13)],
  // Loading spinner: an arc that brightens to its leading end (it spins
  // clockwise).
  spinner: [64, 64, (u, v) => {
    const [r, a] = polar(u, v);
    const s = (((Math.PI / 2 - a) % (Math.PI * 2)) + Math.PI * 2) % (Math.PI * 2) / (Math.PI * 2);
    const head = Math.hypot(u - 0.7 * Math.cos(Math.PI / 2 - 0.83 * Math.PI * 2), v - 0.7 * Math.sin(Math.PI / 2 - 0.83 * Math.PI * 2));
    const arc = s < 0.83 ? stroke(Math.abs(r - 0.7), 0.13) * Math.pow(s / 0.83, 0.8) : 0;
    return clamp(Math.max(arc, stroke(head, 0.13)));
  }],
  // Frosted glass tile: a translucent rounded panel, brighter at the top,
  // with a crisp rim and a highlight along its top-left edge.
  glasstile: [128, 64, (u, v) => {
    const x = u * 64, y = v * 32;
    const d = roundBox(x, y, 62, 30, 14);
    if (d > 0) return 0;
    if (d > -1.6) return [1, 1];
    if (d > -3.6 && y > 14 && x < 24) return [0.75 * clamp((24 - x) / 40 + 0.4), 1];
    return [0.4 + 0.16 * clamp((y + 30) / 60), 0.95];
  }],
  // A soft slanted band of light (glass sheen).
  sheen: [64, 64, (u, v) => Math.exp(-Math.pow((u - v * 0.35) / 0.3, 2)) * (1 - smooth(0.8, 1, Math.abs(v)))],
  // Rounded screen edge: a thin rim over a faint fill.
  edgeframe: [128, 64, (u, v) => {
    const d = roundBox(u * 64, v * 32, 61, 29, 16);
    const rim = 1 - smooth(0.9, 2.1, Math.abs(d));
    return d < 0 ? [Math.max(rim, 0.1), rim > 0.2 ? 1 : 0.25] : rim > 0 ? [rim, 1] : 0;
  }],
  // A comet streak: a bright head at the right, its tail thinning left.
  streak: [128, 16, (u, v) => {
    const t = clamp((u + 1) / 1.82);
    const along = u <= 0.82 ? t * t : 1 - smooth(0.82, 1, u);
    const w = 0.25 + 0.6 * t;
    const head = 1 - smooth(0.3, 0.9, Math.hypot((u - 0.82) * 8, v));
    return clamp(Math.max(along * (1 - smooth(w * 0.4, w, Math.abs(v))), head));
  }],
  // Battery outline with its terminal (the charge is a separate fill).
  battery: [128, 64, (u, v) => {
    const x = (u + 1) * 64, y = (1 - v) * 32;
    const b = roundBox(x - 55, y - 32, 49, 20, 8);
    if (b < 0 && b > -5) return 1;
    return roundBox(x - 112, y - 32, 6, 10, 3) < 0 && x > 104 ? 1 : 0;
  }],
  // Chat bubble with its tail at the bottom right (sent), and its mirror.
  chatbubble: [128, 64, (u, v) => {
    const x = (u + 1) * 64, y = (1 - v) * 32;
    if (roundBox(x - 60, y - 28, 56, 24, 22) < 0) return 1;
    return pip(x, y, [[96, 44], [114, 34], [117, 50], [126, 61], [106, 56]]) ? 1 : 0;
  }],
  chatbubbleL: [128, 64, (u, v) => TEXTURES.chatbubble[2](-u, v)],
  dot: [32, 32, (u, v) => 1 - smooth(0.78, 0.86, Math.hypot(u, v))],
  // Three activity rings, each with the same pixel thickness at the sizes
  // they're drawn (116, 90 and 64 across).
  fitseg1: [128, 128, fitSeg(0.155)],
  fitseg2: [128, 128, fitSeg(0.2)],
  fitseg3: [128, 128, fitSeg(0.28)],
  fittrk1: [128, 128, fitTrack(0.155)],
  fittrk2: [128, 128, fitTrack(0.2)],
  fittrk3: [128, 128, fitTrack(0.28)],
  // Scouter lens: a slanted pane with scanlines, a rim, corner brackets and
  // range ticks along the top.
  scouter: [128, 64, (u, v) => {
    const y = v * 32, x = u * 64 - y * 0.25;
    const d = roundBox(x, y, 54, 26, 6);
    if (d > 1.6) return 0;
    if (Math.abs(d) < 1.6) return [1, 1];
    if (d > -5 && d < -2.6 && Math.abs(x) > 40 && Math.abs(y) > 12) return [1, 1];
    if (y > 17 && y < 21 && Math.abs(x) < 30 && ((x + 64) % 8) < 1.6) return [0.9, 1];
    return Math.abs(((y + 64) % 4) - 2) < 0.55 ? [0.42, 0.85] : [0.26, 0.75];
  }],
  // A dark domain: a disc with faint rings, spokes and ticks.
  domain: [128, 128, (u, v) => {
    const [r, a] = polar(u, v);
    if (r > 0.96) return 0;
    let lum = 0.07;
    if (stroke(Math.abs(r - 0.66), 0.012) > 0.5) lum = 0.6;
    else if (stroke(Math.abs(r - 0.4), 0.01) > 0.5) lum = 0.45;
    else if (r > 0.4 && r < 0.66 && Math.abs(r * Math.sin(a - Math.round(a / (Math.PI / 4)) * Math.PI / 4)) < 0.006) lum = 0.4;
    else if (r > 0.78 && r < 0.84 && Math.abs(r * Math.sin(a - Math.round(a / (Math.PI / 12)) * Math.PI / 12)) < 0.008) lum = 0.5;
    return [1 - smooth(0.88, 0.96, r), lum];
  }],
  // Trading card back: a bright border, an inner frame and concentric
  // ovals round an emblem.
  cardback: [64, 128, (u, v) => {
    const x = u * 32, y = v * 64;
    const d = roundBox(x, y, 30, 61, 4);
    if (d > 0) return 0;
    if (d > -4) return [1, 0.95];
    if (d > -7 && d < -6) return [1, 0.8];
    const e = Math.hypot(x / 21, y / 40);
    if (e < 0.18) return [1, 1];
    if (e < 1 && Math.abs((e * 5) % 1 - 0.5) > 0.36) return [1, 0.72];
    return [1, 0.4];
  }],
  // Card face: a frame, a title bar, an art window with a star emblem and
  // a pale text box for the number.
  cardface: [64, 128, (u, v) => {
    const x = u * 32, y = v * 64;
    const d = roundBox(x, y, 30, 61, 4);
    if (d > 0) return 0;
    if (d > -3.5) return [1, 0.95];
    if (Math.abs(x) < 25 && y > 42 && y < 56) return [1, y > 47 && y < 51 && x > -20 && x < 6 ? 0.45 : 0.82];
    if (Math.abs(x) < 24 && y > -6 && y < 38) {
      const [r, a] = polar(x / 14, (y - 16) / 14);
      const star = 0.42 + 0.5 * Math.pow(Math.abs(Math.cos(2.5 * (a - Math.PI / 2))), 5);
      return [1, r < star ? 1 : 0.26 + 0.08 * Math.sin(a * 12)];
    }
    if (Math.abs(x) < 25 && y > -56 && y < -12) return [1, 0.88];
    return [1, 0.6];
  }],
  // Portal: spiral arms swirling into a bright core, with a rim.
  portal: [128, 128, (u, v) => {
    const [r, a] = polar(u, v);
    if (r > 0.97) return 0;
    const arms = Math.pow(0.5 + 0.5 * Math.sin(a * 3 + r * 12), 3) * smooth(0.12, 0.35, r) * (1 - smooth(0.8, 0.94, r));
    const rim = stroke(Math.abs(r - 0.9), 0.035);
    const core = (1 - smooth(0.05, 0.3, r)) * 0.85;
    return clamp(Math.max(arms, rim, core));
  }],
  // Truck grille: a rounded frame round horizontal slats.
  grille: [128, 64, (u, v) => {
    const x = u * 64, y = v * 32;
    const d = roundBox(x, y, 60, 26, 8);
    if (d > 0) return 0;
    if (d > -4) return [1, 0.75];
    return [1, Math.abs(((y + 64) % 8) - 4) < 2 ? 0.5 : 0.14];
  }],
  // Anger mark: four curved strokes round a cross-shaped gap.
  vein: [64, 64, (u, v) => {
    let al = 0;
    for (const [sx, sy] of [[1, 1], [1, -1], [-1, 1], [-1, -1]]) {
      const px = u - sx * 0.52, py = v - sy * 0.52, r = Math.hypot(px, py);
      const c = (px * -sx + py * -sy) / (Math.SQRT2 * (r || 1));
      if (c < 0.3) continue;
      al = Math.max(al, stroke(Math.abs(r - 0.4), 0.03 + 0.12 * (c - 0.3) / 0.7));
    }
    return al;
  }],
  // Sweat drop: a teardrop with a highlight and darker lower edge.
  sweatdrop: [32, 64, (u, v) => {
    const x = u * 16, y = v * 32;
    const inBall = Math.hypot(x, y + 12) < 11;
    const inTop = y >= -12 && y < 28 && Math.abs(x) < 11 * Math.pow((28 - y) / 40, 1.3);
    if (!inBall && !inTop) return 0;
    if (Math.hypot(x + 4, y + 13) < 3) return [1, 1];
    return [1, 0.72 + 0.2 * clamp(0.5 - x / 22 + (y + 12) / 60)];
  }],
  // Katana: a curved blade (a bright edge, a darker spine), a collar, a
  // round guard and a wrapped grip.
  katana: [128, 32, (u, v) => {
    const x = u * 64, y = v * 16;
    if (x > -61 && x < 16) {
      const c = bladeCurve(x);
      let hw = 3.4;
      if (x < -50) hw *= (x + 61) / 11;
      const dy = y - c;
      if (Math.abs(dy) > hw) return 0;
      return [1, dy < -hw * 0.35 ? 1 : dy > hw * 0.45 ? 0.68 : 0.86];
    }
    if (x >= 16 && x < 19) return Math.abs(y) < 4.2 ? [1, 0.9] : 0;
    if (x >= 19 && x < 23.5) return Math.hypot((x - 21.2) / 2.3, y / 10) < 1 ? [1, 0.42] : 0;
    if (x >= 23.5 && x < 60) return Math.abs(y) < 4.4 ? [1, (((x * 0.5 + Math.abs(y)) % 4) + 4) % 4 < 2 ? 0.22 : 0.5] : 0;
    if (x >= 60 && x < 62.5) return Math.abs(y) < 4.8 ? [1, 0.7] : 0;
    return 0;
  }],
  // Scabbard: lacquered, the same curve, a collar at the mouth and a cord.
  saya: [128, 32, (u, v) => {
    const x = u * 64, y = v * 16;
    if (Math.abs(Math.hypot(x - 6, y + 8) - 3) < 1) return [1, 0.75];
    if (x < -61 || x > 18) return 0;
    const dy = y - bladeCurve(x);
    let hw = 4.8;
    if (x < -56) hw *= Math.sqrt(Math.max(0, 1 - ((x + 56) / 5) ** 2));
    if (Math.abs(dy) > hw) return 0;
    if (x > 13) return [1, 0.88];
    return [1, dy > hw * 0.45 ? 0.58 : 0.3];
  }],
  // Power meter: ten cells (revealed upward as it fills) and its frame.
  metercells: [32, 128, (u, v) => {
    const x = u * 16, y = v * 64;
    if (Math.abs(x) > 8.5 || y < -58 || y > 58) return 0;
    const cell = (y + 58) / 11.6, k = cell - Math.floor(cell);
    return k < 0.8 ? [1, 0.82 + 0.18 * (1 - Math.abs(x) / 8.5)] : 0;
  }],
  meterframe: [32, 128, (u, v) => {
    const d = roundBox(u * 16, v * 64, 13, 62, 4);
    if (d > 1.5) return 0;
    return Math.abs(d) < 1.5 ? [1, 1] : [0.3, 0.15];
  }],
  // Psychic ring: a wobbly glowing band.
  psyring: [128, 128, (u, v) => {
    const [r, a] = polar(u, v);
    const r0 = 0.72 + 0.07 * Math.sin(a * 6) + 0.04 * Math.sin(a * 11 + 1.3);
    const d = Math.abs(r - r0);
    return clamp(Math.max(stroke(d, 0.06), (1 - smooth(0, 0.22, d)) * 0.35));
  }],
  // Saxophone silhouette: a curved body widening to a flared bell, with
  // keys down its front.
  sax: [64, 128, (u, v) => {
    const x = u * 32, y = v * 64;
    const P = [[-16, 60, 1.5], [-10, 52, 2], [-8, 32, 2.8], [-10, 4, 3.6], [-12, -24, 4.4], [-10, -44, 5], [-3, -55, 5.4],
               [6, -51, 5.6], [10, -34, 6], [12, -14, 8], [13, 0, 11]];
    let inside = false;
    for (let i = 0; i < P.length - 1; i++) {
      const [ax, ay, aw] = P[i], [bx, by, bw] = P[i + 1];
      const dx = bx - ax, dy = by - ay, t = clamp(((x - ax) * dx + (y - ay) * dy) / (dx * dx + dy * dy));
      if (Math.hypot(x - ax - t * dx, y - ay - t * dy) < aw + (bw - aw) * t) { inside = true; break; }
    }
    if (!inside) return 0;
    if (y > -3 && x > 2) return [1, y > 1 ? 1 : 0.85];
    for (const [kx, ky] of [[-6, 22], [-7, 10], [-8, -4], [-9, -18], [-8, -32]]) if (Math.hypot(x - kx, y - ky) < 1.8) return [1, 0.35];
    return [1, x < -9 ? 0.95 : 0.7];
  }],
});

// --- World skins (WoW: Forever themes) ---------------------------------------------
// The legendary weapons are full-color art traced from the game's own models
// (Wowhead's model viewer, side on): each is drawn in its reference picture's
// pixel coordinates (y down) and mapped into the texture.
const mix = (a, b, t) => a.map((v, i) => v + (b[i] - v) * clamp(t));
const rgb = (c, k = 1) => c.map(v => clamp(v * k));
const C = (a, c) => [a, c[0], c[1], c[2]];
const inTri = (x, y, a, b, c) => pip(x, y, [a, b, c]);
// Distance to a polygon's edge (for rims and bevels).
const polyEdge = (x, y, pts) => {
  let d = Infinity;
  for (let i = 0; i < pts.length; i++) {
    const a = pts[i], b = pts[(i + 1) % pts.length];
    d = Math.min(d, segDist(x, y, a[0], a[1], b[0], b[1]));
  }
  return d;
};
let seed4 = 9001;
const rand4 = () => {
  seed4 = (seed4 + 0x6D2B79F5) >>> 0;
  let t = seed4;
  t = Math.imul(t ^ (t >>> 15), t | 1);
  t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
};

// Horn or spike: a triangle shaded light along one side, darker the other.
function spike(x, y, tip, b1, b2, light, dark) {
  if (!inTri(x, y, tip, b1, b2)) return null;
  const mx = (b1[0] + b2[0]) / 2, my = (b1[1] + b2[1]) / 2;
  const ax = tip[0] - mx, ay = tip[1] - my, len = Math.hypot(ax, ay) || 1;
  const side = ((x - mx) * -ay + (y - my) * ax) / len;
  const along = ((x - mx) * ax + (y - my) * ay) / (len * len);
  return mix(dark, light, 0.5 + side / (Math.hypot(b1[0] - b2[0], b1[1] - b2[1]) * 0.6) * 0.8 + along * 0.25);
}

// Value noise for organic surfaces (wood grain, hammered metal, smoke, fire).
const hash2 = (x, y) => {
  let h = Math.imul(x | 0, 374761393) + Math.imul(y | 0, 668265263);
  h = Math.imul(h ^ (h >>> 13), 1274126177);
  return ((h ^ (h >>> 16)) >>> 0) / 4294967296;
};
const vnoise = (x, y) => {
  const xi = Math.floor(x), yi = Math.floor(y), xf = x - xi, yf = y - yi;
  const s = t => t * t * (3 - 2 * t);
  const a = hash2(xi, yi), b = hash2(xi + 1, yi), c = hash2(xi, yi + 1), d = hash2(xi + 1, yi + 1);
  const u = s(xf), w = s(yf);
  return a + (b - a) * u + (c - a) * w + (a - b - c + d) * u * w;
};
const fbm = (x, y, oct = 4) => {
  let sum = 0, amp = 0.5, f = 1, norm = 0;
  for (let i = 0; i < oct; i++) { sum += amp * vnoise(x * f + i * 17.3, y * f + i * 9.1); norm += amp; amp *= 0.5; f *= 2; }
  return sum / norm;
};
// A horn or spike with a lit ridge down its middle.
function spikeR(x, y, tip, b1, b2, light, dark) {
  if (!inTri(x, y, tip, b1, b2)) return null;
  const mx = (b1[0] + b2[0]) / 2, my = (b1[1] + b2[1]) / 2;
  const ax = tip[0] - mx, ay = tip[1] - my, len = Math.hypot(ax, ay) || 1;
  const half = Math.hypot(b1[0] - b2[0], b1[1] - b2[1]) / 2;
  const along = clamp(((x - mx) * ax + (y - my) * ay) / (len * len));
  const side = ((x - mx) * -ay + (y - my) * ax) / len / (half * (1 - along) + 0.5);
  if (Math.abs(side) < 0.08) return mix(light, [1, 1, 1], 0.35);
  if (polyEdge(x, y, [tip, b1, b2]) < 1.1) return rgb(dark, 0.7);
  return mix(dark, light, side > 0 ? 0.85 - along * 0.2 : 0.35 - along * 0.15);
}

// Thunderfury, Blessed Blade of the Windseeker (reference 670 x 160).
const TF_LIGHTNING = Array.from({ length: 3 }, () => [rand4() * 6, 0.04 + rand4() * 0.03, 6 + rand4() * 8]);
function thunderfury(u, v) {
  const x = (u + 1) * 128 / 0.382, y = 160 - ((v + 1) * 32 - 1.4) / 0.382;
  const IVORY = [0.99, 0.93, 0.72], IVORY_D = [0.58, 0.45, 0.26], STEEL = [0.3, 0.32, 0.4], NAVY = [0.05, 0.07, 0.18];
  // The orb: a white core, swirling light, a deep blue rim.
  const orb = Math.hypot(x - 372, y - 80);
  if (orb < 30) {
    const k = orb / 30, ang = Math.atan2(y - 80, x - 372);
    let c = mix([1, 1, 1], [0.42, 0.56, 1], k * k);
    if (k > 0.3 && Math.sin(ang * 3 + k * 9) > 0.7) c = mix(c, [0.9, 0.95, 1], 0.55);
    if (k > 0.9) c = [0.25, 0.4, 0.92];
    if (Math.hypot(x - 364, y - 72) < 6) c = [1, 1, 1];
    return C(1, c);
  }
  let out = null;
  const blade = [[322, 80], [294, 22], [336, 20], [662, 80], [336, 140], [294, 138]];
  if (pip(x, y, blade)) {
    const hh = x < 336 ? 60 : 60 * (662 - x) / 326;
    const t = Math.abs(y - 80) / Math.max(1, hh);
    const top = y < 80;
    if (x < 338) {
      // The barbed crystal base: two facets.
      const facet = (x - 294) / 44 + (Math.abs(y - 80) / 60) * 0.6;
      out = top ? mix([0.6, 0.72, 0.92], [0.97, 0.98, 1], facet) : mix([0.4, 0.5, 0.75], [0.75, 0.84, 0.97], facet);
      if (Math.abs(t - 0.55) < 0.04) out = [0.35, 0.45, 0.7];
    } else if (t > 0.6) {
      out = top ? mix([0.72, 0.8, 0.93], [0.97, 0.98, 1], (t - 0.6) * 2.5) : mix([0.5, 0.58, 0.76], [0.72, 0.78, 0.9], (t - 0.6) * 2.5);
      if (top && t > 0.74 && t < 0.8) out = [1, 1, 1];          // a glint along the top edge
      if (t < 0.64) out = top ? [0.92, 0.96, 1] : [0.62, 0.7, 0.88]; // the bevel catching light
    } else if (t < 0.1) {
      out = mix([0.55, 0.74, 1], [0.85, 0.93, 1], 1 - t / 0.1);
    } else {
      out = mix([0.04, 0.13, 0.45], [0.15, 0.33, 0.78], (t - 0.1) / 0.5);
      out = rgb(out, 0.85 + 0.3 * fbm(x * 0.05, y * 0.12));
      if (x > 380) {
        for (const [ph, f, a] of TF_LIGHTNING) {
          const ly = 80 + Math.sin(x * f + ph) * a * (1 - (x - 380) / 300) + Math.sin(x * 0.31 + ph * 3) * 3;
          const d = Math.abs(y - ly);
          if (d < 0.7) out = [0.9, 0.96, 1];
          else if (d < 3) out = mix(out, [0.5, 0.7, 1], (1 - d / 3) * 0.7);
        }
      }
    }
    if (polyEdge(x, y, blade) < 1.4) out = top ? [1, 1, 1] : [0.35, 0.42, 0.6];
    return C(1, out);
  }
  // The orb's glow, with four faint rays.
  if (orb < 50) {
    const ang = Math.atan2(y - 80, x - 372), ray = Math.pow(Math.abs(Math.cos(ang * 2)), 40);
    return C(clamp((1 - (orb - 30) / 20) * 0.8 + ray * 0.5 * (1 - (orb - 30) / 20)), [0.55, 0.68, 1]);
  }
  if (x > 250 && x < 324 && y > 71 && y < 91) {
    if (Math.abs(x - 266) < 1.5 || Math.abs(x - 300) < 1.5) return C(1, [0.08, 0.12, 0.3]);
    return C(1, mix([0.1, 0.18, 0.45], [0.36, 0.52, 0.92], Math.sin(Math.PI * (91 - y) / 20)));
  }
  out = spikeR(x, y, [229, 33], [213, 64], [229, 64], IVORY, IVORY_D) || spikeR(x, y, [259, 28], [239, 64], [255, 64], IVORY, IVORY_D);
  if (out) return C(1, out);
  if (x > 200 && x < 252 && y > 63 && y < 97) {
    if (Math.hypot(x - 213, y - 80) < 3.6 || Math.hypot(x - 238, y - 80) < 3.6) {
      return C(1, Math.hypot(x - 212, y - 79) < 1.5 || Math.hypot(x - 237, y - 79) < 1.5 ? [1, 1, 1] : [0.7, 0.72, 0.8]);
    }
    if (x < 205 || x > 247) return C(1, rgb(STEEL, 0.6));
    if (y < 66) return C(1, [0.6, 0.62, 0.72]);
    return C(1, rgb(STEEL, 0.72 + 0.5 * Math.sin(Math.PI * (97 - y) / 34)));
  }
  if (x > 104 && x < 206 && y > 70 && y < 90) {
    const ph = ((x + (y - 70) * 0.7) % 13 + 13) % 13;
    const band = ph < 5, lip = ph >= 4 && ph < 5.2;
    const shade = 0.6 + 0.6 * Math.sin(Math.PI * (90 - y) / 20);
    return C(1, rgb(lip ? [0.55, 0.7, 1] : band ? [0.22, 0.38, 0.8] : NAVY, shade));
  }
  if (x > 58 && x < 106 && y > 66 && y < 94) {
    if (y < 69) return C(1, [0.62, 0.64, 0.74]);
    return C(1, rgb(STEEL, 0.7 + 0.5 * Math.sin(Math.PI * (94 - y) / 28)));
  }
  out = spikeR(x, y, [69, 124], [72, 92], [90, 92], IVORY, IVORY_D) || spikeR(x, y, [14, 80], [60, 70], [60, 90], IVORY, IVORY_D);
  return out ? C(1, out) : 0;
}

// Sulfuras, Hand of Ragnaros (reference 800 x 609, model at full size).
function sulfuras(u, v) {
  const x = ((u + 1) * 128 - 12) / 0.35 + 70, y = 458 - (v + 1) * 64 / 0.35;
  const GOLD_L = [1, 0.9, 0.5], GOLD_D = [0.74, 0.32, 0.04];
  const spikes = [
    [[600, 95], [572, 168], [632, 168]], [[606, 452], [576, 390], [636, 390]],
    [[706, 150], [652, 172], [682, 210]], [[730, 275], [680, 248], [680, 302]],
    [[706, 388], [682, 342], [652, 384]], [[504, 186], [548, 196], [554, 240]],
    [[508, 370], [550, 318], [548, 364]],
    [[74, 285], [182, 263], [182, 307]], [[164, 213], [172, 266], [202, 266]], [[172, 350], [176, 300], [206, 300]],
  ];
  for (const s of spikes) { const c = spikeR(x, y, s[0], s[1], s[2], GOLD_L, GOLD_D); if (c) return C(1, c); }
  // The diamond stud: four facets, a dark rim, a glint.
  const dx = x - 628, dy = y - 272, dd = Math.abs(dx) + Math.abs(dy);
  if (dd < 34) {
    if (dd > 31) return C(1, [0.5, 0.2, 0.02]);
    if (Math.hypot(dx + 9, dy + 9) < 4) return C(1, [1, 1, 0.9]);
    const f = dx < 0 ? (dy < 0 ? 1 : 0.68) : (dy < 0 ? 0.84 : 0.5);
    return C(1, mix(GOLD_D, GOLD_L, f));
  }
  const head = [[545, 176], [561, 160], [664, 160], [680, 176], [680, 380], [664, 396], [561, 396], [545, 380]];
  if (pip(x, y, head)) {
    const e = polyEdge(x, y, head);
    if (e < 3) return C(1, [1, 0.62, 0.15]);
    if (e < 5) return C(1, [0.35, 0.05, 0.01]);
    const band = (y > 182 && y < 226) || (y > 330 && y < 374);
    let c = mix([0.66, 0.11, 0.03], [0.3, 0.04, 0.01], (x - 545) / 135);
    c = rgb(c, 0.85 + 0.3 * fbm(x * 0.06, y * 0.06));       // hammered metal
    if (band) {
      c = rgb([0.34, 0.05, 0.02], 0.85 + 0.3 * fbm(x * 0.05, y * 0.05));
      const by = y < 280 ? 204 : 352;
      const tri = Math.abs((((x - 552) / 22) % 2 + 2) % 2 - 1) * 2 - 1;
      const d = Math.abs(y - (by + 13 * tri));
      if (d < 2.6) c = mix([1, 0.7, 0.2], [1, 0.98, 0.7], 1 - d / 2.6);
      else if (d < 9) c = mix(c, [1, 0.42, 0.05], (1 - (d - 2.6) / 6.4) * 0.8);
    }
    if ((y > 226 && y < 232) || (y > 324 && y < 330)) c = [0.95, 0.5, 0.1];
    return C(1, c);
  }
  // The flared collar, carved with flame glyphs that glow.
  const collar = [[388, 256], [548, 224], [548, 322], [388, 306]];
  if (pip(x, y, collar)) {
    const e = polyEdge(x, y, collar);
    if (e < 2.5) return C(1, [0.95, 0.5, 0.1]);
    const cy = 281 + (x - 388) * 0.016;
    const w = Math.sin((x - 388) * 0.07 + Math.sin((y - cy) * 0.12) * 2.2);
    const g = Math.abs(w);
    let c = mix([0.62, 0.11, 0.03], [0.3, 0.04, 0.01], Math.abs(y - cy) / 45);
    if (Math.abs(y - cy) < 34) {
      if (g < 0.16) c = mix([1, 0.95, 0.6], [1, 0.62, 0.12], g / 0.16);
      else if (g < 0.4) c = mix(c, [1, 0.4, 0.05], (1 - (g - 0.16) / 0.24) * 0.6);
    }
    return C(1, c);
  }
  // The shaft: dark iron split by veins and pools of lava.
  if (x > 200 && x < 392 && y > 264 && y < 301) {
    const cyl = Math.sin(Math.PI * (301 - y) / 37);
    let c = rgb([0.42, 0.07, 0.02], 0.7 + 0.5 * cyl);
    const vein = Math.abs(fbm(x * 0.05, y * 0.15) - 0.5);
    if (vein < 0.03) c = mix([1, 0.85, 0.4], [1, 0.4, 0.05], vein / 0.03);
    for (const cx of [238, 292, 346]) {
      const e = Math.hypot((x - cx) / 23, (y - 282) / 9);
      if (e < 1) c = mix([1, 0.97, 0.7], [1, 0.48, 0.06], e);
      else if (e < 1.4) c = mix(c, [1, 0.4, 0.05], (1.4 - e) / 0.4 * 0.7);
    }
    if (Math.abs(x - 265) < 2 || Math.abs(x - 319) < 2) c = [0.2, 0.03, 0.01];
    return C(1, c);
  }
  const hub = Math.hypot(x - 190, y - 284);
  if (hub < 22) return C(1, hub > 19 ? [0.45, 0.08, 0.02] : mix([1, 0.62, 0.15], [0.42, 0.07, 0.02], Math.hypot(x - 182, y - 276) / 30));
  return 0;
}

// Ashbringer (reference 680 x 190).
const ASH_RUNES = Array.from({ length: 13 }, () => [rand4(), rand4(), rand4()]);
function ashbringer(u, v) {
  const x = (u + 1) * 128 / 0.394 + 8, y = 172 - (v + 1) * 32 / 0.394;
  const GOLD = [0.98, 0.78, 0.3], GOLD_D = [0.58, 0.34, 0.08], RED = [0.76, 0.2, 0.07];
  // The orb: a warm white core, soft rays, a gold rim.
  const orb = Math.hypot(x - 498, y - 46);
  if (orb < 34) {
    const k = orb / 34, ang = Math.atan2(y - 46, x - 498);
    let c = mix([1, 1, 0.95], [0.98, 0.8, 0.42], k * k);
    c = mix(c, [1, 1, 1], Math.pow(Math.abs(Math.cos(ang * 4)), 30) * (1 - k) * 0.6);
    if (k > 0.9) c = [0.85, 0.6, 0.25];
    if (Math.hypot(x - 487, y - 36) < 7) c = [1, 1, 1];
    return C(1, c);
  }
  const guardIn = (px, py) => (px > 222 && px < 252 && py > 22 && py < 168) || (px > 222 && px < 304 && py > 20 && py < 40)
    || (px > 284 && px < 304 && py > 20 && py < 84) || (px > 222 && px < 300 && py > 146 && py < 168)
    || inTri(px, py, [298, 146], [298, 168], [314, 174]);
  if (guardIn(x, y)) {
    const near = r => !guardIn(x - r, y) || !guardIn(x + r, y) || !guardIn(x, y - r) || !guardIn(x, y + r);
    if (near(1.5)) return C(1, GOLD_D);
    if (near(5)) return C(1, mix(GOLD, [1, 0.95, 0.75], !guardIn(x, y - 5) || !guardIn(x - 5, y) ? 0.6 : 0));
    if (near(7)) return C(1, [0.4, 0.08, 0.03]);
    return C(1, rgb(mix([0.55, 0.12, 0.04], RED, (172 - y) / 150), 0.9 + 0.2 * fbm(x * 0.08, y * 0.08)));
  }
  const blade = [[234, 70], [454, 70], [548, 60], [657, 12], [598, 132], [234, 106]];
  if (pip(x, y, blade) && orb > 40) {
    const e = polyEdge(x, y, blade);
    const topEdge = y < 74 || (x > 548 && y < 60 + (x - 548) * -0.44 + 8);
    let c = mix([0.78, 0.79, 0.83], [0.88, 0.89, 0.92], (106 - y) / 36);
    if (e < 1.5) c = topEdge ? [1, 1, 1] : [0.42, 0.42, 0.48];
    else if (e < 8) c = topEdge ? [0.95, 0.96, 0.98] : [0.64, 0.65, 0.7];
    if (Math.abs(y - 99) < 0.8 && x > 250 && x < 590) c = [0.55, 0.56, 0.6];       // the fuller's groove
    if (Math.abs(y - 100.6) < 0.7 && x > 250 && x < 590) c = [0.97, 0.97, 1];
    // Runes engraved along the flat, with a faint holy glow.
    if (x > 300 && x < 488 && y > 78 && y < 98) {
      const i = Math.floor((x - 300) / 14.5), lx = (x - 300) % 14.5, ly = y - 81;
      const [a, b, d] = ASH_RUNES[i] || [0, 0, 0];
      const dist = Math.min(Math.abs(lx - 3 - a * 3), b > 0.4 ? Math.abs(lx - 3 - (ly / 16) * 8) : 9, d > 0.5 && lx > 3 && lx < 11 ? Math.abs(ly - 8) : 9);
      if (lx < 12 && ly > 0 && ly < 16) {
        if (dist < 1.2) c = [0.34, 0.33, 0.38];
        else if (dist < 3.5) c = mix(c, [1, 0.9, 0.55], (1 - (dist - 1.2) / 2.3) * 0.45);
      }
    }
    return C(1, c);
  }
  if (orb < 52) return C((1 - (orb - 34) / 18) * 0.85, [1, 0.86, 0.48]);
  if (x > 206 && x < 228 && y > 70 && y < 106) {
    if (x < 209 || x > 225) return C(1, GOLD_D);
    return C(1, rgb([0.58, 0.14, 0.07], 0.7 + 0.5 * Math.sin(Math.PI * (106 - y) / 36)));
  }
  if (x > 60 && x < 212 && y > 77 && y < 100) {
    const shade = 0.68 + 0.42 * Math.sin(Math.PI * (100 - y) / 23);
    const red = (x > 112 && x < 128) || (x > 166 && x < 182);
    const trim = (x > 109 && x < 113) || (x > 127 && x < 131) || (x > 163 && x < 167) || (x > 181 && x < 185);
    let c = red ? RED : trim ? GOLD : [0.88, 0.87, 0.82];
    if (!red && !trim && ((x * 0.8 + y) % 7 + 7) % 7 < 1) c = [0.72, 0.71, 0.67];   // the grip's binding
    return C(1, rgb(c, shade));
  }
  if (x > 54 && x < 66 && y > 77 && y < 99) return C(1, rgb(RED, 0.75 + 0.4 * Math.sin(Math.PI * (99 - y) / 22)));
  const p = Math.hypot(x - 36, y - 88);
  if (p < 24) {
    if (Math.hypot(x - 28, y - 79) < 5) return C(1, [1, 0.98, 0.85]);
    return C(1, mix([1, 0.9, 0.55], GOLD_D, Math.hypot(x - 28, y - 80) / 32));
  }
  return 0;
}

// Atiesh, Greatstaff of the Guardian (reference 800 x 600).
function atiesh(u, v) {
  const x = (u + 1) * 128 / 0.385 + 64, y = 392 - ((v + 1) * 64 - 20) / 0.385;
  const WOOD = [0.58, 0.37, 0.18], RED = [0.78, 0.08, 0.05];
  const cyl = (y0, y1) => 0.68 + 0.5 * Math.sin(Math.PI * clamp((y1 - y) / (y1 - y0)));
  // The woven head: each strand shaded round.
  const he = Math.hypot((x - 680) / 42, (y - 185) / 21);
  if (he < 1) {
    const a = (x + y) / 7, b = (x - y) / 7;
    const over = (Math.floor(a) + Math.floor(b)) % 2 === 0;
    const f = over ? a - Math.floor(a) : b - Math.floor(b);
    const strand = Math.sin(Math.PI * f);
    const base = over ? [0.66, 0.45, 0.24] : [0.46, 0.29, 0.13];
    return C(1, rgb(base, (0.45 + 0.65 * strand) * (0.55 + 0.6 * (1 - he)) * (y < 190 ? 1.05 : 0.8)));
  }
  if (x > 718 && x < 731 && y > 179 && y < 192) return C(1, rgb([0.7, 0.13, 0.08], cyl(179, 192)));
  const gem = Math.hypot(x - 647, y - 205);
  if (gem < 8) return C(1, Math.hypot(x - 644, y - 202) < 2.6 ? [0.95, 0.98, 1] : mix([0.4, 0.55, 1], [0.08, 0.15, 0.55], gem / 8));
  if (x > 621 && x < 641 && y > 170 && y < 201) return C(1, rgb(RED, 0.75 + 0.35 * Math.sin((x - 621) * 0.5)));
  if (y > 198 && y < 330) {
    const hw = 6 * (1 - (y - 198) / 140) + 0.8;
    if (Math.abs(x - 630) < hw) return C(1, rgb(RED, 0.75 + 0.3 * Math.sin((x - 630) / hw * 1.5 + y * 0.08)));
  }
  for (const [by, c] of [[338, [0.92, 0.9, 0.82]], [348, RED], [358, [0.92, 0.9, 0.82]], [368, RED], [380, [0.88, 0.72, 0.4]]]) {
    const d = Math.hypot(x - 630, y - by);
    if (d < 3.6) return C(1, Math.hypot(x - 629, y - by + 1) < 1.1 ? [1, 1, 1] : c);
  }
  if (Math.abs(x - 630) < 0.8 && y >= 330 && y < 384) return C(1, [0.8, 0.75, 0.65]);
  if (y > 177 && y < 193) {
    if (x > 70 && x < 146) {
      const ring = Math.abs(x - 90) < 1.5 || Math.abs(x - 130) < 1.5;
      return C(1, rgb(ring ? [0.5, 0.52, 0.58] : [0.8, 0.82, 0.88], cyl(177, 193)));
    }
    if (x >= 146 && x < 622) {
      let c;
      if ((x > 553 && x < 563) || (x > 568 && x < 576)) c = mix([0.7, 0.48, 0.14], [1, 0.85, 0.42], Math.sin(Math.PI * (193 - y) / 16));
      else if ((x > 333 && x < 339) || (x > 421 && x < 427)) c = [0.32, 0.18, 0.07];
      else if (x > 339 && x < 421) {
        const a = (x + y * 1.6) / 9, b = (x - y * 1.6) / 9;
        const fa = a - Math.floor(a), fb = b - Math.floor(b);
        c = Math.min(fa, 1 - fa, fb, 1 - fb) < 0.1 ? [0.36, 0.21, 0.09] : rgb([0.66, 0.45, 0.23], 0.85 + 0.3 * (fa - 0.5));
      } else {
        const grain = fbm(x * 0.03, y * 0.5);
        c = rgb(WOOD, 0.75 + 0.5 * grain);
        if (Math.abs(grain - 0.55) < 0.02) c = rgb(WOOD, 0.6);
      }
      return C(1, rgb(c, cyl(177, 193)));
    }
  }
  return 0;
}

// An item-icon stand-in: weapon fn (aspect w:h) rotated 45 degrees over a
// dark tile. dy recenters art that sits off the middle of its texture.
function weaponIcon(fn, aspect, u, v, k, dy = 0) {
  const a = (u + v) / Math.SQRT2, b = (v - u) / Math.SQRT2;
  const wu = a * k, wv = b * k * aspect + dy;
  const bg = mix([0.16, 0.13, 0.2], [0.04, 0.03, 0.06], Math.hypot(u, v) / 1.4);
  const w = Math.abs(wu) <= 1 && Math.abs(wv) <= 1 ? fn(wu, wv) : 0;
  if (!w) return C(1, bg);
  return C(1, mix(bg, [w[1], w[2], w[3]], w[0]));
}

Object.assign(TEXTURES, {
  thunderfury: [512, 128, thunderfury, 4],
  sulfuras: [512, 256, sulfuras, 3],
  ashbringer: [512, 128, ashbringer, 4],
  atiesh: [512, 256, atiesh, 3],
  // Stand-ins for the weapons' own item icons (the game's icons are used in
  // game; these only show where the client lacks them, and in the gallery):
  // the weapon laid diagonally across a dark tile.
  icon_thunderfury: [64, 64, (u, v) => weaponIcon(thunderfury, 4, u, v, 1.25)],
  icon_sulfuras: [64, 64, (u, v) => weaponIcon(sulfuras, 2, u, v, 1.05)],
  icon_ashbringer: [64, 64, (u, v) => weaponIcon(ashbringer, 4, u, v, 1.25)],
  icon_atiesh: [64, 64, (u, v) => weaponIcon(atiesh, 2, u, v, 1.2, 0.56)],
  // A legendary loot frame: an orange-glowing border round an item icon.
  legendframe: [64, 64, (u, v) => {
    const d = Math.max(Math.abs(u), Math.abs(v));
    if (d > 0.98) return 0;
    if (d > 0.8) return [1 - smooth(0.9, 0.98, d) * 0.4, d > 0.86 && d < 0.92 ? 1 : 0.75];
    return 0;
  }],
  // A whirlwind: stacked spiral strokes narrowing to the ground.
  whirlwind: [64, 128, (u, v) => {
    let al = 0;
    for (let i = 0; i < 9; i++) {
      const k = i / 8, cy = -0.88 + k * 1.72, cx = 0.08 * Math.sin(i * 1.7);
      const rx = 0.14 + 0.8 * Math.pow(k, 1.1), ry = 0.05 + 0.07 * k;
      const px = (u - cx) / rx, py = (v - cy) / ry;
      const d = Math.abs(Math.hypot(px, py) - 1) * ry;
      const front = py < 0;
      al = Math.max(al, (1 - smooth(0.012, 0.03, d)) * (front ? 1 : 0.3) * (0.45 + 0.55 * k));
    }
    return clamp(al);
  }],
  // A raven in flight, wings raised.
  raven: [128, 64, (u, v) => {
    const body = Math.hypot((u - 0.05) / 0.32, (v + 0.1) / 0.16) < 1;
    const head = Math.hypot(u - 0.36, v + 0.02) < 0.11;
    const beak = inTri(u, v, [0.44, 0.02], [0.44, -0.1], [0.6, -0.06]);
    const tail = inTri(u, v, [-0.25, -0.05], [-0.25, -0.2], [-0.62, -0.28]);
    const wingL = pip(u, v, [[-0.05, -0.02], [0.2, 0.0], [-0.05, 0.55], [-0.4, 0.92], [-0.38, 0.6], [-0.55, 0.7], [-0.45, 0.42], [-0.62, 0.44]]);
    const wingR = pip(u, v, [[0.0, -0.05], [0.18, 0.02], [0.42, 0.4], [0.62, 0.88], [0.32, 0.58], [0.28, 0.72], [0.1, 0.42]]);
    if (head && Math.hypot(u - 0.39, v + 0.0) < 0.025) return [1, 0.8];
    return body || head || beak || tail || wingL || wingR ? [1, 0.18 + 0.12 * clamp(v + 0.3)] : 0;
  }],
  // A green dragon's eye: scaled lids round a gold iris with a slit pupil.
  dragoneye: [128, 64, (u, v) => {
    const lid = Math.abs(v) < 0.92 * Math.pow(Math.max(0, 1 - u * u), 0.9);
    if (!lid) {
      if (Math.abs(v) < 1.0 * Math.pow(Math.max(0, 1 - u * u * 0.85), 0.7)) return C(1, rgb([0.12, 0.42, 0.22], 0.7 + 0.3 * Math.sin(u * 30) * Math.sin(v * 12)));
      return 0;
    }
    const r = Math.hypot(u * 2, v);
    if (Math.abs(u * 2) < 0.12 * (1 - Math.abs(v)) + 0.02 && r < 0.95) return C(1, [0.02, 0.04, 0.02]);
    if (r < 0.95) return C(1, mix([1, 0.92, 0.4], [0.55, 0.62, 0.12], r) .map((c, i) => c * (0.85 + 0.15 * Math.sin(Math.atan2(v, u) * 18))));
    return C(1, [0.85, 0.96, 0.75]);
  }],
  // A sleepy Z.
  zee: [32, 32, (u, v) => stroke(polyDist(u, v, [[-0.55, 0.6], [0.55, 0.6], [-0.55, -0.6], [0.55, -0.6]]), 0.16)],
  // A titan disc: a carved stone platter with channels and a hub.
  titandisc: [128, 128, (u, v) => {
    const [r, a] = polar(u, v);
    if (r > 0.96) return 0;
    let lum = 0.62 + 0.18 * (u - v) * 0.5;
    if (Math.abs(r - 0.9) < 0.04 || Math.abs(r - 0.55) < 0.03 || Math.abs(r - 0.22) < 0.025) lum = 0.4;
    const k = ((a / (Math.PI * 2)) * 12 % 1 + 1) % 1;
    if (r > 0.58 && r < 0.86 && Math.abs(k - 0.5) < 0.05) lum = 0.42;
    if (r < 0.18) lum = 0.8;
    return [1 - smooth(0.93, 0.96, r), lum];
  }],
  // One twelfth of the disc's ring of glyphs (they light one by one).
  glyphseg: [128, 128, (u, v) => {
    const [r, a] = polar(u, v);
    const a0 = Math.PI / 2 - Math.PI / 6, a1 = Math.PI / 2;
    if (a < a0 || a > a1 || r < 0.6 || r > 0.84) return 0;
    const t = (a - a0) / (a1 - a0), m = (r - 0.6) / 0.24;
    const g = Math.abs(t - 0.5) < 0.07 || (Math.abs(m - 0.5) < 0.1 && Math.abs(t - 0.5) < 0.3) || (Math.abs(t - 0.5 - (m - 0.5) * 0.5) < 0.05 && m > 0.5);
    return g ? 1 : 0;
  }],
  // A skeletal hand reaching up, fingers spread.
  bonehand: [64, 128, (u, v) => {
    const x = u * 32, y = v * 64;
    let d = Infinity;
    const seg = (a, b, w) => { d = Math.min(d, segDist(x, y, a[0], a[1], b[0], b[1]) - w); };
    seg([-3, -64], [-3, -24], 3.2); seg([4, -64], [4, -24], 2.6);
    seg([-9, -24], [9, -24], 2.5); seg([-10, -22], [-8, 0], 2.2); seg([-3, -22], [-2, 2], 2.2); seg([3, -22], [3, 2], 2.2); seg([9, -22], [10, 0], 2.2);
    seg([-10, -22], [-18, -6], 2.2); seg([-18, -6], [-24, 6], 1.8); seg([-24, 6], [-26, 16], 1.6);
    seg([-8, 0], [-11, 22], 1.9); seg([-11, 22], [-12, 38], 1.6); seg([-12, 38], [-12, 48], 1.4);
    seg([-2, 2], [-3, 28], 1.9); seg([-3, 28], [-3, 46], 1.6); seg([-3, 46], [-3, 58], 1.4);
    seg([3, 2], [5, 26], 1.9); seg([5, 26], [6, 42], 1.6); seg([6, 42], [7, 54], 1.4);
    seg([10, 0], [14, 18], 1.8); seg([14, 18], [16, 32], 1.5); seg([16, 32], [17, 40], 1.3);
    if (d > 0.6) return 0;
    const knuckle = [[-8, 0], [-2, 2], [3, 2], [10, 0], [-11, 22], [-3, 28], [5, 26], [14, 18], [-18, -6], [-24, 6]].some(([kx, ky]) => Math.hypot(x - kx, y - ky) < 3);
    return [1 - smooth(-0.6, 0.6, d), knuckle ? 1 : 0.82];
  }],
  // A hoofprint (two toes) and a charging kodo in silhouette.
  hoofprint: [32, 32, (u, v) => {
    const a = Math.hypot((u + 0.32) / 0.3, (v + 0.05) / 0.62), b = Math.hypot((u - 0.32) / 0.3, (v + 0.05) / 0.62);
    return Math.max(1 - smooth(0.85, 1, a), 1 - smooth(0.85, 1, b));
  }],
  kodo: [128, 64, (u, v) => {
    const body = Math.hypot((u + 0.05) / 0.55, (v - 0.02) / 0.42) < 1;
    const hump = Math.hypot((u + 0.2) / 0.35, (v - 0.3) / 0.3) < 1;
    const head = Math.hypot((u - 0.58) / 0.26, (v + 0.05) / 0.28) < 1;
    const horn = inTri(u, v, [0.6, 0.18], [0.72, 0.12], [0.5, 0.62]) || inTri(u, v, [0.72, 0.1], [0.8, 0.02], [0.92, 0.5]);
    const legs = [[-0.42, 0.06], [-0.22, 0.06], [0.18, 0.06], [0.34, 0.06]].some(([lx], i) => Math.abs(u - lx - (i % 2 ? 0.04 : -0.04) * (v + 0.4)) < 0.07 && v < -0.2 && v > -0.95);
    const tail = segDist(u, v, -0.58, 0.15, -0.75, -0.15) < 0.03;
    if (!(body || hump || head || horn || legs || tail)) return 0;
    if (horn) return [1, 0.9];
    return [1, 0.22 + 0.1 * clamp(v + 0.3)];
  }],
  // A kobold's candle: a stub of wax with drips and a wick.
  candle: [32, 64, (u, v) => {
    const x = u * 16, y = v * 32;
    if (Math.abs(x) < 1 && y > 10 && y < 15) return C(1, [0.15, 0.1, 0.05]);
    const drip = (x > 4 && x < 7 && y < 8 && y > 8 - 14 * (0.5 + 0.5 * Math.sin(3))) || (x > -7 && x < -4.5 && y < 8 && y > -4);
    const body = Math.abs(x) < 8 && y > -30 && y < 10 - 1.5 * Math.cos(x / 3);
    if (Math.abs(x) < 9.5 && y > -30 && y < -26) return C(1, [0.5, 0.36, 0.2]);
    if (body || (drip && Math.abs(x) < 9)) return C(1, mix([0.98, 0.94, 0.78], [0.78, 0.7, 0.5], (x + 8) / 16 * 0.8 + (drip ? -0.2 : 0)));
    return 0;
  }],
  // A sheep: puffs of white wool, a dark face and legs.
  sheep: [64, 64, (u, v) => {
    const x = u * 32, y = v * 32;
    const head = Math.hypot((x - 16) / 7, (y - 4) / 8.5) < 1;
    const ear = Math.hypot((x - 11) / 4, (y - 11) / 2) < 1;
    if (head || ear) return C(1, Math.hypot(x - 18, y - 6) < 1.6 ? [0.95, 0.95, 0.9] : [0.18, 0.16, 0.16]);
    for (const [lx] of [[-11], [-4], [5], [11]]) if (Math.abs(x - lx) < 1.7 && y < -6 && y > -19) return C(1, [0.18, 0.16, 0.16]);
    let best = Infinity;
    for (const [cx, cy, r] of [[-12, 0, 9], [-3, 5, 10], [6, 2, 9], [-6, -6, 9], [4, -6, 8], [-13, -5, 6], [9, 7, 6]]) best = Math.min(best, Math.hypot(x - cx, y - cy) / r);
    if (best < 1) return C(1, rgb([0.98, 0.97, 0.93], 0.82 + 0.18 * (1 - best)));
    return 0;
  }],
  // A raptor mid-leap, claws forward.
  raptor: [128, 64, (u, v) => {
    const x = u * 64, y = v * 32;
    const body = Math.hypot((x + 2) / 22, (y - 2) / 10) < 1;
    const neck = segDist(x, y, 14, 6, 30, 16) < 5;
    const head = Math.hypot((x - 36) / 10, (y - 17) / 5) < 1;
    const jaw = inTri(x, y, [30, 14], [50, 12], [32, 10]);
    const tail = segDist(x, y, -20, 4, -58, 14) < 4.5 - (x < -20 ? (-20 - x) * 0.1 : 0);
    const leg = segDist(x, y, -6, -4, -14, -18) < 3.5 || segDist(x, y, -14, -18, -6, -28) < 2.2 || segDist(x, y, 4, -4, 12, -16) < 3.2 || segDist(x, y, 12, -16, 22, -22) < 2;
    const arm = segDist(x, y, 14, 2, 24, -6) < 1.8;
    const crest = inTri(x, y, [28, 20], [40, 21], [26, 28]);
    if (!(body || neck || head || jaw || tail || leg || arm || crest)) return 0;
    if (head && Math.hypot(x - 39, y - 18) < 1.4) return [1, 1];
    return [1, crest ? 0.55 : 0.22 + 0.08 * clamp(y / 20)];
  }],
  // A wisp: a bright core trailing a curled tail, and a ring of five.
  wisp: [64, 64, (u, v) => {
    const r = Math.hypot(u - 0.25, v - 0.25);
    const core = (1 - smooth(0.05, 0.32, r));
    let tail = 0;
    for (let i = 0; i < 24; i++) {
      const t = i / 23, tx = 0.25 - t * 0.9 + 0.1 * Math.sin(t * 6), ty = 0.25 - t * 0.85 + 0.12 * Math.sin(t * 9);
      tail = Math.max(tail, (1 - smooth(0.0, 0.12 * (1 - t) + 0.02, Math.hypot(u - tx, v - ty))) * (1 - t) * 0.7);
    }
    return clamp(Math.max(core, tail, (1 - smooth(0.1, 0.5, r)) * 0.4));
  }],
  // A torn page of an old adventure book, and the book itself.
  page: [32, 64, (u, v) => {
    const x = u * 16, y = v * 32;
    const edge = 13 + 1.2 * Math.sin(y * 1.3);
    if (Math.abs(x) > edge || y > 29 || y < -29 + 2 * Math.sin(x * 1.7)) return 0;
    const line = y < 22 && y > -22 && ((y + 40) % 5) < 1.1 && Math.abs(x) < 10 - (((Math.floor((y + 40) / 5)) * 7) % 5);
    return C(1, line ? [0.42, 0.32, 0.2] : mix([0.96, 0.9, 0.72], [0.82, 0.72, 0.5], Math.hypot(x, y) / 34));
  }],
  openbook: [128, 64, (u, v) => {
    const x = u * 64, y = v * 32;
    const cover = Math.abs(x) < 58 && y > -26 && y < 22 + 3 * Math.cos(x / 20);
    if (!cover) return 0;
    const pageArea = Math.abs(x) < 54 && Math.abs(x) > 2 && y > -22 && y < 18 + 6 * Math.cos(x / 28) * (Math.abs(x) / 54 - 1) * -1;
    if (pageArea) {
      const line = ((y + 40) % 5) < 1 && Math.abs(Math.abs(x) - 28) < 20 && y < 12 && y > -16;
      return C(1, line ? [0.45, 0.35, 0.22] : mix([0.98, 0.93, 0.78], [0.8, 0.7, 0.5], 1 - Math.abs(x) / 54));
    }
    return C(1, Math.abs(x) < 2.5 ? [0.3, 0.15, 0.06] : [0.48, 0.22, 0.08]);
  }],
  // Midsummer: a bonfire's crossed logs, and a juggling torch.
  bonfire: [128, 64, (u, v) => {
    const x = u * 64, y = v * 32;
    const logs = [[-48, -24, 30, 4], [48, -24, -30, 4], [-40, -28, 40, -14], [40, -28, -40, -14], [-20, -30, 12, 18], [20, -30, -12, 18]];
    let hit = null;
    logs.forEach(([ax, ay, bx, by], i) => {
      const d = segDist(x, y, ax, ay, bx, by);
      if (d < 5) hit = mix([0.42, 0.24, 0.1], [0.22, 0.12, 0.05], d / 5 + (i % 2) * 0.2);
      if (d < 5 && Math.hypot(x - bx, y - by) < 5) hit = [0.95, 0.5, 0.12];
    });
    if (hit) return C(1, hit);
    for (const [sx, sy] of [[-52, -30], [-36, -32], [-18, -31], [0, -32], [18, -31], [36, -32], [52, -30]]) {
      if (Math.hypot((x - sx) / 9, (y - sy) / 4) < 1) return C(1, [0.5, 0.48, 0.45]);
    }
    return 0;
  }],
  torch: [32, 64, (u, v) => {
    const x = u * 16, y = v * 32;
    if (Math.abs(x) < 2.6 && y < 8 && y > -30) return C(1, rgb([0.48, 0.28, 0.12], x < 0 ? 1 : 0.75));
    if (Math.abs(x) < 4.4 && y >= 8 && y < 14) return C(1, [0.35, 0.3, 0.28]);
    const f = Math.hypot(x / (7 - (y - 14) * 0.22), (y - 18) / 13);
    if (y > 12 && f < 1) return C(1, mix([1, 0.95, 0.6], [1, 0.4, 0.05], f));
    return 0;
  }],
  // Lunar Festival lantern: a round red paper lantern, gold caps, a tassel.
  lantern: [32, 64, (u, v) => {
    const x = u * 16, y = v * 32;
    if (Math.abs(x) < 6 && ((y > 14 && y < 18) || (y > -16 && y < -12))) return C(1, [1, 0.8, 0.25]);
    if (Math.abs(x) < 0.8 && y > 18 && y < 30) return C(1, [0.4, 0.3, 0.15]);
    if (Math.abs(x) < 1.4 && y < -16 && y > -30) return C(1, [1, 0.72, 0.15]);
    const e = Math.hypot(x / 13, (y - 1) / 14);
    if (e < 1) {
      const rib = Math.abs((Math.asin(clamp(x / 13 / Math.sqrt(Math.max(0.01, 1 - ((y - 1) / 14) ** 2)), -1, 1)) * 3) % 1) < 0.08;
      return C(1, mix([1, 0.72, 0.3], [0.62, 0.04, 0.04], e).map(c => c * (rib ? 0.8 : 1)));
    }
    return 0;
  }],
  // The Darkmoon high striker: a tall post marked off in steps, a bell on
  // top; and the puck that rides up it.
  highstriker: [32, 128, (u, v) => {
    const x = u * 16, y = v * 64;
    const bell = Math.hypot(x / 9, (y - 54) / 7) < 1 && y > 50;
    if (bell || (Math.abs(x) < 10 && y > 48 && y <= 51)) return C(1, mix([1, 0.92, 0.5], [0.8, 0.52, 0.1], Math.hypot(x + 3, y - 57) / 10));
    if (Math.abs(x) < 4 && y > -62 && y < 48) {
      const step = Math.floor((y + 62) / 11) % 2 === 0;
      return C(1, Math.abs(x) < 2.6 ? (step ? [0.95, 0.85, 0.3] : [0.55, 0.2, 0.6]) : [0.35, 0.2, 0.1]);
    }
    if (Math.abs(x) < 12 && y < -56 && y > -64) return C(1, [0.4, 0.24, 0.12]);
    return 0;
  }],
  // A painted egg (zigzag bands, dots), its top half, and a chick.
  egg: [64, 64, (u, v) => {
    const x = u * 32, y = v * 32;
    const e = Math.hypot(x / 20, (y + 2) / (y > -2 ? 28 : 24));
    if (e > 1) return 0;
    let c = [0.98, 0.72, 0.86];
    const zz = 4 + 3 * Math.sin(x * 0.7);
    if (Math.abs(y - zz) < 2.6) c = [0.55, 0.85, 1];
    if (Math.abs(y + 10 - zz * 0.5) < 2) c = [1, 0.95, 0.55];
    if ([[-8, 14], [6, 16], [-2, 20], [10, -14], [-10, -12]].some(([dx, dy]) => Math.hypot(x - dx, y - dy) < 2.2)) c = [0.6, 0.85, 0.45];
    return C(1, rgb(c, 1 - 0.3 * clamp(Math.hypot(x - 8, y - 10) / 30)));
  }],
  eggtop: [64, 64, (u, v) => {
    const r = TEXTURES.egg[2](u, v);
    if (!r) return 0;
    const y = v * 32, x = u * 32;
    const crack = 6 + 3 * (Math.abs((x * 0.35) % 2 - 1));
    return y > crack ? r : 0;
  }],
  eggbottom: [64, 64, (u, v) => {
    const r = TEXTURES.egg[2](u, v);
    if (!r) return 0;
    const y = v * 32, x = u * 32;
    const crack = 6 + 3 * (Math.abs((x * 0.35) % 2 - 1));
    return y <= crack ? r : 0;
  }],
  chick: [32, 32, (u, v) => {
    const x = u * 16, y = v * 16;
    if (inTri(x, y, [7, 3], [7, -1], [12, 1])) return C(1, [1, 0.55, 0.1]);
    if (Math.hypot(x - 3, y - 3) < 1.5) return C(1, [0.1, 0.08, 0.05]);
    const head = Math.hypot(x - 1, y - 2) < 7, body = Math.hypot((x + 1) / 10, (y + 7) / 7) < 1;
    const tuft = segDist(x, y, 0, 8, -1, 12) < 1 || segDist(x, y, 1, 8, 3, 12) < 1;
    if (head || body || tuft) return C(1, rgb([1, 0.9, 0.35], 0.85 + 0.15 * clamp(y / 10 + 0.5)));
    return 0;
  }],
  // A winged spirit, arms raised (the Spirit Healer's silhouette).
  angel: [128, 128, (u, v) => {
    const x = u * 64, y = v * 64;
    const head = Math.hypot(x, y - 26) < 7;
    const robe = pip(x, y, [[-6, 18], [6, 18], [16, -56], [-16, -56]]);
    const arms = segDist(x, y, -5, 14, -18, 34) < 3 || segDist(x, y, 5, 14, 18, 34) < 3;
    let wing = 0;
    for (const s of [-1, 1]) {
      for (let i = 0; i < 6; i++) {
        const ax = s * 6, ay = 10, bx = s * (26 + i * 6), by = 44 - i * 14;
        const d = segDist(x, y, ax, ay, bx, by);
        wing = Math.max(wing, 1 - smooth(4 - i * 0.35, 6.5 - i * 0.4, d));
      }
    }
    if (head || robe || arms) return [1, 1];
    return wing > 0 ? [wing, 0.8] : 0;
  }],
  // One dragon scale: a pointed shield shape with a ridge.
  dragonscale: [32, 32, (u, v) => {
    const inside = Math.abs(u) < 0.8 * Math.sqrt(Math.max(0, (v + 1) / 1.9)) && v < 0.85 && v > -0.95 + Math.abs(u) * 0.2;
    if (!inside) return 0;
    return [1, Math.abs(u) < 0.08 ? 1 : 0.6 + 0.3 * (u < 0 ? 1 : 0)];
  }],
});

// --- Spell effects (World skins) ---------------------------------------------------
let seed5 = 31337;
const rand5 = () => {
  seed5 = (seed5 + 0x6D2B79F5) >>> 0;
  let t = seed5;
  t = Math.imul(t ^ (t >>> 15), t | 1);
  t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
};
// Forked lightning: a jagged main channel bottom to top, with branches
// that split off and thin out (pixel space, 64 x 256).
const FORK = (() => {
  const segs = [];
  let x = 0, y = -124;
  const main = [[x, y]];
  for (let i = 1; i <= 14; i++) { x = Math.max(-22, Math.min(22, x + (rand5() - 0.5) * 22)); y = -124 + i * 248 / 14; main.push([x, y]); }
  for (let i = 0; i < main.length - 1; i++) segs.push([...main[i], ...main[i + 1], 2.2]);
  for (const at of [3, 6, 9, 11]) {
    let [bx, by] = main[at];
    const dir = rand5() < 0.5 ? -1 : 1;
    for (let j = 0; j < 4; j++) {
      const nx = Math.max(-30, Math.min(30, bx + dir * (4 + rand5() * 7))), ny = by + 10 + rand5() * 10;
      segs.push([bx, by, nx, ny, 1.6 - j * 0.3]);
      bx = nx; by = ny;
    }
  }
  return segs;
})();
// A flame tongue in color: white-hot core, yellow, orange, red edges, the
// edges torn by noise.
function flameColor(u, v, seed) {
  const t = (v + 1) / 2;                          // 0 at the base, 1 at the tip
  const sway = (fbm(t * 3 + seed, seed * 2) - 0.5) * 0.7 * t;
  const w = 0.62 * Math.pow(Math.max(0, 1 - t), 0.75) * (t < 0.12 ? Math.sqrt(t / 0.12) : 1);
  const n = fbm(u * 3 + seed, t * 5 - seed, 3);
  const heat = 1 - Math.abs(u - sway) / Math.max(0.01, w) - (n - 0.5) * 0.6;
  if (heat <= 0) return 0;
  const a = clamp(heat * 3);
  const c = heat > 0.7 ? mix([1, 0.85, 0.4], [1, 1, 0.9], (heat - 0.7) / 0.3)
    : heat > 0.35 ? mix([1, 0.45, 0.06], [1, 0.85, 0.4], (heat - 0.35) / 0.35)
    : mix([0.7, 0.08, 0.02], [1, 0.45, 0.06], heat / 0.35);
  return C(a, c);
}

Object.assign(TEXTURES, {
  forkbolt: [64, 256, (u, v) => {
    const x = u * 32, y = v * 128;
    let core = 0, glow = 0;
    for (const [ax, ay, bx, by, w] of FORK) {
      const d = segDist(x, y, ax, ay, bx, by);
      core = Math.max(core, 1 - smooth(w * 0.5, w, d));
      glow = Math.max(glow, Math.exp(-d / 6) * (w / 2.2));
    }
    return [clamp(Math.max(core, glow * 0.55)), core > 0.5 ? 1 : 0.75];
  }],
  flamecolor: [64, 128, (u, v) => flameColor(u, v, 1.3), 3],
  flamecolor2: [64, 128, (u, v) => flameColor(u, v, 4.7), 3],
  // A radiant holy star: four long rays, four short, a soft heart.
  holystar: [128, 128, (u, v) => {
    const [r, a] = polar(u, v);
    const long = Math.pow(Math.abs(Math.cos(a * 2)), 60) * (1 - smooth(0.2, 1, r));
    const short = Math.pow(Math.abs(Math.cos(a * 2 + Math.PI / 2)), 40) * (1 - smooth(0.1, 0.6, r)) * 0.8;
    const core = 1 - smooth(0, 0.28, r);
    const halo = (1 - smooth(0.1, 0.75, r)) * 0.35;
    return clamp(Math.max(long, short, core, halo));
  }],
  // Consecrated ground: a ring of runes seen at an angle, a faint fill.
  consecrate: [128, 64, (u, v) => {
    const r = Math.hypot(u, v), a = Math.atan2(v, u);
    if (r > 0.98) return 0;
    let al = (1 - smooth(0.6, 0.98, r)) * 0.22;
    al = Math.max(al, stroke(Math.abs(r - 0.92), 0.035), stroke(Math.abs(r - 0.7), 0.02));
    if (r > 0.74 && r < 0.88) {
      const k = ((a / (Math.PI * 2)) * 18 % 1 + 1) % 1, m = (r - 0.74) / 0.14;
      if (Math.abs(k - 0.5) < 0.06 || (Math.abs(m - 0.5) < 0.12 && Math.abs(k - 0.5) < 0.25) || (Math.abs(k - 0.3 - m * 0.4) < 0.05)) al = 1;
    }
    // Eight spokes of light from a small inner ring.
    const sp = ((a / (Math.PI * 2)) * 8 % 1 + 1) % 1;
    if (r > 0.2 && r < 0.68) al = Math.max(al, stroke(Math.abs(sp - 0.5) * r * 0.8, 0.012) * 0.75);
    al = Math.max(al, stroke(Math.abs(r - 0.2), 0.02) * 0.8);
    return al;
  }],
  // A dust shockwave on the ground, seen at an angle.
  groundring: [128, 64, (u, v) => {
    const r = Math.hypot(u, v);
    const ring = Math.exp(-Math.pow((r - 0.8) / 0.11, 2));
    return clamp(ring * (0.55 + 0.6 * fbm(u * 4, v * 4)) * (1 - smooth(0.92, 1, r)));
  }],
  // A frost-nova ring of jagged shards pointing outward.
  novaring: [128, 128, (u, v) => {
    const [r, a] = polar(u, v);
    const n = 18, k = ((a / (Math.PI * 2)) * n % 1 + 1) % 1;
    const len = 0.78 + 0.16 * hash2(Math.floor((a / (Math.PI * 2)) * n + 50), 3);
    const half = 0.5 * (1 - (r - 0.62) / (len - 0.62));
    if (r > 0.62 && r < len && Math.abs(k - 0.5) < half * 0.9) return [1, Math.abs(k - 0.5) < 0.08 ? 1 : 0.7];
    return r > 0.55 && r < 0.66 ? [0.7, 0.85] : 0;
  }],
  // Billowing smoke: a soft blob, broken up.
  smoke: [64, 64, (u, v) => {
    const r = Math.hypot(u, v);
    const n = fbm(u * 2.5 + 3, v * 2.5 + 7);
    const a = (1 - smooth(0.25, 0.95, r + (n - 0.5) * 0.5)) * (0.55 + 0.45 * n);
    return a > 0 ? [a, 0.75 + 0.25 * n] : 0;
  }],
  // A rising spiral of light (a resurrection), brighter in front.
  rezspiral: [64, 128, (u, v) => {
    let al = 0;
    for (let i = 0; i < 120; i++) {
      const t = i / 119, ph = t * Math.PI * 4;
      const x = 0.7 * Math.sin(ph) * (1 - 0.3 * t), y = -0.95 + t * 1.9;
      const front = Math.cos(ph) > 0 ? 1 : 0.25;
      const d = Math.hypot(u - x, (v - y) * 0.5);
      al = Math.max(al, (1 - smooth(0.015, 0.05, d)) * front * (1 - t * 0.5));
    }
    return clamp(al);
  }],
  // A swirling shadow orb: a dark heart, curling arms, a bright rim.
  shadoworb: [64, 64, (u, v) => {
    const [r, a] = polar(u, v);
    if (r > 0.95) return 0;
    const arms = Math.pow(0.5 + 0.5 * Math.sin(a * 3 - r * 10), 2);
    const rim = stroke(Math.abs(r - 0.82), 0.1);
    return [1 - smooth(0.85, 0.95, r), Math.max(0.12, arms * 0.55 * smooth(0.15, 0.6, r), rim)];
  }],
  // A tumbling rock.
  rock: [32, 32, (u, v) => {
    const [r, a] = polar(u, v);
    const edge = 0.72 + 0.16 * Math.sin(a * 3 + 1) + 0.08 * Math.sin(a * 7);
    if (r > edge) return 0;
    const lit = clamp(0.5 + (-u + v) * 0.4);
    return [1, 0.35 + 0.5 * lit * (0.8 + 0.4 * fbm(u * 3, v * 3))];
  }],
  // An arcane missile: a bright head.
  arcorb: [32, 32, (u, v) => {
    const r = Math.hypot(u, v);
    return clamp(Math.max(1 - smooth(0.1, 0.35, r), (1 - smooth(0.2, 1, r)) * 0.6));
  }],
});

const outDir = process.argv[2] || path.join(__dirname, '..', 'Media', 'Textures');
fs.mkdirSync(outDir, { recursive: true });
for (const [name, [w, h, fn, ss]] of Object.entries(TEXTURES)) {
  const buf = render(w, h, fn, ss || 4);
  fs.writeFileSync(path.join(outDir, name + '.tga'), buf);
  console.log(name + '.tga', w + 'x' + h);
}
