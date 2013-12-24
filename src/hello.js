var http = require('http');
http.createServer(function (req, res) {
  res.writeHead(200, {'Content-Type': 'text/plain'});
  res.end('Hello Node.js! I am on your Vagrant VM!\n');
}).listen(8124, "0.0.0.0");
console.log('A server is running at http://127.0.0.1:8124/ on the guest, or http://localhost:8280 on the host (your workstation)');
