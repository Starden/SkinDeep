// Finds skins that look too much alike: compares what each skin is built
// from (motion, font, the textures in every slot, crit extras), ignoring
// color, since two skins that differ only in color are what this hunts for.
//   node tools/similarity.js [--top N] [--json]
const fs = require('fs');
const path = require('path');
const { lua, lauxlib, lualib, to_luastring } = require('fengari');

const root = path.join(__dirname, '..');
const harness = fs.readFileSync(path.join(root, 'tests', 'harness.lua'), 'utf8');
const cut = harness.indexOf('print("== login")');
const dump = `
SkinDeepDB = { unlockMode = "all" }
fire("ADDON_LOADED", "SkinDeep")
fire("PLAYER_LOGIN")
local function tex(d) if not d then return "" end return d.file or d.tex or "glow" end
local function pieceTex(list)
  local out = {}
  for _, d in ipairs(list or {}) do out[#out + 1] = tex(d) end
  return table.concat(out, ",")
end
local rows = {}
for _, id in ipairs(ns.SkinOrder) do
  local s = ns.TierSkin(ns.Skins[id])
  local p, p2 = s.particles or {}, s.particles2 or {}
  local c = s.physColor or s.color or { 1, 1, 1 }
  local k = s.critColor or s.spellColor or c
  local args = {}
  for key, v in pairs(s.motionArgs or {}) do
    if type(v) == "number" then args[#args + 1] = key .. "=" .. v end
  end
  table.sort(args)
  rows[#rows + 1] = table.concat({
    id, s.name, s.group or "style", s.base or "",
    s.motion or "rise", table.concat(args, ","), s.font or "", s.outline or "",
    tex(s.decor), tex(s.critDecor), tex(s.critDecor2),
    (p.count or 0) + (p.critCount or 0) > 0 and tex(p) or "",
    (p2.count or 0) + (p2.critCount or 0) > 0 and tex(p2) or "",
    tostring(s.ring ~= nil), tostring(s.critTitle ~= nil), tostring(s.echo ~= nil), tostring(s.drum ~= nil),
    tostring(#(s.layers or {})), tostring(s.critCycle ~= nil), tostring((s.shake or 0) > 0),
    string.format("%.2f,%.2f,%.2f", c[1], c[2], c[3]), string.format("%.2f,%.2f,%.2f", k[1], k[2], k[3]),
    tostring(s.size or 24), tostring(s.ownText == true), pieceTex(s.critPieces),
  }, "\\t")
end
DUMP = table.concat(rows, "\\n")
`;
const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);
lauxlib.luaL_dostring(L, to_luastring('unpack = table.unpack'));
if (lauxlib.luaL_loadbuffer(L, to_luastring(harness.slice(0, cut) + dump), null, to_luastring('=similarity')) !== lua.LUA_OK) {
  console.error(lua.lua_tojsstring(L, -1)); process.exit(1);
}
lua.lua_pushstring(L, to_luastring(root));
const log = console.log; console.log = () => {};
const ok = lua.lua_pcall(L, 1, 0, 0) === lua.LUA_OK;
console.log = log;
if (!ok) { console.error(lua.lua_tojsstring(L, -1)); process.exit(1); }
lua.lua_getglobal(L, to_luastring('DUMP'));

const short = t => t.replace(/^.*[\\/]/, '').replace(/\.tga$/i, '').toLowerCase();
const skins = lua.lua_tojsstring(L, -1).split('\n').map(line => {
  const c = line.split('\t');
  const s = {
    id: c[0], name: c[1], group: c[2], base: c[3], motion: c[4], args: c[5], font: short(c[6]), outline: c[7],
    decor: short(c[8]), critDecor: short(c[9]), critDecor2: short(c[10]), parts: short(c[11]), parts2: short(c[12]),
    ring: c[13] === 'true', title: c[14] === 'true', echo: c[15] === 'true', drum: c[16] === 'true',
    layers: +c[17], cycle: c[18] === 'true', shake: c[19] === 'true',
    color: c[20].split(',').map(Number), critColor: c[21].split(',').map(Number), size: +c[22], ownText: c[23] === 'true',
    pieces: c[24] ? c[24].split(',').map(short) : [],
  };
  s.pieceSet = new Set(s.pieces);
  s.texSet = new Set([s.decor, s.critDecor, s.critDecor2, s.parts, s.parts2, ...s.pieces].filter(Boolean));
  return s;
});

