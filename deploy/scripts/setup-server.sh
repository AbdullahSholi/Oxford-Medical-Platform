#!/bin/bash
# ═══════════════════════════════════════════════════════════
# MedOrder — VPS Initial Setup Script (Hetzner/Ubuntu 22.04+)
# Run as root on a fresh VPS
# Usage: curl -sSL https://raw.githubusercontent.com/YOUR_REPO/main/deploy/scripts/setup-server.sh | bash
# ═══════════════════════════════════════════════════════════

set -euo pipefail

echo "═══════════════════════════════════════════"
echo "  MedOrder — Server Setup"
echo "═══════════════════════════════════════════"

# 1. Update system
echo "📦 Updating system..."
apt-get update && apt-get upgrade -y

# 2. Install Docker
echo "🐳 Installing Docker..."
curl -fsSL https://get.docker.com | sh
systemctl enable docker
systemctl start docker

# 3. Install Docker Compose plugin
echo "🐳 Installing Docker Compose..."
apt-get install -y docker-compose-plugin

# 4. Create app user
echo "👤 Creating medorder user..."
useradd -m -s /bin/bash -G docker medorder || true

# 5. Configure firewall
echo "🔥 Configuring firewall..."
apt-get install -y ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# 6. Install fail2ban
echo "🛡️ Installing fail2ban..."
apt-get install -y fail2ban
systemctl enable fail2ban
systemctl start fail2ban

# 7. Configure automatic security updates
echo "🔄 Enabling automatic security updates..."
apt-get install -y unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades

# 8. Set up swap (2GB — useful for 4GB VPS)
echo "💾 Setting up swap..."
if [ ! -f /swapfile ]; then
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    echo 'vm.swappiness=10' >> /etc/sysctl.conf
    sysctl -p
fi

# 9. Create app directory
echo "📁 Creating app directory..."
mkdir -p /opt/medorder
chown medorder:medorder /opt/medorder

echo ""
echo "═══════════════════════════════════════════"
echo "  ✅ Server setup complete!"
echo "═══════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "  1. Clone your repo to /opt/medorder"
echo "  2. Copy deploy/.env.production and fill in secrets"
echo "  3. Run: docker compose -f docker-compose.prod.yml up -d"
echo "  4. Run: docker compose exec server npx prisma db push"
echo "  5. Run SSL setup: deploy/scripts/init-ssl.sh"
echo ""
