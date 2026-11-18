// Runs harness.lua in fengari (Lua 5.3 VM; the addon code is 5.1-compatible).
const path = require('path');
const { lua, lauxlib, lualib, to_luastring } = require('fengari');
const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);
// 5.1 shims the WoW client provides.
lauxlib.luaL_dostring(L, to_luastring('unpack = table.unpack'));
const harness = path.join(__dirname, 'harness.lua');
if (lauxlib.luaL_loadfile(L, to_luastring(harness)) !== lua.LUA_OK) {
  console.error(lua.lua_tojsstring(L, -1)); process.exit(1);
}
lua.lua_pushstring(L, to_luastring(process.argv[2] || path.join(__dirname, '..')));
if (lua.lua_pcall(L, 1, 0, 0) !== lua.LUA_OK) {
  console.error('LUA ERROR: ' + lua.lua_tojsstring(L, -1)); process.exit(1);
}
