// Usage: node tests/check.js [dir or .lua files]   (default: the addon root)
// Parses each Lua file (5.1 grammar) and lists the global names it touches,
// so typos and unintended globals stand out.
const fs = require('fs');
const luaparse = require('luaparse');
let failed = false;
const path = require("path");
const args = process.argv.slice(2);
if (args.length === 0) args.push(path.join(__dirname, ".."));
const files = args.flatMap(a => fs.statSync(a).isDirectory()
  ? fs.readdirSync(a).filter(n => n.endsWith(".lua")).map(n => path.join(a, n)) : [a]);
for (const file of files) {
  const src = fs.readFileSync(file, 'utf8');
  const globalsRead = new Set(), globalsWritten = new Set();
  try {
    const ast = luaparse.parse(src, { luaVersion: '5.1', scope: true, locations: true });
    const walk = (node, assignTarget) => {
      if (!node || typeof node !== 'object') return;
      if (Array.isArray(node)) { node.forEach(n => walk(n, assignTarget)); return; }
      if (node.type === 'Identifier' && node.isLocal === false) {
        (assignTarget ? globalsWritten : globalsRead).add(node.name);
      }
      if (node.type === 'AssignmentStatement') {
        node.variables.forEach(v => walk(v, v.type === 'Identifier'));
        walk(node.init, false);
        return;
      }
      if (node.type === 'FunctionDeclaration' && node.identifier && node.identifier.type === 'Identifier' && !node.isLocal) {
        globalsWritten.add(node.identifier.name);
      }
      for (const k of Object.keys(node)) if (k !== 'loc' && k !== 'range') walk(node[k], false);
    };
    walk(ast.body, false);
    console.log(`OK   ${file}`);
    console.log(`     writes: ${[...globalsWritten].sort().join(', ') || '-'}`);
    console.log(`     reads:  ${[...globalsRead].sort().join(', ')}`);
  } catch (e) {
    failed = true;
    console.log(`FAIL ${file}: ${e.message}`);
  }
}
process.exit(failed ? 1 : 0);
