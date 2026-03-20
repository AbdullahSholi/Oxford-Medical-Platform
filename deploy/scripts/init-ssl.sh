#!/bin/bash
# ═══════════════════════════════════════════════════════════
# MedOrder — SSL Certificate Setup (Let's Encrypt + Certbot)
# Run once after initial deployment
# Usage: ./init-ssl.sh api.yourdomain.com your@email.com
# ═══════════════════════════════════════════════════════════

set -euo pipefail

DOMAIN=${1:?"Usage: $0 <domain> <email>"}
EMAIL=${2:?"Usage: $0 <domain> <email>"}

echo "🔐 Setting up SSL for ${DOMAIN}..."

# Create required directories
mkdir -p deploy/certbot/conf deploy/certbot/www

# Step 1: Start nginx with HTTP only (for ACME challenge)
echo "Starting nginx for certificate request..."

# Create temporary nginx config without SSL
cat > deploy/nginx/conf.d/default.conf << EOF
server {
    listen 80;
    server_name ${DOMAIN};

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        proxy_pass http://server:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Restart nginx with HTTP-only config
docker compose -f docker-compose.prod.yml up -d nginx

# Step 2: Request certificate
echo "Requesting certificate from Let's Encrypt..."
docker compose -f docker-compose.prod.yml run --rm certbot \
    certbot certonly --webroot \
    --webroot-path=/var/www/certbot \
    --email "${EMAIL}" \
    --agree-tos \
    --no-eff-email \
    -d "${DOMAIN}"

# Step 3: Restore full nginx config with SSL
echo "Restoring SSL nginx config..."
cat > deploy/nginx/conf.d/default.conf << 'NGINXEOF'
upstream api {
    server server:3000;
    keepalive 32;
}

server {
    listen 80;
    server_name DOMAIN_PLACEHOLDER;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl;
    http2 on;
    server_name DOMAIN_PLACEHOLDER;

    ssl_certificate /etc/letsencrypt/live/DOMAIN_PLACEHOLDER/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/DOMAIN_PLACEHOLDER/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains" always;

    client_max_body_size 10m;

    location /api/ {
        limit_req zone=api burst=50 nodelay;
        proxy_pass http://api;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /socket.io/ {
        proxy_pass http://api;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_read_timeout 86400s;
    }

    location / {
        return 404;
    }
}
NGINXEOF

# Replace domain placeholder
sed -i "s/DOMAIN_PLACEHOLDER/${DOMAIN}/g" deploy/nginx/conf.d/default.conf

# Step 4: Reload nginx with SSL
docker compose -f docker-compose.prod.yml restart nginx

echo ""
echo "✅ SSL setup complete for ${DOMAIN}!"
echo "Certificate will auto-renew via the certbot container."
