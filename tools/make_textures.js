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
  // Spiked crown: a band with five points, the middle one tallest.
  crown: [64, 40, (u, v) => {
    const band = (Math.abs(u) < 0.9 && v > -0.85 && v < -0.35) ? 1 : 0;
    let spike = 0;
    for (let i = 0; i < 5; i++) {
      const cx = -0.72 + i * 0.36, top = i === 2 ? 0.95 : 0.6;
      const t = (v + 0.35) / (top + 0.35);
      if (t >= 0 && t <= 1 && Math.abs(u - cx) < 0.15 * (1 - t)) spike = 1;
    }
    return [Math.max(band, spike), band ? 0.75 : 1];
  }],
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
};

const outDir = process.argv[2] || path.join(__dirname, '..', 'Media', 'Textures');
fs.mkdirSync(outDir, { recursive: true });
for (const [name, [w, h, fn, ss]] of Object.entries(TEXTURES)) {
  const buf = render(w, h, fn, ss || 4);
  fs.writeFileSync(path.join(outDir, name + '.tga'), buf);
  console.log(name + '.tga', w + 'x' + h);
}
