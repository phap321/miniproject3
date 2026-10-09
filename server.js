const http = require('http');
const fs = require('fs');
const path = require('path');

let PORT = 3000;
const PUBLIC_DIR = path.join(__dirname, 'web_preview');

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css',
  '.js': 'text/javascript',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.json': 'application/json'
};

function startServer(port) {
  const server = http.createServer((req, res) => {
    let filePath = path.join(PUBLIC_DIR, req.url === '/' ? 'index.html' : req.url);
    const ext = path.extname(filePath);
    const contentType = MIME_TYPES[ext] || 'text/plain';

    fs.readFile(filePath, (err, content) => {
      if (err) {
        if (err.code === 'ENOENT') {
          res.writeHead(404, { 'Content-Type': 'text/html; charset=utf-8' });
          res.end('<h1>404 Not Found</h1>');
        } else {
          res.writeHead(500);
          res.end(`Server Error: ${err.code}`);
        }
      } else {
        res.writeHead(200, { 'Content-Type': contentType });
        res.end(content, 'utf-8');
      }
    });
  });

  server.on('error', (err) => {
    if (err.code === 'EADDRINUSE') {
      console.log(`⚠️ Cổng ${port} đang được sử dụng, tự động chuyển sang cổng ${port + 1}...`);
      startServer(port + 1);
    } else {
      console.error('Lỗi server:', err);
    }
  });

  server.listen(port, () => {
    console.log(`====================================================`);
    console.log(`📱 Smart Receipt Scanner Web App đang chạy!`);
    console.log(`👉 Mở trình duyệt xem ngay: http://localhost:${port}`);
    console.log(`====================================================`);
  });
}

startServer(PORT);
