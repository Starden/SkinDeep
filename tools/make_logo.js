// Builds SkinDeep's 400x400 project logo (CurseForge avatar): a crit burst
// behind a chunky 3D pixel "SD", on a dark rounded tile. No dependencies.
// Usage: node tools/make_logo.js [out.png]   (default: docs/logo.png)
'use strict';
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const SIZE = 400, SS = 3;
const GLYPHS = {
  S: ['.####', '#....', '#....', '.###.', '....#', '....#', '####.'],
  D: ['###..', '#..#.', '#...#', '#...#', '#...#', '#..#.', '###..'],
};
const clamp = (v, a = 0, b = 1) => Math.max(a, Math.min(b, v));
const mix = (a, b, k) => a.map((v, i) => v + (b[i] - v) * k);

const BG = [29, 27, 36], BG_TOP = [44, 38, 52], GOLD = [255, 205, 70], ORANGE = [255, 120, 30];
const EXTRUDE = [[150, 40, 10], [90, 20, 5], [40, 8, 2]];
const PX = 26;                       // pixel size of the letters
const TEXT_W = (5 * 2 + 1) * PX, TEXT_H = 7 * PX;
const TX = (SIZE - TEXT_W) / 2, TY = (SIZE - TEXT_H) / 2 + 6;

function letterAt(x, y, ox, oy) {
  const lx = x - TX - ox, ly = y - TY - oy;
  if (lx < 0 || ly < 0 || ly >= TEXT_H) return false;
  const col = Math.floor(lx / PX), row = Math.floor(ly / PX);
  const letter = col < 5 ? 'S' : col >= 6 && col < 11 ? 'D' : null;
  if (!letter) return false;
  return GLYPHS[letter][row][col < 5 ? col : col - 6] === '#';
}

function shade(x, y) {
  // Rounded tile.
  const r = 64, q = [Math.abs(x - SIZE / 2) - (SIZE / 2 - r), Math.abs(y - SIZE / 2) - (SIZE / 2 - r)];
  const d = Math.hypot(Math.max(q[0], 0), Math.max(q[1], 0)) + Math.min(Math.max(q[0], q[1]), 0) - r;
  if (d > 0) return [0, 0, 0, 0];
  let c = mix(BG_TOP, BG, y / SIZE);
  // Burst: twelve rays with a hot core.
  const u = (x - SIZE / 2) / (SIZE / 2), v = (y - SIZE / 2) / (SIZE / 2);
  const rr = Math.hypot(u, v), a = Math.atan2(v, u);
  const rays = Math.pow(Math.abs(Math.cos(a * 6)), 16) * clamp(1 - rr / 0.95);
  const core = clamp(1 - rr / 0.55) ** 2;
  c = mix(c, ORANGE, clamp(rays * 0.75 + core * 0.55));
  // Letters: three extrusion steps, a black outline, then the gold face.
  if (letterAt(x, y, 0, 0)) return [...mix(GOLD, [255, 245, 190], clamp(1 - (y - TY) / TEXT_H) * 0.5), 255];
  const o = 4;
  for (const [dx, dy] of [[o, 0], [-o, 0], [0, o], [0, -o], [o, o], [-o, -o], [o, -o], [-o, o]]) {
    if (letterAt(x, y, dx, dy)) return [10, 6, 4, 255];
  }
  for (let i = 0; i < EXTRUDE.length; i++) {
    const s = (i + 1) * 7;
    if (letterAt(x, y, s, s)) return [...EXTRUDE[i], 255];
  }
  return [...c, 255];
}

const rgba = Buffer.alloc(SIZE * SIZE * 4);
for (let y = 0; y < SIZE; y++) {
  for (let x = 0; x < SIZE; x++) {
    const acc = [0, 0, 0, 0];
    for (let sy = 0; sy < SS; sy++) for (let sx = 0; sx < SS; sx++) {
      const s = shade(x + (sx + 0.5) / SS, y + (sy + 0.5) / SS);
      for (let k = 0; k < 3; k++) acc[k] += s[k] * s[3] / 255;
      acc[3] += s[3];
    }
    const i = (y * SIZE + x) * 4, a = acc[3] / (SS * SS);
    for (let k = 0; k < 3; k++) rgba[i + k] = a > 0 ? Math.round(acc[k] / (acc[3] / 255)) : 0;
    rgba[i + 3] = Math.round(a);
  }
}

// PNG encoding (RGBA, no filter).
const crcT = Array.from({ length: 256 }, (_, n) => { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; return c >>> 0; });
const crc = b => { let c = 0xffffffff; for (const x of b) c = crcT[(c ^ x) & 255] ^ (c >>> 8); return (c ^ 0xffffffff) >>> 0; };
const chunk = (t, d) => { const l = Buffer.alloc(4); l.writeUInt32BE(d.length); const td = Buffer.concat([Buffer.from(t), d]); const c = Buffer.alloc(4); c.writeUInt32BE(crc(td)); return Buffer.concat([l, td, c]); };
const raw = Buffer.alloc((SIZE * 4 + 1) * SIZE);
for (let y = 0; y < SIZE; y++) rgba.copy(raw, y * (SIZE * 4 + 1) + 1, y * SIZE * 4, (y + 1) * SIZE * 4);
const ihdr = Buffer.alloc(13); ihdr.writeUInt32BE(SIZE, 0); ihdr.writeUInt32BE(SIZE, 4); ihdr[8] = 8; ihdr[9] = 6;
const png = Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk('IHDR', ihdr), chunk('IDAT', zlib.deflateSync(raw)), chunk('IEND', Buffer.alloc(0))]);

const out = process.argv[2] || path.join(__dirname, '..', 'docs', 'logo.png');
fs.mkdirSync(path.dirname(out), { recursive: true });
fs.writeFileSync(out, png);
console.log('wrote', out, png.length, 'bytes');
