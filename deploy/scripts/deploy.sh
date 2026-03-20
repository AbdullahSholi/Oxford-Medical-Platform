#!/bin/bash
# ═══════════════════════════════════════════════════════════
# Oxford-Medical-Platform — One-Command Deploy Script
# Run from /opt/Oxford-Medical-Platform after server setup
# Usage: bash deploy/scripts/deploy.sh
# ═══════════════════════════════════════════════════════════

set -euo pipefail

APP_NAME="Oxford-Medical-Platform"
APP_DIR="/opt/Oxford-Medical-Platform"
APP_USER="oxford"
REPO_URL="${GITHUB_REPO:-}"
DOMAIN="${DOMAIN:-}"
EMAIL="${SSL_EMAIL:-}"

echo "═══════════════════════════════════════════"
echo "  $APP_NAME — Deploy"
echo "═══════════════════════════════════════════"

# ── Step 1: Clone or pull repo ──────────────────────────
if [ -z "$REPO_URL" ] && [ ! -f "$APP_DIR/docker-compose.prod.yml" ]; then
    echo ""
    read -rp "GitHub repo URL (e.g. https://github.com/user/repo.git): " REPO_URL
fi

mkdir -p "$APP_DIR"

if [ ! -f "$APP_DIR/docker-compose.prod.yml" ]; then
    echo "📥 Cloning repository..."
    git clone "$REPO_URL" "$APP_DIR/tmp-clone"
    shopt -s dotglob nullglob
    mv "$APP_DIR/tmp-clone/"* "$APP_DIR/" 2>/dev/null || true
    shopt -u dotglob nullglob
    rm -rf "$APP_DIR/tmp-clone"
else
    echo "📥 Pulling latest code..."
    cd "$APP_DIR"
    git pull origin main
fi

cd "$APP_DIR"

# Ensure ownership if script is run with sudo/root
if id "$APP_USER" >/dev/null 2>&1; then
    chown -R "$APP_USER:$APP_USER" "$APP_DIR" 2>/dev/null || true
fi

# ── Step 2: Environment file ────────────────────────────
if [ ! -f "$APP_DIR/.env" ]; then
    echo ""
    echo "⚙️  Creating environment file..."
    echo "   Fill in the values, then re-run this script."
    echo ""

    cat > "$APP_DIR/.env" << 'EOF'
# ═══════════════════════════════════════════════════════════
# Oxford-Medical-Platform — Production Environment
# Fill in ALL values below, then re-run deploy.sh
# ═══════════════════════════════════════════════════════════

# ── Database (internal Docker network — don't change host/port) ──
DB_NAME=oxford_medical_platform
DB_USER=oxford
DB_PASSWORD=CHANGE_ME_STRONG_DB_PASSWORD

# ── Server ───────────────────────────────────────────────
NODE_ENV=production
PORT=3000
API_PREFIX=/api/v1
CORS_ORIGINS=https://YOUR_DOMAIN

# ── Auth (generate with: openssl rand -base64 48) ───────
JWT_ACCESS_SECRET=CHANGE_ME
JWT_REFRESH_SECRET=CHANGE_ME
JWT_ACCESS_EXPIRY=15m
JWT_REFRESH_EXPIRY=7d
BCRYPT_ROUNDS=12
OTP_EXPIRY_SECONDS=300

# ── Storage / Object Store ──────────────────────────────
S3_BUCKET=oxford-medical-platform-uploads
S3_REGION=auto
S3_ACCESS_KEY=
S3_SECRET_KEY=
S3_ENDPOINT=
CDN_BASE_URL=

# ── Email (example: Gmail App Password) ────────────────
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your.email@gmail.com
SMTP_PASS=YOUR_16_CHAR_APP_PASSWORD
EMAIL_FROM=your.email@gmail.com

# ── Rate Limiting ───────────────────────────────────────
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX=100
LOGIN_RATE_LIMIT_MAX=5
LOGIN_RATE_LIMIT_WINDOW_MS=900000

# ── Domain (for SSL setup) ──────────────────────────────
DOMAIN=api.yourdomain.com
SSL_EMAIL=your@email.com
EOF

    echo "📝 Edit the .env file:"
    echo "   nano $APP_DIR/.env"
    echo ""
    echo "Then re-run: bash deploy/scripts/deploy.sh"
    exit 0
fi

# ── Load and validate env vars ──────────────────────────
set -a
source "$APP_DIR/.env"
set +a

if [ "${JWT_ACCESS_SECRET:-}" = "CHANGE_ME" ] || [ "${DB_PASSWORD:-}" = "CHANGE_ME_STRONG_DB_PASSWORD" ]; then
    echo "❌ You must fill in real values in .env first!"
    echo "   nano $APP_DIR/.env"
    exit 1
fi

if [ -z "${CORS_ORIGINS:-}" ]; then
    echo "❌ CORS_ORIGINS is missing in .env"
    exit 1
fi

