#!/bin/bash
set -euo pipefail

# Reset ownership of persistent data directory
chown -R cloudron:cloudron /app/data

# Gate first-run initialization
if [[ ! -f /app/data/.initialized ]]; then
    echo "First run: initializing 9router data directory..."

    # Seed MITM enabled by default (UI toggle may not work on first run)
    gosu cloudron:cloudron node -e "
const path = require('path');
const fs = require('fs');
const dbDir = path.join(process.env.DATA_DIR || '/app/data', 'db');
const dbFile = path.join(dbDir, 'data.sqlite');
if (!fs.existsSync(dbFile)) { process.exit(0); }
try {
  const { DatabaseSync } = require('node:sqlite');
  const db = new DatabaseSync(dbFile, { readOnly: false });
  const row = db.prepare('SELECT data FROM settings WHERE id = 1').get();
  const settings = row ? JSON.parse(row.data) : {};
  if (!settings.mitmEnabled) {
    settings.mitmEnabled = true;
    db.prepare('INSERT INTO settings(id, data) VALUES(1, ?) ON CONFLICT(id) DO UPDATE SET data = excluded.data')
      .run(JSON.stringify(settings));
    console.log('Seeded mitmEnabled=true in settings');
  }
  db.close();
} catch (e) {
  console.log('MITM seed skipped:', e.message);
}
"

    touch /app/data/.initialized
fi

# Drop privileges and start the app
cd /app/code
exec gosu cloudron:cloudron node custom-server.js
