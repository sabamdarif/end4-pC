#!/usr/bin/env python3
import http.server
import json
import os
import socketserver
import sys
import webbrowser

PORT = 8089
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
JSON_PATH = os.path.join(BASE_DIR, "assets", "material_symbols_rounded.json")
HTML_PATH = os.path.join(BASE_DIR, "scripts", "material_icons.html")

HTML_TEMPLATE = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Material Symbols Search</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Rounded:opsz,wght,FILL,GRAD@24,400,0,0">
<style>
  :root {
    --bg: #121316;
    --card: #1e1f24;
    --card-hover: #2b2c34;
    --primary: #a8c7fa;
    --on-primary: #062e6f;
    --text: #e3e2e6;
    --subtext: #8e9099;
    --border: #44474f;
    --active: #384252;
  }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    background: var(--bg);
    color: var(--text);
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    padding: 24px;
    display: flex;
    flex-direction: column;
    align-items: center;
  }
  .header {
    width: 100%;
    max-width: 1100px;
    margin-bottom: 24px;
    display: flex;
    flex-direction: column;
    gap: 12px;
  }
  .title-row {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  h1 { font-size: 24px; font-weight: 600; color: var(--primary); }
  .stats { font-size: 14px; color: var(--subtext); }
  .search-box {
    width: 100%;
    padding: 14px 18px;
    font-size: 16px;
    border-radius: 28px;
    border: 1px solid var(--border);
    background: var(--card);
    color: var(--text);
    outline: none;
    transition: border-color 0.2s, box-shadow 0.2s;
  }
  .search-box:focus {
    border-color: var(--primary);
    box-shadow: 0 0 0 2px rgba(168, 199, 250, 0.25);
  }
  .grid {
    width: 100%;
    max-width: 1100px;
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(130px, 1fr));
    gap: 12px;
  }
  .card {
    background: var(--card);
    border-radius: 16px;
    padding: 16px 8px;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 10px;
    cursor: pointer;
    transition: background 0.15s, transform 0.1s;
    user-select: none;
    border: 1px solid transparent;
  }
  .card:hover {
    background: var(--card-hover);
    transform: translateY(-2px);
  }
  .card:active {
    transform: translateY(0);
    border-color: var(--primary);
  }
  .card.copied {
    border-color: #6dd58c;
    background: #1b3824;
  }
  .icon {
    font-family: 'Material Symbols Rounded';
    font-size: 36px;
    color: var(--primary);
    line-height: 1;
  }
  .name {
    font-size: 12px;
    color: var(--text);
    text-align: center;
    word-break: break-all;
    max-width: 100%;
  }
  .toast {
    position: fixed;
    bottom: 24px;
    left: 50%;
    transform: translateX(-50%);
    background: var(--primary);
    color: var(--on-primary);
    font-weight: 500;
    padding: 10px 20px;
    border-radius: 20px;
    box-shadow: 0 4px 12px rgba(0,0,0,0.4);
    opacity: 0;
    transition: opacity 0.2s;
    pointer-events: none;
  }
  .toast.show { opacity: 1; }
</style>
</head>
<body>
<div class="header">
  <div class="title-row">
    <h1>Material Symbols Search</h1>
    <div class="stats" id="stats">Loading...</div>
  </div>
  <input type="text" class="search-box" id="search" placeholder="Type to search icons (e.g. search, settings, arrow, user)..." autofocus autocomplete="off">
</div>
<div class="grid" id="grid"></div>
<div class="toast" id="toast">Copied to clipboard!</div>

<script>
  let allIcons = [];
  const searchInput = document.getElementById('search');
  const grid = document.getElementById('grid');
  const stats = document.getElementById('stats');
  const toast = document.getElementById('toast');
  let toastTimer = null;

  function showToast(text) {
    toast.textContent = text;
    toast.classList.add('show');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => toast.classList.remove('show'), 1500);
  }

  function render(list) {
    grid.innerHTML = '';
    const slice = list.slice(0, 150);
    slice.forEach(item => {
      const el = document.createElement('div');
      el.className = 'card';
      el.innerHTML = `<span class="icon">${item.name}</span><span class="name">${item.name}</span>`;
      el.onclick = () => {
        navigator.clipboard.writeText(item.name);
        el.classList.add('copied');
        showToast('Copied: "' + item.name + '"');
        setTimeout(() => el.classList.remove('copied'), 600);
      };
      grid.appendChild(el);
    });
    stats.textContent = `Showing ${slice.length} of ${list.length} icons`;
  }

  function filter() {
    const q = searchInput.value.toLowerCase().trim();
    if (!q) {
      render(allIcons);
      return;
    }
    const matched = allIcons.filter(item => {
      if (item.name.toLowerCase().includes(q)) return true;
      return item.tags && item.tags.some(t => t.toLowerCase().includes(q));
    });
    render(matched);
  }

  fetch('/data')
    .then(r => r.json())
    .then(data => {
      allIcons = data;
      render(allIcons);
      searchInput.oninput = filter;
    })
    .catch(e => {
      stats.textContent = 'Failed to load icon data.';
    });
</script>
</body>
</html>
"""

class IconHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/" or self.path == "/index.html":
            self.send_response(200)
            self.send_header("Content-type", "text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(HTML_TEMPLATE.encode("utf-8"))
        elif self.path == "/data":
            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            with open(JSON_PATH, "rb") as f:
                self.wfile.write(f.read())
        else:
            self.send_error(404)

    def log_message(self, format, *args):
        pass

def main():
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("127.0.0.1", PORT), IconHandler) as httpd:
        url = f"http://127.0.0.1:{PORT}"
        print(f"Material Symbols Search running at {url}")
        print("Press Ctrl+C to stop.")
        try:
            webbrowser.open(url)
        except Exception:
            pass
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\\nServer stopped.")

if __name__ == "__main__":
    main()
