// Scores every skin against SkinDeep's quality bar and prints a table:
// readability (a dark shadow layer or thick outline, text bright enough),
// what a normal hit shows, and how much a crit delivers.
//   node tools/audit.js [--json]
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
local function lum(c) return c and (0.3 * c[1] + 0.59 * c[2] + 0.11 * c[3]) or 1 end
local rows = {}
for _, id in ipairs(ns.SkinOrder) do
  local s = ns.TierSkin(ns.Skins[id])
  local dark = false
  for _, L in ipairs(s.layers or {}) do
    if lum(L.color) < 0.3 and (L.color[4] or 1) >= 0.6 and (math.abs(L.x or 0) + math.abs(L.y or 0)) >= 1.5 then dark = true end
  end
  local p, p2 = s.particles or {}, s.particles2 or {}
  rows[#rows + 1] = table.concat({
    id, s.name, s.group or "style",
    tostring(s.size or 24), s.outline or "", tostring(dark),
    string.format("%.2f", lum(s.physColor or s.color)), string.format("%.2f", lum(s.spellColor or s.color)),
    tostring(s.decor ~= nil), tostring(p.count or 0),
    tostring(s.critDecor ~= nil), tostring(s.critDecor2 ~= nil), tostring(s.ring ~= nil), tostring(s.critTitle ~= nil),
    tostring(p.critCount or p.count or 0), tostring(p2.critCount or 0), tostring(s.shake or 0), tostring(s.drum ~= nil),
    tostring(s.critCycle ~= nil), tostring(s.critScale or 1.5), tostring(s.dur or 1.1), tostring(s.critDur or s.dur or 1.1),
    tostring(s.ownText == true), tostring(#(s.critPieces or {})),
  }, "\\t")
end
AUDIT = table.concat(rows, "\\n")
`;
const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);
lauxlib.luaL_dostring(L, to_luastring('unpack = table.unpack'));
if (lauxlib.luaL_loadbuffer(L, to_luastring(harness.slice(0, cut) + dump), null, to_luastring('=audit')) !== lua.LUA_OK) {
  console.error(lua.lua_tojsstring(L, -1)); process.exit(1);
}
lua.lua_pushstring(L, to_luastring(root));
const log = console.log; console.log = () => {};
const ok = lua.lua_pcall(L, 1, 0, 0) === lua.LUA_OK;
console.log = log;
if (!ok) { console.error(lua.lua_tojsstring(L, -1)); process.exit(1); }
lua.lua_getglobal(L, to_luastring('AUDIT'));
const rows = lua.lua_tojsstring(L, -1).split('\n').map(line => {
  const c = line.split('\t');
  const b = v => v === 'true';
  const r = {
    id: c[0], name: c[1], group: c[2], size: +c[3], outline: c[4], darkLayer: b(c[5]),
    physLum: +c[6], spellLum: +c[7], decor: b(c[8]), hitParts: +c[9],
    critDecor: b(c[10]), critDecor2: b(c[11]), ring: b(c[12]), title: b(c[13]),
    critParts: +c[14], critParts2: +c[15], shake: +c[16], drum: b(c[17]), cycle: b(c[18]),
    critScale: +c[19], dur: +c[20], critDur: +c[21], ownText: b(c[22]), pieces: +c[23],
  };
  // Crit: layered effects (each choreographed piece counts). Hit: something of its own.
  r.crit = (r.critDecor ? 2 : 0) + (r.critDecor2 ? 2 : 0) + (r.ring ? 1 : 0) + (r.title ? 2 : 0)
    + Math.min(2, r.critParts / 6) + (r.critParts2 > 0 ? 1 : 0) + (r.shake > 0 ? 0.5 : 0) + (r.drum ? 0.5 : 0) + (r.cycle ? 1 : 0)
    + Math.min(4, r.pieces * 1.5);   // choreographed pieces (critPieces)
  r.hit = (r.decor ? 1 : 0) + (r.hitParts > 0 ? 1 : 0);
  r.readable = r.darkLayer || r.outline === 'THICKOUTLINE';
  r.flags = [];
  // (The engine gives a skin without its own a soft drop shadow.)
  if (Math.min(r.physLum, r.spellLum) < 0.35) r.flags.push('dark text');
  if (r.crit < 4 && !r.ownText) r.flags.push('thin crit');
  if (r.critScale < 1.45) r.flags.push('small crit');
  return r;
});
if (process.argv.includes('--json')) { console.log(JSON.stringify(rows, null, 1)); process.exit(0); }
rows.sort((a, b) => a.crit - b.crit);
console.log('crit  hit  id               group    flags');
for (const r of rows) {
  console.log(`${r.crit.toFixed(1).padStart(4)}  ${String(r.hit).padStart(3)}  ${r.id.padEnd(16)} ${r.group.padEnd(8)} ${r.flags.join(', ')}`);
}
const byGroup = {};
for (const r of rows) { (byGroup[r.group] = byGroup[r.group] || []).push(r.crit); }
console.log('\naverage crit score by group:');
for (const [g, v] of Object.entries(byGroup)) console.log(`  ${g.padEnd(8)} ${(v.reduce((a, b) => a + b, 0) / v.length).toFixed(1)}  (${v.length} skins)`);
console.log(`\nflagged: ${rows.filter(r => r.flags.length).length} of ${rows.length}`);