# ── Step 3: Update deploy/.env.production ──────────────
echo "⚙️  Updating deploy/.env.production..."
mkdir -p "$APP_DIR/deploy"

cat > "$APP_DIR/deploy/.env.production" << EOF
NODE_ENV=production
PORT=${PORT:-3000}
API_PREFIX=${API_PREFIX:-/api/v1}
CORS_ORIGINS=${CORS_ORIGINS}
DATABASE_URL=postgresql://${DB_USER}:${DB_PASSWORD}@postgres:5432/${DB_NAME}?schema=public
DATABASE_POOL_MIN=2
DATABASE_POOL_MAX=10
REDIS_URL=redis://redis:6379
JWT_ACCESS_SECRET=${JWT_ACCESS_SECRET}
JWT_REFRESH_SECRET=${JWT_REFRESH_SECRET}
JWT_ACCESS_EXPIRY=${JWT_ACCESS_EXPIRY}
JWT_REFRESH_EXPIRY=${JWT_REFRESH_EXPIRY}
BCRYPT_ROUNDS=${BCRYPT_ROUNDS}
OTP_EXPIRY_SECONDS=${OTP_EXPIRY_SECONDS:-300}
S3_BUCKET=${S3_BUCKET}
S3_REGION=${S3_REGION}
S3_ACCESS_KEY=${S3_ACCESS_KEY}
S3_SECRET_KEY=${S3_SECRET_KEY}
S3_ENDPOINT=${S3_ENDPOINT}
CDN_BASE_URL=${CDN_BASE_URL}
SMTP_HOST=${SMTP_HOST}
SMTP_PORT=${SMTP_PORT}
SMTP_USER=${SMTP_USER}
SMTP_PASS=${SMTP_PASS}
EMAIL_FROM=${EMAIL_FROM}
RATE_LIMIT_WINDOW_MS=${RATE_LIMIT_WINDOW_MS}
RATE_LIMIT_MAX=${RATE_LIMIT_MAX}
LOGIN_RATE_LIMIT_MAX=${LOGIN_RATE_LIMIT_MAX}
LOGIN_RATE_LIMIT_WINDOW_MS=${LOGIN_RATE_LIMIT_WINDOW_MS}
EOF

# ── Step 4: Build and start containers ─────────────────
echo "🐳 Building and starting containers..."
export DB_NAME DB_USER DB_PASSWORD
docker compose -f docker-compose.prod.yml up -d --build

# ── Step 5: Wait for database to be ready ──────────────
echo "⏳ Waiting for database..."
DB_READY=0
for i in $(seq 1 30); do
    if docker compose -f docker-compose.prod.yml exec -T postgres pg_isready -U "$DB_USER" >/dev/null 2>&1; then
        echo "   Database ready!"
        DB_READY=1
        break
    fi
    sleep 2
done

if [ "$DB_READY" -ne 1 ]; then
    echo "❌ Database did not become ready in time."
    exit 1
fi

# ── Step 6: Run Prisma migrations ──────────────────────
echo "🗄️  Running database migrations..."
docker compose -f docker-compose.prod.yml exec -T server npx prisma db push

# ── Step 7: SSL setup ──────────────────────────────────
DOMAIN="${DOMAIN:-${DOMAIN:-}}"
EMAIL="${EMAIL:-${SSL_EMAIL:-}}"

if [ -n "${DOMAIN:-}" ] && [ -n "${EMAIL:-}" ] && [ ! -d "deploy/certbot/conf/live/$DOMAIN" ]; then
    echo "🔐 Setting up SSL certificate..."
    bash deploy/scripts/init-ssl.sh "$DOMAIN" "$EMAIL"
else
    if [ -n "${DOMAIN:-}" ] && [ -d "deploy/certbot/conf/live/$DOMAIN" ]; then
        echo "🔐 SSL certificate already exists"
    else
        echo "⚠️  Skipping SSL — set DOMAIN and SSL_EMAIL in .env to enable"
    fi
fi

# ── Step 8: Verify ─────────────────────────────────────
PUBLIC_IP="$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo 'YOUR_IP')"

echo ""
echo "🔍 Checking container status..."
docker compose -f docker-compose.prod.yml ps

echo ""
echo "═══════════════════════════════════════════"
echo "  ✅ Deployment complete!"
echo "═══════════════════════════════════════════"
echo ""
echo "Services:"
echo "  API:      http://$PUBLIC_IP:80"
echo "  Postgres: internal (port 5432)"
echo "  Redis:    internal (port 6379)"
echo ""
echo "Useful commands:"
echo "  Logs:     docker compose -f docker-compose.prod.yml logs -f server"
echo "  Restart:  docker compose -f docker-compose.prod.yml restart server"
echo "  DB shell: docker compose -f docker-compose.prod.yml exec postgres psql -U $DB_USER $DB_NAME"
echo "  Rebuild:  docker compose -f docker-compose.prod.yml up -d --build server"
echo "  Redeploy: git pull && docker compose -f docker-compose.prod.yml up -d --build"
echo ""