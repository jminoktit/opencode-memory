const http = require("http");
const fs = require("fs");
const path = require("path");
const { spawn, exec } = require("child_process");

const PORT = process.env.PORT || 8080;
const DIR = __dirname;

const MIME = {
  ".html": "text/html; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".css": "text/css",
  ".png": "image/png",
  ".ico": "image/x-icon",
  ".svg": "image/svg+xml",
};

const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);
  const pathname = url.pathname;

  if (pathname === "/api/continue" && req.method === "POST") {
    let body = "";
    req.on("data", (chunk) => body += chunk);
    req.on("end", () => {
      try {
        const { sessionId, title } = JSON.parse(body);
        if (!sessionId) {
          res.writeHead(400);
          return res.end(JSON.stringify({ error: "sessionId required" }));
        }
        const cmd = `start "" powershell -NoExit -Command "opencode -s '${sessionId.replace(/'/g, "''")}'"`;
        exec(cmd, { shell: "cmd.exe" }, (err) => {
          if (err) {
            res.writeHead(500);
            return res.end(JSON.stringify({ error: err.message }));
          }
          res.writeHead(200, { "Content-Type": "application/json" });
          res.end(JSON.stringify({ ok: true, sessionId }));
        });
      } catch (e) {
        res.writeHead(400);
        res.end(JSON.stringify({ error: e.message }));
      }
    });
    return;
  }

  if (pathname === "/api/export" && req.method === "POST") {
    const ps = spawn("powershell", ["-NoProfile", "-Command", `& '${DIR}\\export.ps1'`]);
    let out = "";
    ps.stdout.on("data", (d) => out += d);
    ps.stderr.on("data", (d) => out += d);
    ps.on("close", (code) => {
      res.writeHead(code === 0 ? 200 : 500, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ ok: code === 0, output: out.trim() }));
    });
    return;
  }

  let filePath = path.join(DIR, pathname === "/" ? "index.html" : pathname);
  const ext = path.extname(filePath);

  if (!fs.existsSync(filePath)) {
    res.writeHead(404);
    return res.end("404");
  }

  const stat = fs.statSync(filePath);
  if (stat.isDirectory()) {
    filePath = path.join(filePath, "index.html");
    if (!fs.existsSync(filePath)) {
      res.writeHead(404);
      return res.end("404");
    }
  }

  const content = fs.readFileSync(filePath);
  res.writeHead(200, { "Content-Type": MIME[ext] || "application/octet-stream" });
  res.end(content);
});

server.listen(PORT, "127.0.0.1", () => {
  console.log(`🚀 Server: http://localhost:${PORT}`);
});
