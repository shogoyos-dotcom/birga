#!/usr/bin/env python3
"""Color Land uchun onlayn reyting serveri.

Faqat standart kutubxona — o'rnatish shart emas:

    python3 server/leaderboard.py --port 8080 --db /var/lib/colorland.db

Keyin o'yin sozlamalariga shu manzilni yozing:
    http://<server-ip>:8080

API:
  POST /score
      {"name","country","city","continent","percent","kills"}
      Har o'yinchining eng yaxshi natijasi saqlanadi.
  GET  /top?scope=world|continent|country|city&key=<qiymat>&limit=50
      {"rows":[{"name","percent","kills","country","city"}]}

Eslatma: bu namuna server — hisob (akkaunt) yo'q, shuning uchun
natijani kim yuborganini tekshirmaydi. Haqiqiy chiqarishda oldiga
HTTPS proksi va oddiy autentifikatsiya qo'yish kerak.
"""
import argparse
import json
import sqlite3
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

SCHEMA = """
CREATE TABLE IF NOT EXISTS score (
    name      TEXT NOT NULL,
    country   TEXT NOT NULL DEFAULT '',
    city      TEXT NOT NULL DEFAULT '',
    continent TEXT NOT NULL DEFAULT '',
    percent   REAL NOT NULL,
    kills     INTEGER NOT NULL DEFAULT 0,
    at        INTEGER NOT NULL,
    PRIMARY KEY (name, country)
);
CREATE INDEX IF NOT EXISTS score_country ON score (country, percent DESC);
CREATE INDEX IF NOT EXISTS score_city ON score (city, percent DESC);
CREATE INDEX IF NOT EXISTS score_continent ON score (continent, percent DESC);
CREATE INDEX IF NOT EXISTS score_world ON score (percent DESC);
"""

MAX_NAME = 24
MAX_LIMIT = 100

lock = threading.Lock()


def connect(path):
    db = sqlite3.connect(path, check_same_thread=False)
    db.executescript(SCHEMA)
    db.commit()
    return db


def clean(value, limit=MAX_NAME):
    return str(value or '').strip()[:limit]


class Handler(BaseHTTPRequestHandler):
    db = None

    def _send(self, code, payload):
        body = json.dumps(payload, ensure_ascii=False).encode()
        self.send_response(code)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Content-Length', str(len(body)))
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        url = urlparse(self.path)
        if url.path != '/top':
            self._send(404, {'error': 'not found'})
            return
        query = parse_qs(url.query)
        scope = clean(query.get('scope', ['world'])[0], 16)
        key = clean(query.get('key', [''])[0], 64)
        try:
            limit = min(int(query.get('limit', ['50'])[0]), MAX_LIMIT)
        except ValueError:
            limit = 50

        column = {'city': 'city', 'country': 'country',
                  'continent': 'continent'}.get(scope)
        sql = ('SELECT name, percent, kills, country, city FROM score '
               '{where} ORDER BY percent DESC, kills DESC LIMIT ?')
        with lock:
            if column and key:
                rows = self.db.execute(
                    sql.format(where=f'WHERE {column} = ?'),
                    (key, limit)).fetchall()
            else:
                rows = self.db.execute(
                    sql.format(where=''), (limit,)).fetchall()
        self._send(200, {'rows': [
            {'name': r[0], 'percent': r[1], 'kills': r[2],
             'country': r[3], 'city': r[4]} for r in rows]})

    def do_POST(self):
        if urlparse(self.path).path != '/score':
            self._send(404, {'error': 'not found'})
            return
        try:
            size = int(self.headers.get('Content-Length', '0'))
            data = json.loads(self.rfile.read(size) or b'{}')
        except (ValueError, TypeError):
            self._send(400, {'error': 'bad json'})
            return

        name = clean(data.get('name'))
        if not name:
            self._send(400, {'error': 'name required'})
            return
        try:
            percent = max(0.0, min(100.0, float(data.get('percent', 0))))
            kills = max(0, min(999, int(data.get('kills', 0))))
        except (ValueError, TypeError):
            self._send(400, {'error': 'bad score'})
            return

        row = (name, clean(data.get('country'), 2).upper(),
               clean(data.get('city'), 40), clean(data.get('continent'), 24),
               percent, kills)
        with lock:
            # Faqat eng yaxshi natija saqlanadi.
            self.db.execute(
                'INSERT INTO score (name, country, city, continent, percent,'
                ' kills, at) VALUES (?, ?, ?, ?, ?, ?, strftime("%s","now")) '
                'ON CONFLICT(name, country) DO UPDATE SET '
                ' city = excluded.city, continent = excluded.continent,'
                ' kills = max(kills, excluded.kills),'
                ' percent = max(percent, excluded.percent),'
                ' at = excluded.at '
                'WHERE excluded.percent >= score.percent', row)
            self.db.commit()
        self._send(200, {'ok': True})

    def log_message(self, fmt, *args):
        pass


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', type=int, default=8080)
    parser.add_argument('--host', default='0.0.0.0')
    parser.add_argument('--db', default='colorland.db')
    args = parser.parse_args()

    Handler.db = connect(args.db)
    server = ThreadingHTTPServer((args.host, args.port), Handler)
    print(f'Color Land reyting serveri: http://{args.host}:{args.port}')
    server.serve_forever()


if __name__ == '__main__':
    main()
