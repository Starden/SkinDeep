// Renders every skin's hit and crit from the real addon code into an HTML
// gallery (tools/gallery/index.html): the test harness's mock client runs
// the engine and tools/capture.lua records each frame.
//   node tools/gallery.js [skinId ...]
const fs = require('fs');
const path = require('path');
const { lua, lauxlib, lualib, to_luastring } = require('fengari');

const root = path.join(__dirname, '..');
const harness = fs.readFileSync(path.join(root, 'tests', 'harness.lua'), 'utf8');
const cut = harness.indexOf('print("== login")');
if (cut < 0) throw new Error('harness login marker not found');
const only = process.argv.slice(2);
const prelude = only.length ? `rawset(_G, "CAPTURE_ONLY", { ${only.map(id => `["${id}"] = true`).join(', ')} })\n` : '';
const capture = fs.readFileSync(path.join(__dirname, 'capture.lua'), 'utf8')
  .replace('local only = CAPTURE_ONLY', 'local only = rawget(_G, "CAPTURE_ONLY")');
const source = harness.slice(0, cut) + '\n' + capture;

const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);
lauxlib.luaL_dostring(L, to_luastring('unpack = table.unpack\n' + prelude));
if (lauxlib.luaL_loadbuffer(L, to_luastring(source), null, to_luastring('=capture')) !== lua.LUA_OK) {
  console.error(lua.lua_tojsstring(L, -1)); process.exit(1);
}
lua.lua_pushstring(L, to_luastring(root));
const origLog = console.log;
console.log = () => {};   // the harness prints chat lines
if (lua.lua_pcall(L, 1, 0, 0) !== lua.LUA_OK) {
  console.log = origLog;
  console.error('LUA ERROR: ' + lua.lua_tojsstring(L, -1)); process.exit(1);
}
console.log = origLog;
lua.lua_getglobal(L, to_luastring('CAPTURE_JSON'));
const data = JSON.parse(lua.lua_tojsstring(L, -1));

// Textures: TGA (uncompressed 32-bit, bottom-up) to base64 RGBA, top-down.
// The game's faction crests aren't on disk: the skins' own fallbacks stand in.
const STAND_IN = { 'alliance-logo': 'Media\\Textures\\shield.tga', 'horde-logo': 'Media\\Textures\\spikes.tga' };
const textures = data.textures.map(p => {
  const key = Object.keys(STAND_IN).find(k => p.toLowerCase().endsWith(k));
  const m = (key ? STAND_IN[key] : p).match(/Media\\Textures\\(.+)\.tga$/i);
  if (!m) return { path: p, missing: true };
  const buf = fs.readFileSync(path.join(root, 'Media', 'Textures', m[1] + '.tga'));
  const w = buf.readUInt16LE(12), h = buf.readUInt16LE(14);
  const out = Buffer.alloc(w * h * 4);
  for (let y = 0; y < h; y++) {
    const src = 18 + (h - 1 - y) * w * 4;
    buf.copy(out, y * w * 4, src, src + w * 4);
  }
  // TGA stores BGRA; the generator writes grey, so channel order doesn't matter.
  return { path: p, name: m[1], w, h, rgba: out.toString('base64') };
});
// Fonts: SkinDeep's own embed; the game's map to look-alikes.
const fonts = data.fonts.map(p => {
  const m = p.match(/Media\\Fonts\\(.+\.ttf)$/i);
  if (m) {
    const file = path.join(root, 'Media', 'Fonts', m[1]);
    return { path: p, family: 'sd-' + m[1].replace(/\W/g, ''), url: 'data:font/ttf;base64,' + fs.readFileSync(file).toString('base64') };
  }
  const game = { 'FRIZQT__': 'Georgia, serif', 'MORPHEUS': '"Palatino Linotype", "Book Antiqua", serif', 'SKURRI': 'Impact, sans-serif', 'ARIALN': '"Arial Narrow", Arial, sans-serif' };
  const key = Object.keys(game).find(k => p.toUpperCase().includes(k));
  return { path: p, family: key ? game[key] : 'Georgia, serif' };
});

const outDir = path.join(__dirname, 'gallery');
fs.mkdirSync(outDir, { recursive: true });
// One self-contained page (the data inline), so it opens anywhere.
const page = fs.readFileSync(path.join(__dirname, 'gallery.html'), 'utf8')
  .replace('<script src="data.js"></script>', () => '<script>window.GALLERY = ' + JSON.stringify({ skins: data.skins, textures, fonts }) + ';</script>');
fs.writeFileSync(path.join(outDir, 'index.html'), page);
// The showcase (CurseForge gallery images), with the logo inline.
const logo = 'data:image/png;base64,' + fs.readFileSync(path.join(root, 'docs', 'logo.png')).toString('base64');
const show = fs.readFileSync(path.join(__dirname, 'showcase.html'), 'utf8')
  .replace('<script src="data.js"></script>', () => '<script>window.GALLERY = ' + JSON.stringify({ skins: data.skins, textures, fonts, logo }) + ';</script>');
fs.writeFileSync(path.join(outDir, 'showcase.html'), show);
// Before/after: the snapshot in gallery/before.html (copy index.html there
// before changing skins) beside the current skins.
const beforeFile = path.join(outDir, 'before.html');
if (fs.existsSync(beforeFile)) {
  const old = fs.readFileSync(beforeFile, 'utf8');
  const m = old.match(/window\.GALLERY = ([\s\S]*?);<\/script>/);
  if (m) {
    const cmp = fs.readFileSync(path.join(__dirname, 'compare.html'), 'utf8')
      .replace('<script src="data.js"></script>', () => '<script>window.GALLERY = ' + JSON.stringify({ skins: data.skins, textures, fonts }) + '; window.BEFORE = ' + m[1] + ';</script>');
    fs.writeFileSync(path.join(outDir, 'compare.html'), cmp);
  }
}
console.log(`gallery: ${data.skins.length} skins -> ${path.join(outDir, 'index.html')}`);
