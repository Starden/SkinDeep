// Builds SkinDeep's pixel fonts (TrueType) from one 5x7 bitmap set, each
// family drawing the "pixels" with a different shape. No dependencies.
// Usage: node tools/make_fonts.js [outDir]   (default: Media/Fonts)
'use strict';
const fs = require('fs');
const path = require('path');

const GLYPHS = {
  '0': ['.###.', '#...#', '#..##', '#.#.#', '##..#', '#...#', '.###.'],
  '1': ['..#..', '.##..', '..#..', '..#..', '..#..', '..#..', '.###.'],
  '2': ['.###.', '#...#', '....#', '...#.', '..#..', '.#...', '#####'],
  '3': ['#####', '...#.', '..#..', '...#.', '....#', '#...#', '.###.'],
  '4': ['...#.', '..##.', '.#.#.', '#..#.', '#####', '...#.', '...#.'],
  '5': ['#####', '#....', '####.', '....#', '....#', '#...#', '.###.'],
  '6': ['..##.', '.#...', '#....', '####.', '#...#', '#...#', '.###.'],
  '7': ['#####', '....#', '...#.', '..#..', '.#...', '.#...', '.#...'],
  '8': ['.###.', '#...#', '#...#', '.###.', '#...#', '#...#', '.###.'],
  '9': ['.###.', '#...#', '#...#', '.####', '....#', '...#.', '.##..'],
  'A': ['.###.', '#...#', '#...#', '#####', '#...#', '#...#', '#...#'],
  'B': ['####.', '#...#', '#...#', '####.', '#...#', '#...#', '####.'],
  'C': ['.###.', '#...#', '#....', '#....', '#....', '#...#', '.###.'],
  'D': ['###..', '#..#.', '#...#', '#...#', '#...#', '#..#.', '###..'],
  'E': ['#####', '#....', '#....', '####.', '#....', '#....', '#####'],
  'F': ['#####', '#....', '#....', '####.', '#....', '#....', '#....'],
  'G': ['.###.', '#...#', '#....', '#.###', '#...#', '#...#', '.####'],
  'H': ['#...#', '#...#', '#...#', '#####', '#...#', '#...#', '#...#'],
  'I': ['.###.', '..#..', '..#..', '..#..', '..#..', '..#..', '.###.'],
  'J': ['..###', '...#.', '...#.', '...#.', '...#.', '#..#.', '.##..'],
  'K': ['#...#', '#..#.', '#.#..', '##...', '#.#..', '#..#.', '#...#'],
  'L': ['#....', '#....', '#....', '#....', '#....', '#....', '#####'],
  'M': ['#...#', '##.##', '#.#.#', '#.#.#', '#...#', '#...#', '#...#'],
  'N': ['#...#', '#...#', '##..#', '#.#.#', '#..##', '#...#', '#...#'],
  'O': ['.###.', '#...#', '#...#', '#...#', '#...#', '#...#', '.###.'],
  'P': ['####.', '#...#', '#...#', '####.', '#....', '#....', '#....'],
  'Q': ['.###.', '#...#', '#...#', '#...#', '#.#.#', '#..#.', '.##.#'],
  'R': ['####.', '#...#', '#...#', '####.', '#.#..', '#..#.', '#...#'],
  'S': ['.####', '#....', '#....', '.###.', '....#', '....#', '####.'],
  'T': ['#####', '..#..', '..#..', '..#..', '..#..', '..#..', '..#..'],
  'U': ['#...#', '#...#', '#...#', '#...#', '#...#', '#...#', '.###.'],
  'V': ['#...#', '#...#', '#...#', '#...#', '#...#', '.#.#.', '..#..'],
  'W': ['#...#', '#...#', '#...#', '#.#.#', '#.#.#', '#.#.#', '.#.#.'],
  'X': ['#...#', '#...#', '.#.#.', '..#..', '.#.#.', '#...#', '#...#'],
  'Y': ['#...#', '#...#', '.#.#.', '..#..', '..#..', '..#..', '..#..'],
  'Z': ['#####', '....#', '...#.', '..#..', '.#...', '#....', '#####'],
  '+': ['.....', '..#..', '..#..', '#####', '..#..', '..#..', '.....'],
  '-': ['.....', '.....', '.....', '#####', '.....', '.....', '.....'],
  '.': ['.....', '.....', '.....', '.....', '.....', '.##..', '.##..'],
  ',': ['.....', '.....', '.....', '.....', '.##..', '..#..', '.#...'],
  '!': ['..#..', '..#..', '..#..', '..#..', '..#..', '.....', '..#..'],
  '?': ['.###.', '#...#', '....#', '...#.', '..#..', '.....', '..#..'],
  '%': ['##...', '##..#', '...#.', '..#..', '.#...', '#..##', '...##'],
  '(': ['...#.', '..#..', '.#...', '.#...', '.#...', '..#..', '...#.'],
  ')': ['.#...', '..#..', '...#.', '...#.', '...#.', '..#..', '.#...'],
  '/': ['.....', '....#', '...#.', '..#..', '.#...', '#....', '.....'],
  ':': ['.....', '.##..', '.##..', '.....', '.##..', '.##..', '.....'],
  '*': ['.....', '#.#.#', '.###.', '#####', '.###.', '#.#.#', '.....'],
  "'": ['..#..', '..#..', '.#...', '.....', '.....', '.....', '.....'],
  '$': ['..#..', '.####', '#.#..', '.###.', '..#.#', '####.', '..#..'],
  '#': ['.#.#.', '.#.#.', '#####', '.#.#.', '#####', '.#.#.', '.#.#.'],
};

