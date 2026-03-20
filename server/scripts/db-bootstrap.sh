#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# MedOrder — Database Bootstrap Script
# Runs all SQL files in order after Prisma migration
# Usage: npm run db:bootstrap  (or ./scripts/db-bootstrap.sh)
# ═══════════════════════════════════════════════════════════

set -euo pipefail

# Load DATABASE_URL from .env
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

DB_URL="${DATABASE_URL:?'DATABASE_URL not set. Create a .env file or set it in your environment.'}"
SQL_DIR="prisma/sql"

echo "╔══════════════════════════════════════════════╗"
echo "║  MedOrder — Database Bootstrap               ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# Step 1: Run Prisma migration
echo "▸ Step 1: Running Prisma migrations..."
npx prisma migrate deploy
echo "  ✓ Prisma migrations applied"
echo ""

# Step 2: Run SQL files in order
echo "▸ Step 2: Applying supplementary SQL scripts..."
for sql_file in $(ls -1 "$SQL_DIR"/*.sql 2>/dev/null | sort); do
    filename=$(basename "$sql_file")
    echo "  ⏳ Running $filename..."
    psql "$DB_URL" -f "$sql_file" -v ON_ERROR_STOP=1 --quiet 2>&1 | sed 's/^/     /'
    echo "  ✓ $filename applied"
done
echo ""

# Step 3: Run seeder
echo "▸ Step 3: Seeding database..."
npx tsx scripts/seed.ts
echo "  ✓ Seed data inserted"
echo ""

echo "╔══════════════════════════════════════════════╗"
echo "║  ✅ Database bootstrap complete!              ║"
echo "╚══════════════════════════════════════════════╝"
