#!/bin/bash
# ═══════════════════════════════════════════════════════════
# MedOrder — EC2 / VPS Initial Setup Script (Ubuntu 22.04+)
# Run as root on a fresh instance
# Usage: sudo bash setup-server.sh
# ═══════════════════════════════════════════════════════════

set -euo pipefail

echo "═══════════════════════════════════════════"
echo "  MedOrder — Server Setup (AWS EC2)"
echo "═══════════════════════════════════════════"

# 1. Update system
echo "📦 Updating system..."
apt-get update && apt-get upgrade -y

# 2. Install essential tools
echo "🔧 Installing essentials..."
apt-get install -y curl git htop nano unzip

# 3. Install Docker
echo "🐳 Installing Docker..."
curl -fsSL https://get.docker.com | sh
systemctl enable docker
systemctl start docker

# 4. Install Docker Compose plugin
echo "🐳 Installing Docker Compose..."
apt-get install -y docker-compose-plugin

# 5. Create app user and add to docker group
echo "👤 Creating medorder user..."
useradd -m -s /bin/bash -G docker medorder 2>/dev/null || usermod -aG docker medorder
# Also add ubuntu user (EC2 default) to docker group
usermod -aG docker ubuntu 2>/dev/null || true

# 6. Configure firewall
echo "🔥 Configuring firewall..."
apt-get install -y ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# 7. Install fail2ban (brute-force protection)
echo "🛡️ Installing fail2ban..."
apt-get install -y fail2ban
cat > /etc/fail2ban/jail.local << 'EOF'
[sshd]
enabled = true
port = ssh
filter = sshd
maxretry = 5
bantime = 3600
findtime = 600
EOF
systemctl enable fail2ban
systemctl restart fail2ban

# 8. Automatic security updates
echo "🔄 Enabling automatic security updates..."
apt-get install -y unattended-upgrades
cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

# 9. Set up swap (1GB — crucial for t3.micro with 1GB RAM)
echo "💾 Setting up swap..."
if [ ! -f /swapfile ]; then
    fallocate -l 1G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    # Optimize for low-memory instances
    echo 'vm.swappiness=10' >> /etc/sysctl.conf
    echo 'vm.vfs_cache_pressure=50' >> /etc/sysctl.conf
    sysctl -p
fi

# 10. Create app directory
echo "📁 Creating app directory..."
mkdir -p /opt/medorder
chown medorder:medorder /opt/medorder

# 11. Configure Docker log rotation (prevent disk filling up)
echo "📝 Configuring Docker log rotation..."
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << 'EOF'
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    }
}
EOF
systemctl restart docker

echo ""
echo "═══════════════════════════════════════════"
echo "  ✅ Server setup complete!"
echo "═══════════════════════════════════════════"
echo ""
echo "Next steps — run as the medorder user:"
echo "  sudo su - medorder"
echo "  cd /opt/medorder"
echo "  bash deploy/scripts/deploy.sh"
echo ""