const CELL = 100;          // font units per pixel
const ROWS = 7, COLS = 5;
const EM = 1000, ASC = 900, DESC = 200;

// Pixel shapes. Each returns contours (arrays of [x,y], clockwise, y up)
// for the pixel whose bottom-left corner is (x, y).
const SHAPES = {
  // Solid squares, a hair larger than the cell so neighbours fuse.
  block: (x, y) => [[[x - 3, y - 3], [x - 3, y + CELL + 3], [x + CELL + 3, y + CELL + 3], [x + CELL + 3, y - 3]]],
  // Round LED dots (octagons) with gaps between them.
  led: (x, y) => {
    const cx = x + CELL / 2, cy = y + CELL / 2, r = 46, pts = [];
    for (let i = 0; i < 8; i++) {
      const a = (112.5 - i * 45) * Math.PI / 180; // decreasing angle = clockwise
      pts.push([Math.round(cx + r * Math.cos(a)), Math.round(cy + r * Math.sin(a))]);
    }
    return [pts];
  },
  // Diamonds that overlap at the tips: a faceted, crystalline stroke.
  shard: (x, y) => {
    const cx = x + CELL / 2, cy = y + CELL / 2, r = 62;
    return [[[cx, cy - r], [cx - r, cy], [cx, cy + r], [cx + r, cy]]];
  },
  // Squares sheared to the right: a fast, slanted look.
  slash: (x, y) => {
    const k = 0.28, x0 = x - 2, x1 = x + CELL + 2, y0 = y - 2, y1 = y + CELL + 2;
    return [[[x0 + y0 * k, y0], [x0 + y1 * k, y1], [x1 + y1 * k, y1], [x1 + y0 * k, y0]].map(p => [Math.round(p[0]), p[1]])];
  },
};

function glyphContours(rows, shape) {
  const contours = [];
  for (let r = 0; r < ROWS; r++) {
    for (let c = 0; c < COLS; c++) {
      if (rows[r][c] !== '#') continue;
      const x = c * CELL + 50, y = (ROWS - 1 - r) * CELL;
      for (const ct of SHAPES[shape](x, y)) contours.push(ct);
    }
  }
  return contours;
}

// ---- binary helpers -------------------------------------------------------
class Buf {
  constructor() { this.parts = []; this.len = 0; }
  u8(v) { const b = Buffer.alloc(1); b.writeUInt8(v & 0xff); this.push(b); }
  u16(v) { const b = Buffer.alloc(2); b.writeUInt16BE(v & 0xffff); this.push(b); }
  i16(v) { const b = Buffer.alloc(2); b.writeInt16BE(v); this.push(b); }
  u32(v) { const b = Buffer.alloc(4); b.writeUInt32BE(v >>> 0); this.push(b); }
  bytes(b) { this.push(Buffer.from(b)); }
  push(b) { this.parts.push(b); this.len += b.length; }
  out() { return Buffer.concat(this.parts); }
}

function checksum(buf) {
  const padded = Buffer.concat([buf, Buffer.alloc((4 - (buf.length % 4)) % 4)]);
  let sum = 0;
  for (let i = 0; i < padded.length; i += 4) sum = (sum + padded.readUInt32BE(i)) >>> 0;
  return sum;
}

