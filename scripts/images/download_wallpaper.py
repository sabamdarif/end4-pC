#!/usr/bin/env python3
import os
import signal
import ssl
import sys
import urllib.request


def main():
    if len(sys.argv) < 3:
        sys.stderr.write("Usage: download_wallpaper.py <url> <dest_path>\n")
        sys.exit(1)

    url = sys.argv[1]
    dest = os.path.abspath(sys.argv[2])
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    tmp_path = f"{dest}.downloading.{os.getpid()}"

    def cleanup(*_):
        if os.path.exists(tmp_path):
            try:
                os.remove(tmp_path)
            except OSError:
                pass
        sys.exit(1)

    signal.signal(signal.SIGTERM, cleanup)
    signal.signal(signal.SIGINT, cleanup)

    headers = {
        "User-Agent": "Mozilla/5.0 (X11; Linux x86_64; rv:130.0) Gecko/20100101 Firefox/130.0",
        "Accept": "image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8",
    }

    req = urllib.request.Request(url, headers=headers)
    ctx = ssl.create_default_context()

    try:
        with urllib.request.urlopen(req, context=ctx, timeout=30) as resp, open(tmp_path, "wb") as f:
            total = int(resp.headers.get("Content-Length", 0))
            downloaded = 0
            last_reported = -1.0

            while True:
                chunk = resp.read(65536)
                if not chunk:
                    break
                f.write(chunk)
                downloaded += len(chunk)

                if total > 0:
                    pct = round((downloaded / total) * 100, 1)
                else:
                    pct = round(95.0 * (1.0 - (0.5 ** (downloaded / 1000000.0))), 1)

                if pct - last_reported >= 1.0 or pct >= 100.0:
                    print(f"{pct}", flush=True)
                    last_reported = pct

        if last_reported < 100.0:
            print("100.0", flush=True)

        os.replace(tmp_path, dest)
        return 0
    except Exception as e:
        if os.path.exists(tmp_path):
            try:
                os.remove(tmp_path)
            except OSError:
                pass
        sys.stderr.write(f"Download failed: {e}\n")
        sys.stderr.flush()
        return 1


if __name__ == "__main__":
    sys.exit(main())
