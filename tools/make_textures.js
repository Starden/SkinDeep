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