function buildFont(family, shape, advanceExtra) {
  // Glyph order: .notdef, space, then each defined character.
  const chars = Object.keys(GLYPHS);
  const glyphs = [{ name: '.notdef', contours: [[[50, 0], [50, 700], [550, 700], [550, 0]], [[100, 50], [500, 50], [500, 650], [100, 650]]] },
                  { name: 'space', contours: [] }];
  const cmap = new Map(); // code -> glyph index
  cmap.set(32, 1);
  for (const ch of chars) {
    const gi = glyphs.length;
    glyphs.push({ name: ch, contours: glyphContours(GLYPHS[ch], shape) });
    cmap.set(ch.charCodeAt(0), gi);
    if (/[A-Z]/.test(ch)) cmap.set(ch.toLowerCase().charCodeAt(0), gi); // lowercase shares the caps
  }
  cmap.set(0xA0, 1); // no-break space

  const ADV = COLS * CELL + 100 + advanceExtra;
  let gxMin = 0, gyMin = 0, gxMax = 0, gyMax = 0, maxPts = 0, maxCts = 0;
  const glyf = new Buf(), loca = [], hmtx = new Buf();
  for (let i = 0; i < glyphs.length; i++) {
    const g = glyphs[i];
    const adv = g.name === 'space' ? 400 : ADV;
    loca.push(glyf.len);
    if (g.contours.length === 0) { hmtx.u16(adv); hmtx.i16(0); continue; }
    const pts = g.contours.flat();
    const xs = pts.map(p => p[0]), ys = pts.map(p => p[1]);
    const xMin = Math.min(...xs), xMax = Math.max(...xs), yMin = Math.min(...ys), yMax = Math.max(...ys);
    gxMin = Math.min(gxMin, xMin); gyMin = Math.min(gyMin, yMin);
    gxMax = Math.max(gxMax, xMax); gyMax = Math.max(gyMax, yMax);
    maxPts = Math.max(maxPts, pts.length); maxCts = Math.max(maxCts, g.contours.length);
    hmtx.u16(adv); hmtx.i16(xMin);
    glyf.i16(g.contours.length); glyf.i16(xMin); glyf.i16(yMin); glyf.i16(xMax); glyf.i16(yMax);
    let end = -1;
    for (const ct of g.contours) { end += ct.length; glyf.u16(end); }
    glyf.u16(0); // no instructions
    for (let k = 0; k < pts.length; k++) glyf.u8(0x01); // on-curve, long coords
    let px = 0; for (const p of pts) { glyf.i16(p[0] - px); px = p[0]; }
    let py = 0; for (const p of pts) { glyf.i16(p[1] - py); py = p[1]; }
    while (glyf.len % 4) glyf.u8(0);
  }
  loca.push(glyf.len);
  const numGlyphs = glyphs.length;

  const tables = {};
  const head = new Buf();
  head.u32(0x00010000); head.u32(0x00010000); head.u32(0); head.u32(0x5F0F3CF5);
  head.u16(0x000B); head.u16(EM);
  head.u32(0); head.u32(0); head.u32(0); head.u32(0); // created, modified
  head.i16(gxMin); head.i16(gyMin); head.i16(gxMax); head.i16(gyMax);
  head.u16(0); head.u16(8); head.i16(2); head.i16(1); head.i16(0);
  tables.head = head.out();

  const hhea = new Buf();
  hhea.u32(0x00010000); hhea.i16(ASC); hhea.i16(-DESC); hhea.i16(0);
  hhea.u16(ADV); hhea.i16(gxMin); hhea.i16(0); hhea.i16(gxMax);
  hhea.i16(1); hhea.i16(0); hhea.i16(0);
  for (let i = 0; i < 4; i++) hhea.i16(0);
  hhea.i16(0); hhea.u16(numGlyphs);
  tables.hhea = hhea.out();

  const maxp = new Buf();
  maxp.u32(0x00010000); maxp.u16(numGlyphs); maxp.u16(maxPts); maxp.u16(maxCts);
  maxp.u16(0); maxp.u16(0); maxp.u16(2);
  for (let i = 0; i < 7; i++) maxp.u16(0);
  maxp.u16(0); maxp.u16(0);
  tables.maxp = maxp.out();

  const codes = [...cmap.keys()].sort((a, b) => a - b);
  const os2 = new Buf();
  os2.u16(4); os2.i16(ADV); os2.u16(700); os2.u16(5); os2.u16(0);
  for (const v of [650, 600, 0, 75, 650, 600, 0, 350, 50, 300]) os2.i16(v);
  os2.i16(0);
  os2.bytes([2, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
  os2.u32(1); os2.u32(0); os2.u32(0); os2.u32(0);
  os2.bytes(Buffer.from('SKDP', 'ascii'));
  os2.u16(0x0040); os2.u16(codes[0]); os2.u16(codes[codes.length - 1]);
  os2.i16(ASC); os2.i16(-DESC); os2.i16(0); os2.u16(ASC); os2.u16(DESC);
  os2.u32(1); os2.u32(0);
  os2.i16(500); os2.i16(700); os2.u16(0); os2.u16(32); os2.u16(1);
  tables['OS/2'] = os2.out();

  tables.hmtx = hmtx.out();

  // cmap format 4, one segment per code plus the 0xFFFF terminator.
  const segs = codes.map(c => ({ start: c, end: c, delta: (cmap.get(c) - c) & 0xffff }));
  segs.push({ start: 0xffff, end: 0xffff, delta: 1 });
  const segCount = segs.length;
  const sr = 2 * Math.pow(2, Math.floor(Math.log2(segCount)));
  const sub = new Buf();
  sub.u16(4); sub.u16(16 + segCount * 8); sub.u16(0);
  sub.u16(segCount * 2); sub.u16(sr); sub.u16(Math.log2(sr / 2)); sub.u16(segCount * 2 - sr);
  for (const s of segs) sub.u16(s.end);
  sub.u16(0);
  for (const s of segs) sub.u16(s.start);
  for (const s of segs) sub.u16(s.delta);
  for (const s of segs) sub.u16(0);
  const cm = new Buf();
  cm.u16(0); cm.u16(1); cm.u16(3); cm.u16(1); cm.u32(12); cm.push(sub.out());
  tables.cmap = cm.out();

  const lo = new Buf(); for (const o of loca) lo.u32(o);
  tables.loca = lo.out();
  tables.glyf = glyf.out();

  const names = { 1: family, 2: 'Regular', 3: family + ' 1.0', 4: family, 5: 'Version 1.0', 6: family.replace(/\s+/g, '') };
  const ids = Object.keys(names).map(Number);
  const nm = new Buf(), strs = new Buf();
  nm.u16(0); nm.u16(ids.length); nm.u16(6 + ids.length * 12);
  for (const id of ids) {
    const s = Buffer.from(names[id], 'utf16le').swap16();
    nm.u16(3); nm.u16(1); nm.u16(0x409); nm.u16(id); nm.u16(s.length); nm.u16(strs.len);
    strs.push(s);
  }
  nm.push(strs.out());
  tables.name = nm.out();

  const post = new Buf();
  post.u32(0x00030000); post.u32(0); post.i16(-100); post.i16(50);
  post.u32(0); post.u32(0); post.u32(0); post.u32(0); post.u32(0);
  tables.post = post.out();

  // Assemble: directory sorted by tag, tables 4-byte aligned.
  const tags = Object.keys(tables).sort();
  const n = tags.length;
  const srT = 16 * Math.pow(2, Math.floor(Math.log2(n)));
  const dir = new Buf();
  dir.u32(0x00010000); dir.u16(n); dir.u16(srT); dir.u16(Math.log2(srT / 16)); dir.u16(n * 16 - srT);
  let offset = 12 + n * 16;
  const bodies = [];
  for (const tag of tags) {
    const data = tables[tag];
    dir.bytes(Buffer.from(tag.padEnd(4, ' '), 'ascii'));
    dir.u32(checksum(data)); dir.u32(offset); dir.u32(data.length);
    const padded = Buffer.concat([data, Buffer.alloc((4 - (data.length % 4)) % 4)]);
    bodies.push({ tag, padded, offset });
    offset += padded.length;
  }
  const font = Buffer.concat([dir.out(), ...bodies.map(b => b.padded)]);
  const headOff = bodies.find(b => b.tag === 'head').offset;
  font.writeUInt32BE((0xB1B0AFBA - checksum(font)) >>> 0, headOff + 8);
  return font;
}

const outDir = process.argv[2] || path.join(__dirname, '..', 'Media', 'Fonts');
fs.mkdirSync(outDir, { recursive: true });
const families = [
  ['SkinDeep Block', 'block', 0, 'SkinDeepBlock.ttf'],
  ['SkinDeep LED', 'led', 0, 'SkinDeepLED.ttf'],
  ['SkinDeep Shard', 'shard', 20, 'SkinDeepShard.ttf'],
  ['SkinDeep Slash', 'slash', 160, 'SkinDeepSlash.ttf'],
];
for (const [fam, shape, extra, file] of families) {
  const buf = buildFont(fam, shape, extra);
  fs.writeFileSync(path.join(outDir, file), buf);
  console.log(file, buf.length, 'bytes');
}
