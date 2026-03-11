#!/usr/bin/env node
// ACFS Session Manager
// Routes browser tabs to individual tmux sessions via ttyd instances
// GET /           → dashboard with all sessions
// GET /s/<name>   → ttyd terminal for that tmux session
// POST /api/sessions          → create a new session
// DELETE /api/sessions/<name> → kill a session
// GET /api/sessions           → list sessions as JSON

const http = require("http");
const { execSync, spawn } = require("child_process");
const path = require("path");

const PORT = parseInt(process.env.PORT || "7681");
const TTYD_USER = process.env.TTYD_USER || "admin";
const TTYD_PASS = process.env.TTYD_PASS || "changeme";
const ACFS_USER = process.env.ACFS_USER || "dev";
const ACFS_HOSTNAME = process.env.ACFS_HOSTNAME || "acfs";
const BASE_TTYD_PORT = 17681; // internal ports for ttyd instances

// Track running ttyd instances: { sessionName: { port, process, pid } }
const instances = new Map();
let nextPort = BASE_TTYD_PORT;

function getTmuxSessions() {
  try {
    const output = execSync(
      `su - ${ACFS_USER} -c "tmux list-sessions -F '#S|#{session_windows}|#{session_attached}|#{session_created}'" 2>/dev/null`,
      { encoding: "utf8" }
    );
    return output
      .trim()
      .split("\n")
      .filter(Boolean)
      .map((line) => {
        const [name, windows, attached, created] = line.split("|");
        return {
          name,
          windows: parseInt(windows) || 0,
          attached: parseInt(attached) || 0,
          created: parseInt(created) || 0,
          hasTerminal: instances.has(name),
          url: `/s/${name}/`,
        };
      });
  } catch {
    return [];
  }
}

function ensureTmuxSession(name) {
  try {
    execSync(
      `su - ${ACFS_USER} -c "tmux has-session -t '${name}'" 2>/dev/null`
    );
    return true;
  } catch {
    try {
      execSync(
        `su - ${ACFS_USER} -c "tmux new-session -d -s '${name}' -c /data/projects" 2>/dev/null`
      );
      return true;
    } catch {
      return false;
    }
  }
}

function startTtydForSession(sessionName) {
  if (instances.has(sessionName)) return instances.get(sessionName).port;

  const port = nextPort++;
  const proc = spawn(
    "ttyd",
    [
      "-W",
      "-p",
      String(port),
      "-c",
      `${TTYD_USER}:${TTYD_PASS}`,
      "-t",
      `titleFixed=${sessionName} — ${ACFS_HOSTNAME}`,
      "-b",
      `/s/${sessionName}`,
      "su",
      "-",
      ACFS_USER,
      "-c",
      `tmux attach-session -t '${sessionName}' || tmux new-session -s '${sessionName}' -c /data/projects`,
    ],
    { stdio: "ignore", detached: true }
  );

  proc.unref();
  instances.set(sessionName, { port, process: proc, pid: proc.pid });

  proc.on("exit", () => {
    instances.delete(sessionName);
  });

  return port;
}

function killSession(name) {
  const inst = instances.get(name);
  if (inst) {
    try {
      process.kill(inst.pid);
    } catch {}
    instances.delete(name);
  }
  try {
    execSync(
      `su - ${ACFS_USER} -c "tmux kill-session -t '${name}'" 2>/dev/null`
    );
  } catch {}
}

// Simple HTTP proxy to ttyd
function proxyRequest(req, res, targetPort) {
  const options = {
    hostname: "127.0.0.1",
    port: targetPort,
    path: req.url,
    method: req.method,
    headers: { ...req.headers, host: `127.0.0.1:${targetPort}` },
  };

  const proxy = http.request(options, (proxyRes) => {
    // Handle WebSocket upgrade separately
    res.writeHead(proxyRes.statusCode, proxyRes.headers);
    proxyRes.pipe(res);
  });

  proxy.on("error", (err) => {
    res.writeHead(502);
    res.end(`Proxy error: ${err.message}`);
  });

  req.pipe(proxy);
}