// Similarity 0..1, color left out. Weights sum to 11.5.
function sim(a, b) {
  const why = [];
  let score = 0;
  const add = (w, cond, label) => { if (cond) { score += w; why.push(label); } };
  add(1.5, a.motion === b.motion, 'motion ' + a.motion + (a.args === b.args ? ' (same args)' : ''));
  if (a.motion === b.motion && a.args === b.args) score += 0.5;
  add(1, a.font === b.font, 'font');
  // Slot by slot: the same texture in the same role reads as the same effect.
  for (const slot of ['decor', 'critDecor', 'critDecor2', 'parts', 'parts2']) {
    add(1, a[slot] && a[slot] === b[slot], slot + ' ' + a[slot]);
    if (!a[slot] && !b[slot]) score += 0.5;   // both lack it: a little alike
  }
  const inter = [...a.texSet].filter(t => b.texSet.has(t)).length;
  const union = new Set([...a.texSet, ...b.texSet]).size || 1;
  score += 1.5 * inter / union;
  // Choreographed pieces (critPieces): the same set reads as the same crit.
  if (a.pieceSet.size || b.pieceSet.size) {
    const pi = [...a.pieceSet].filter(t => b.pieceSet.has(t)).length;
    const pu = new Set([...a.pieceSet, ...b.pieceSet]).size;
    if (pi) { score += 1.5 * pi / pu; why.push('pieces ' + [...a.pieceSet].filter(t => b.pieceSet.has(t)).join('+')); }
  } else score += 0.75;
  const extras = ['ring', 'title', 'echo', 'drum', 'cycle'];
  score += 0.5 * extras.filter(k => a[k] === b[k]).length / extras.length;
  return { score: Math.min(1, score / 11.5), why };
}
function hueDist(a, b) { return Math.hypot(a[0] - b[0], a[1] - b[1], a[2] - b[2]); }

const pairs = [];
for (let i = 0; i < skins.length; i++) for (let j = i + 1; j < skins.length; j++) {
  const a = skins[i], b = skins[j];
  if (a.ownText || b.ownText) continue;
  const r = sim(a, b);
  pairs.push({ a: a.id, b: b.id, an: a.name, bn: b.name, score: r.score, why: r.why,
               color: hueDist(a.color, b.color), related: a.base === b.id || b.base === a.id || (a.base && a.base === b.base) });
}
pairs.sort((p, q) => q.score - p.score);
const topArg = process.argv.indexOf('--top');
const top = topArg > 0 ? +process.argv[topArg + 1] : 40;
if (process.argv.includes('--json')) { console.log(JSON.stringify({ skins, pairs: pairs.slice(0, top) }, null, 1)); process.exit(0); }
console.log('score  color  pair                                   shared');
for (const p of pairs.slice(0, top)) {
  console.log(`${p.score.toFixed(2)}   ${p.color.toFixed(2)}  ${(p.a + ' / ' + p.b).padEnd(38)} ${p.why.join('; ')}`);
}
// Per skin, its nearest neighbour.
const nearest = {};
for (const p of pairs) {
  if (!nearest[p.a] || nearest[p.a].score < p.score) nearest[p.a] = { other: p.b, score: p.score };
  if (!nearest[p.b] || nearest[p.b].score < p.score) nearest[p.b] = { other: p.a, score: p.score };
}
const close = Object.entries(nearest).filter(([, n]) => n.score >= 0.7);
console.log(`\nskins with a neighbour at 0.70 or more: ${close.length} of ${skins.length}`);
