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
// an alpha 0..1 (white texture) or [alpha, luminance] for shaded art that is
// still tinted in game (luminance multiplies the vertex color).
function render(w, h, alphaFn, ss = 4) {
  const px = Buffer.alloc(w * h * 4);
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      let a = 0, l = 0;
      for (let sy = 0; sy < ss; sy++) for (let sx = 0; sx < ss; sx++) {
        const u = ((x + (sx + 0.5) / ss) / w) * 2 - 1;
        const v = 1 - ((y + (sy + 0.5) / ss) / h) * 2;
        const r = alphaFn(u, v, w, h);
        const al = clamp(Array.isArray(r) ? r[0] : r);
        a += al;
        l += al * clamp(Array.isArray(r) ? r[1] : 1);
      }
      const lum = a > 0 ? l / a : 1;
      a /= ss * ss;
      // TGA stores rows bottom-up; y here counts from the top.
      const i = ((h - 1 - y) * w + x) * 4;
      const c = Math.round(lum * 255);
      px[i] = c; px[i + 1] = c; px[i + 2] = c; px[i + 3] = Math.round(a * 255);
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

const outDir = process.argv[2] || path.join(__dirname, '..', 'Media', 'Textures');
fs.mkdirSync(outDir, { recursive: true });
for (const [name, [w, h, fn, ss]] of Object.entries(TEXTURES)) {
  const buf = render(w, h, fn, ss || 4);
  fs.writeFileSync(path.join(outDir, name + '.tga'), buf);
  console.log(name + '.tga', w + 'x' + h);
}