function dashboardHTML(sessions) {
  const sessionRows = sessions
    .map(
      (s) => `
    <div class="session" onclick="window.open('${s.url}', '_blank')">
      <div class="session-header">
        <span class="session-name">${s.name}</span>
        <span class="session-status ${s.attached ? "attached" : "detached"}">${s.attached ? "attached" : "detached"}</span>
      </div>
      <div class="session-meta">
        ${s.windows} window${s.windows !== 1 ? "s" : ""} · created ${new Date(s.created * 1000).toLocaleTimeString()}
      </div>
      <div class="session-actions">
        <a href="${s.url}" target="_blank" class="btn btn-open">Open Terminal</a>
        <button onclick="event.stopPropagation(); deleteSession('${s.name}')" class="btn btn-kill">Kill</button>
      </div>
    </div>`
    )
    .join("\n");

  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>${ACFS_HOSTNAME} — ACFS Session Dashboard</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, monospace;
    background: #0d1117;
    color: #c9d1d9;
    min-height: 100vh;
    padding: 2rem;
  }
  h1 { color: #58a6ff; margin-bottom: 0.5rem; font-size: 1.5rem; }
  .subtitle { color: #8b949e; margin-bottom: 2rem; font-size: 0.9rem; }
  .toolbar { display: flex; gap: 1rem; margin-bottom: 2rem; align-items: center; }
  .toolbar input {
    background: #161b22; border: 1px solid #30363d; color: #c9d1d9;
    padding: 0.5rem 1rem; border-radius: 6px; font-size: 0.9rem; width: 250px;
  }
  .toolbar input::placeholder { color: #484f58; }
  .btn {
    padding: 0.5rem 1rem; border-radius: 6px; font-size: 0.85rem;
    cursor: pointer; border: 1px solid #30363d; text-decoration: none;
    display: inline-block; transition: all 0.15s;
  }
  .btn-create { background: #238636; color: #fff; border-color: #238636; }
  .btn-create:hover { background: #2ea043; }
  .btn-open { background: #1f6feb; color: #fff; border-color: #1f6feb; }
  .btn-open:hover { background: #388bfd; }
  .btn-kill { background: transparent; color: #f85149; border-color: #f85149; }
  .btn-kill:hover { background: #f8514922; }
  .btn-refresh { background: #21262d; color: #c9d1d9; }
  .btn-refresh:hover { background: #30363d; }
  .sessions { display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 1rem; }
  .session {
    background: #161b22; border: 1px solid #30363d; border-radius: 8px;
    padding: 1.25rem; cursor: pointer; transition: all 0.15s;
  }
  .session:hover { border-color: #58a6ff; transform: translateY(-1px); }
  .session-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.5rem; }
  .session-name { font-weight: 600; font-size: 1.1rem; color: #f0f6fc; }
  .session-status {
    font-size: 0.75rem; padding: 2px 8px; border-radius: 12px; font-weight: 500;
  }
  .attached { background: #23863633; color: #3fb950; }
  .detached { background: #f8514922; color: #f85149; }
  .session-meta { color: #8b949e; font-size: 0.85rem; margin-bottom: 1rem; }
  .session-actions { display: flex; gap: 0.5rem; }
  .empty {
    text-align: center; padding: 4rem 2rem; color: #484f58;
    border: 2px dashed #30363d; border-radius: 8px;
  }
  .empty p { margin-bottom: 1rem; }
</style>
</head>
<body>
  <h1>🚀 ${ACFS_HOSTNAME}</h1>
  <p class="subtitle">ACFS Multi-Agent Session Dashboard · ${sessions.length} session${sessions.length !== 1 ? "s" : ""} active</p>

  <div class="toolbar">
    <input type="text" id="newSession" placeholder="New session name..." onkeydown="if(event.key==='Enter')createSession()">
    <button class="btn btn-create" onclick="createSession()">+ New Session</button>
    <button class="btn btn-refresh" onclick="location.reload()">↻ Refresh</button>
  </div>

  <div class="sessions">
    ${sessions.length === 0 ? '<div class="empty"><p>No sessions running</p><p>Create one to get started</p></div>' : sessionRows}
  </div>

  <script>
    async function createSession() {
      const name = document.getElementById('newSession').value.trim();
      if (!name) return alert('Enter a session name');
      const res = await fetch('/api/sessions', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({ name })
      });
      if (res.ok) {
        const data = await res.json();
        window.open(data.url, '_blank');
        location.reload();
      } else {
        alert('Failed to create session');
      }
    }
    async function deleteSession(name) {
      if (!confirm('Kill session "' + name + '"?')) return;
      await fetch('/api/sessions/' + name, { method: 'DELETE' });
      location.reload();
    }
    // Auto-refresh every 10s
    setTimeout(() => location.reload(), 10000);
  </script>
</body>
</html>`;
}

// Main HTTP server
const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);

  // Dashboard
  if (url.pathname === "/" || url.pathname === "") {
    const sessions = getTmuxSessions();
    // Auto-start ttyd for any session that doesn't have one
    for (const s of sessions) {
      if (!instances.has(s.name)) {
        startTtydForSession(s.name);
      }
    }
    res.writeHead(200, { "Content-Type": "text/html" });
    res.end(dashboardHTML(sessions));
    return;
  }

  // API: list sessions
  if (url.pathname === "/api/sessions" && req.method === "GET") {
    const sessions = getTmuxSessions();
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify(sessions));
    return;
  }

  // API: create session
  if (url.pathname === "/api/sessions" && req.method === "POST") {
    let body = "";
    req.on("data", (chunk) => (body += chunk));
    req.on("end", () => {
      try {
        const { name } = JSON.parse(body);
        if (!name || !/^[a-zA-Z0-9_-]+$/.test(name)) {
          res.writeHead(400, { "Content-Type": "application/json" });
          res.end(JSON.stringify({ error: "Invalid session name" }));
          return;
        }
        ensureTmuxSession(name);
        const port = startTtydForSession(name);
        // Give ttyd a moment to start
        setTimeout(() => {
          res.writeHead(201, { "Content-Type": "application/json" });
          res.end(JSON.stringify({ name, url: `/s/${name}/`, port }));
        }, 500);
      } catch {
        res.writeHead(400, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ error: "Invalid request" }));
      }
    });
    return;
  }

  // API: delete session
  const deleteMatch = url.pathname.match(/^\/api\/sessions\/([a-zA-Z0-9_-]+)$/);
  if (deleteMatch && req.method === "DELETE") {
    killSession(deleteMatch[1]);
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ ok: true }));
    return;
  }

  // Proxy to ttyd session
  const sessionMatch = url.pathname.match(/^\/s\/([a-zA-Z0-9_-]+)(\/.*)?$/);
  if (sessionMatch) {
    const sessionName = sessionMatch[1];
    ensureTmuxSession(sessionName);
    const port = startTtydForSession(sessionName);

    // Rewrite URL for ttyd (it expects its base path)
    proxyRequest(req, res, port);
    return;
  }

  // 404
  res.writeHead(404);
  res.end("Not found");
});

// Handle WebSocket upgrades (critical for ttyd)
server.on("upgrade", (req, socket, head) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);
  const sessionMatch = url.pathname.match(/^\/s\/([a-zA-Z0-9_-]+)(\/.*)?$/);

  if (!sessionMatch) {
    socket.destroy();
    return;
  }

  const sessionName = sessionMatch[1];
  if (!instances.has(sessionName)) {
    socket.destroy();
    return;
  }

  const { port } = instances.get(sessionName);
  const options = {
    hostname: "127.0.0.1",
    port,
    path: req.url,
    method: "GET",
    headers: { ...req.headers, host: `127.0.0.1:${port}` },
  };

  const proxy = http.request(options);
  proxy.on("upgrade", (proxyRes, proxySocket, proxyHead) => {
    socket.write(
      `HTTP/1.1 101 Switching Protocols\r\n` +
        Object.entries(proxyRes.headers)
          .map(([k, v]) => `${k}: ${v}`)
          .join("\r\n") +
        "\r\n\r\n"
    );
    proxySocket.pipe(socket);
    socket.pipe(proxySocket);
  });
  proxy.on("error", () => socket.destroy());
  proxy.end();
});

// Startup: create default "main" session
ensureTmuxSession("main");
startTtydForSession("main");

server.listen(PORT, () => {
  console.log(`ACFS Session Manager running on port ${PORT}`);
  console.log(`Dashboard: http://localhost:${PORT}/`);
  console.log(`Main terminal: http://localhost:${PORT}/s/main/`);
});
