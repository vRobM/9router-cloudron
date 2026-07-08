#!/bin/bash
set -euo pipefail

# Cloudron MITM: use non-privileged port (443 requires root)
export MITM_PORT="${MITM_PORT:-8443}"

# Reset ownership of persistent data directory
chown -R cloudron:cloudron /app/data

# Gate first-run initialization
if [[ ! -f /app/data/.initialized ]]; then
    echo "First run: initializing 9router data directory..."

    # Seed MITM enabled by default with Cloudron-optimized settings
    gosu cloudron:cloudron node -e "
const path = require('path');
const fs = require('fs');
const dbDir = path.join(process.env.DATA_DIR || '/app/data', 'db');
const dbFile = path.join(dbDir, 'data.sqlite');
if (!fs.existsSync(dbFile)) { process.exit(0); }
try {
  const Database = require('better-sqlite3');
  const db = new Database(dbFile);
  const row = db.prepare('SELECT data FROM settings WHERE id = 1').get();
  const settings = row ? JSON.parse(row.data) : {};

  // Enable MITM with Cloudron-optimized settings
  settings.mitmEnabled = true;
  settings.mitmRouterBaseUrl = 'http://localhost:20128';
  // Use non-privileged port for Cloudron container
  settings.mitmPort = parseInt(process.env.MITM_PORT, 10) || 8443;

  db.prepare('INSERT INTO settings(id, data) VALUES(1, ?) ON CONFLICT(id) DO UPDATE SET data = excluded.data')
    .run(JSON.stringify(settings));
  console.log('Seeded MITM settings: enabled=true, port=' + settings.mitmPort);
  db.close();
} catch (e) {
  console.log('MITM seed skipped:', e.message);
}
"

    touch /app/data/.initialized
fi

# Always ensure MITM port is set (survives updates)
gosu cloudron:cloudron node -e "
const path = require('path');
const fs = require('fs');
const dbDir = path.join(process.env.DATA_DIR || '/app/data', 'db');
const dbFile = path.join(dbDir, 'data.sqlite');
if (!fs.existsSync(dbFile)) { process.exit(0); }
try {
  const Database = require('better-sqlite3');
  const db = new Database(dbFile);
  const row = db.prepare('SELECT data FROM settings WHERE id = 1').get();
  const settings = row ? JSON.parse(row.data) : {};
  let changed = false;
  if (!settings.mitmEnabled) { settings.mitmEnabled = true; changed = true; }
  if (!settings.mitmRouterBaseUrl) { settings.mitmRouterBaseUrl = 'http://localhost:20128'; changed = true; }
  const desiredPort = parseInt(process.env.MITM_PORT, 10) || 8443;
  if (settings.mitmPort !== desiredPort) { settings.mitmPort = desiredPort; changed = true; }
  if (changed) {
    db.prepare('INSERT INTO settings(id, data) VALUES(1, ?) ON CONFLICT(id) DO UPDATE SET data = excluded.data')
      .run(JSON.stringify(settings));
    console.log('Updated MITM settings: port=' + settings.mitmPort);
  }
  db.close();
} catch (e) {
  console.log('MITM update skipped:', e.message);
}
"

# Seed Cloudron OIDC settings into database (so dashboard shows OIDC login)
if [[ -n "${CLOUDRON_OIDC_DISCOVERY_URL:-}" && -n "${CLOUDRON_OIDC_CLIENT_ID:-}" && -n "${CLOUDRON_OIDC_CLIENT_SECRET:-}" ]]; then
    echo "Cloudron OIDC detected — seeding OIDC settings into database..."
    gosu cloudron:cloudron node -e "
const path = require('path');
const fs = require('fs');
const dbDir = path.join(process.env.DATA_DIR || '/app/data', 'db');
const dbFile = path.join(dbDir, 'data.sqlite');
if (!fs.existsSync(dbFile)) { process.exit(0); }
try {
  const Database = require('better-sqlite3');
  const db = new Database(dbFile);
  const row = db.prepare('SELECT data FROM settings WHERE id = 1').get();
  const settings = row ? JSON.parse(row.data) : {};

  // Derive issuer from discovery URL
  const discoveryUrl = process.env.CLOUDRON_OIDC_DISCOVERY_URL || '';
  const issuerUrl = discoveryUrl.replace(/\\/\\.well-known\\/openid-configuration$/, '').replace(/\\/+$/, '');

  settings.authMode = 'oidc';
  settings.oidcIssuerUrl = issuerUrl;
  settings.oidcClientId = process.env.CLOUDRON_OIDC_CLIENT_ID || '';
  settings.oidcClientSecret = process.env.CLOUDRON_OIDC_CLIENT_SECRET || '';
  settings.oidcScopes = 'openid profile email';
  settings.oidcLoginLabel = process.env.CLOUDRON_OIDC_PROVIDER_NAME
    ? 'Sign in with ' + process.env.CLOUDRON_OIDC_PROVIDER_NAME
    : 'Sign in with Cloudron';

  db.prepare('INSERT INTO settings(id, data) VALUES(1, ?) ON CONFLICT(id) DO UPDATE SET data = excluded.data')
    .run(JSON.stringify(settings));
  console.log('Seeded Cloudron OIDC settings (authMode=oidc)');
  db.close();
} catch (e) {
  console.log('OIDC seed skipped:', e.message);
}
"
fi

# Drop privileges and start the app
cd /app/code
exec gosu cloudron:cloudron node custom-server.js
