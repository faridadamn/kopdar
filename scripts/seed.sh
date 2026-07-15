#!/bin/bash
# ─────────────────────────────────────────────────────────
# KopDar — Seed Database
# ─────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SEED_FILE="$SCRIPT_DIR/seed.sql"

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-kopdar}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-postgres}"

export PGPASSWORD="$DB_PASSWORD"

red()   { printf '\033[0;31m%s\033[0m\n' "$*"; }
green() { printf '\033[0;32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

bold "╔══════════════════════════════════════════════════════╗"
bold "║           KopDar — Database Seeder                  ║"
bold "╚══════════════════════════════════════════════════════╝"
echo ""
echo "Host: $DB_HOST:$DB_PORT"
echo "Database: $DB_NAME"
echo "User: $DB_USER"
echo ""

# Check if psql is available
if ! command -v psql &> /dev/null; then
  red "Error: psql not found. Install PostgreSQL client."
  exit 1
fi

# Check if seed file exists
if [ ! -f "$SEED_FILE" ]; then
  red "Error: Seed file not found: $SEED_FILE"
  exit 1
fi

# Test connection
bold "Testing database connection..."
if ! psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
  red "Error: Cannot connect to database."
  red "Make sure PostgreSQL is running and the database exists:"
  red "  createdb -h $DB_HOST -p $DB_PORT -U $DB_USER $DB_NAME"
  exit 1
fi
green "✅ Connected to database"
echo ""

# Check if tables exist (migrations should be run first)
bold "Checking if schema exists..."
TABLE_COUNT=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE';" 2>/dev/null || echo "0")
if [ "$TABLE_COUNT" -lt 5 ]; then
  red "Error: Schema not found ($TABLE_COUNT tables). Run migrations first:"
  red "  cd kopdar/backend && go run ./cmd/migrate up"
  exit 1
fi
green "✅ Schema exists ($TABLE_COUNT tables)"
echo ""

# Check if data already exists
EXISTING=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT count(*) FROM users;" 2>/dev/null || echo "0")
if [ "$EXISTING" -gt 0 ]; then
  bold "⚠️  Database already has $EXISTING users."
  read -p "    Truncate all data and re-seed? (y/N) " -n 1 -r
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    bold "Truncating existing data..."
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
      TRUNCATE community_posts, emergency_contacts, pinjol_records, savings,
               transactions, driver_platforms, drivers, users, zones
      CASCADE;
    "
    green "✅ Data truncated"
  else
    bold "Skipping truncate — seed may fail on conflicts."
  fi
  echo ""
fi

# Run seed
bold "Running seed data..."
if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$SEED_FILE"; then
  echo ""
  green "✅ Seed data loaded successfully!"
else
  red "❌ Seed data failed. Check the error above."
  exit 1
fi

# Summary
echo ""
bold "Seed Summary:"
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
  SELECT 'zones' AS entity, count(*) AS count FROM zones
  UNION ALL SELECT 'users (admin)', count(*) FROM users WHERE role = 'admin'
  UNION ALL SELECT 'users (driver)', count(*) FROM users WHERE role = 'driver'
  UNION ALL SELECT 'drivers', count(*) FROM drivers
  UNION ALL SELECT '  pending', count(*) FROM drivers WHERE status = 'pending'
  UNION ALL SELECT '  approved', count(*) FROM drivers WHERE status = 'approved'
  UNION ALL SELECT '  rejected', count(*) FROM drivers WHERE status = 'rejected'
  UNION ALL SELECT 'transactions', count(*) FROM transactions
  UNION ALL SELECT 'savings', count(*) FROM savings
  UNION ALL SELECT 'pinjol_records', count(*) FROM pinjol_records
  UNION ALL SELECT 'community_posts', count(*) FROM community_posts
  UNION ALL SELECT 'emergency_contacts', count(*) FROM emergency_contacts;
"

unset PGPASSWORD
