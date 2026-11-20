// Serves tools/gallery on http://localhost:5177 for the skin gallery.
const http = require('http');
const fs = require('fs');
const path = require('path');
const dir = path.join(__dirname, 'gallery');
http.createServer((req, res) => {
  // The showcase page saves its images here (docs/screenshots).
  if (req.method === 'POST' && req.url.startsWith('/save?')) {
    const name = new URLSearchParams(req.url.slice(6)).get('name') || '';
    if (!/^[a-z0-9-]+\.png$/.test(name)) { res.writeHead(400); return res.end(); }
    const chunks = [];
    req.on('data', c => chunks.push(c));
    req.on('end', () => {
      const b64 = Buffer.concat(chunks).toString().replace(/^data:image\/png;base64,/, '');
      const out = path.join(__dirname, '..', 'docs', 'screenshots');
      fs.mkdirSync(out, { recursive: true });
      fs.writeFileSync(path.join(out, name), Buffer.from(b64, 'base64'));
      res.writeHead(200); res.end('ok');
    });
    return;
  }
  const file = path.join(dir, decodeURIComponent(req.url.split('?')[0]).replace(/^\/+/, '') || 'index.html');
  if (!file.startsWith(dir)) { res.writeHead(403); return res.end(); }
  fs.readFile(file, (err, buf) => {
    if (err) { res.writeHead(404); return res.end('not found'); }
    res.writeHead(200, { 'Content-Type': file.endsWith('.html') ? 'text/html; charset=utf-8' : 'application/octet-stream', 'Cache-Control': 'no-store' });
    res.end(buf);
  });
}).listen(Number(process.env.PORT) || 5177, '127.0.0.1', function () { console.log('gallery on http://localhost:' + this.address().port); });
