// Serves tools/gallery on http://localhost:5177 for the skin gallery.
const http = require('http');
const fs = require('fs');
const path = require('path');
const dir = path.join(__dirname, 'gallery');
http.createServer((req, res) => {
  const file = path.join(dir, decodeURIComponent(req.url.split('?')[0]).replace(/^\/+/, '') || 'index.html');
  if (!file.startsWith(dir)) { res.writeHead(403); return res.end(); }
  fs.readFile(file, (err, buf) => {
    if (err) { res.writeHead(404); return res.end('not found'); }
    res.writeHead(200, { 'Content-Type': file.endsWith('.html') ? 'text/html; charset=utf-8' : 'application/octet-stream', 'Cache-Control': 'no-store' });
    res.end(buf);
  });
}).listen(5177, '127.0.0.1', () => console.log('gallery on http://localhost:5177'));
