const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../build/web');
const types = {'.html':'text/html','.js':'application/javascript','.json':'application/json','.wasm':'application/wasm','.css':'text/css','.png':'image/png','.ttf':'font/ttf','.woff2':'font/woff2'};
http.createServer((req,res) => {
  let file;
  try { file=path.resolve(root,'.'+decodeURIComponent(new URL(req.url,'http://localhost').pathname)); } catch {res.writeHead(400);res.end();return;}
  if(file!==root && !file.startsWith(root+path.sep)) {res.writeHead(403);res.end();return;}
  if(!fs.existsSync(file) || fs.statSync(file).isDirectory()) file=path.join(root,'index.html');
  res.setHeader('Content-Type',types[path.extname(file)] || 'application/octet-stream');
  res.setHeader('Cache-Control','no-store');
  res.setHeader('X-Content-Type-Options','nosniff');
  res.setHeader('Referrer-Policy','strict-origin-when-cross-origin');
  fs.createReadStream(file).on('error',()=>{res.writeHead(404);res.end();}).pipe(res);
}).listen(3000,'127.0.0.1',()=>console.log('AnkiDSA demo: http://localhost:3000'));
