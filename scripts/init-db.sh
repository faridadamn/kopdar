#!/bin/bash
# =============================================================================
# KopDar — Database Initialization Script
# =============================================================================
# Runs on first container start via docker-entrypoint-initdb.d
# Also callable standalone: ./scripts/init-db.sh [--seed]
# =============================================================================
set -euo pipefail

DB_NAME="${DB_NAME:-kopdar}"
DB_USER="${DB_USER:-kopdar}"

SEED=false
if [[ "${1:-}" == "--seed" ]]; then
    SEED=true
fi

echo "=========================================="
echo "  KopDar Database Initialization"
echo "=========================================="

# ---------------------------------------------------------------------------
# 1. Wait for PostgreSQL to be ready
# ---------------------------------------------------------------------------
echo "[1/4] Waiting for PostgreSQL..."
MAX_RETRIES=30
RETRY_COUNT=0

until pg_isready -U "$DB_USER" -d "$DB_NAME" > /dev/null 2>&1; do
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [[ $RETRY_COUNT -ge $MAX_RETRIES ]]; then
        echo "ERROR: PostgreSQL not ready after $MAX_RETRIES attempts. Exiting."
        exit 1
    fi
    echo "  Waiting... ($RETRY_COUNT/$MAX_RETRIES)"
    sleep 2
done

echo "  PostgreSQL is ready."

# ---------------------------------------------------------------------------
# 2. Create database if not exists (handled by POSTGRES_DB env in Docker)
# ---------------------------------------------------------------------------
echo "[2/4] Ensuring database '$DB_NAME' exists..."
psql -v ON_ERROR_STOP=1 --username "$DB_USER" <<-EOSQL
    SELECT 'CREATE DATABASE $DB_NAME'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$DB_NAME')\gexec
EOSQL
echo "  Database '$DB_NAME' ready."

# ---------------------------------------------------------------------------
# 3. Enable PostGIS extension
# ---------------------------------------------------------------------------
echo "[3/4] Enabling PostGIS extension..."
psql -v ON_ERROR_STOP=1 --username "$DB_USER" --dbname "$DB_NAME" <<-EOSQL
    CREATE EXTENSION IF NOT EXISTS postgis;
    CREATE EXTENSION IF NOT EXISTS postgis_topology;
    CREATE EXTENSION IF NOT EXISTS pg_trgm;
EOSQL
echo "  PostGIS extensions enabled."

# ---------------------------------------------------------------------------
# 4. Run migrations
# ---------------------------------------------------------------------------
echo "[4/4] Running migrations..."
MIGRATIONS_DIR="/app/migrations"

if [[ -d "$MIGRATIONS_DIR" ]]; then
    for migration in $(ls "$MIGRATIONS_DIR"/*.sql 2>/dev/null | sort); do
        echo "  Applying: $(basename "$migration")"
        psql -v ON_ERROR_STOP=1 --username "$DB_USER" --dbname "$DB_NAME" -f "$migration"
    done
    echo "  Migrations complete."
else
    echo "  No migrations directory found at $MIGRATIONS_DIR — skipping."
    echo "  (In dev, migrations are run via: make db-migrate)"
fi

# ---------------------------------------------------------------------------
# 5. Seed data (optional)
# ---------------------------------------------------------------------------
if [[ "$SEED" == "true" ]]; then
    echo "[+] Seeding data..."
    SEED_FILE="/app/scripts/seed.sql"
    if [[ -f "$SEED_FILE" ]]; then
        psql -v ON_ERROR_STOP=1 --username "$DB_USER" --dbname "$DB_NAME" -f "$SEED_FILE"
        echo "  Seed data loaded."
    else
        echo "  No seed file found at $SEED_FILE — skipping."
    fi
fi

echo "=========================================="
echo "  Initialization complete!"
echo "=========================================="
