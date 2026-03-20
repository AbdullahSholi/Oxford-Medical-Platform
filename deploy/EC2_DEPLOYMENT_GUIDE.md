# Oxford Medical Platform — AWS EC2 Deployment Guide (Docker Compose)

Everything runs on a single EC2 instance: API Server + PostgreSQL + Redis + Nginx + SSL.

---

## Step 1: Launch EC2 Instance

1. Go to **AWS Console** → **EC2** → **Launch Instance**
2. Settings:
   - **Name**: `oxford-medical-platform`
   - **AMI**: Ubuntu Server 24.04 LTS (free tier eligible)
   - **Instance type**: `t3.micro` (free tier) or `t3.small` ($15/mo)
   - **Key pair**: Create new or select existing (you'll need this to SSH)
   - **Network settings**:
     - Allow SSH (port 22) — from **My IP** only
     - Allow HTTP (port 80) — from anywhere
     - Allow HTTPS (port 443) — from anywhere
   - **Storage**: 20 GB gp3 (free tier includes 30GB)
3. Click **Launch Instance**

## Step 2: Allocate Elastic IP (optional but recommended)

1. Go to **EC2** → **Elastic IPs** → **Allocate**
2. Associate it with your instance
3. This gives you a permanent IP that survives restarts (free while attached)

## Step 3: SSH into the Instance

```bash
ssh -i your-key.pem ubuntu@YOUR_EC2_PUBLIC_IP
```

## Step 4: Run Server Setup

```bash
# Clone the repo and run setup
sudo git clone https://github.com/AbdullahSholi/Oxford-Medical-Platform.git /opt/Oxford-Medical-Platform
cd /opt/Oxford-Medical-Platform
sudo bash deploy/scripts/setup-server.sh
```

This installs Docker, Docker Compose, firewall, fail2ban, swap, and Docker log rotation.

## Step 5: Deploy the Application

```bash
sudo su - oxford
cd /opt/Oxford-Medical-Platform
bash deploy/scripts/deploy.sh
```

**First run**: The script creates an `.env` file and asks you to fill in values:
```bash
nano /opt/Oxford-Medical-Platform/.env
```

Fill in:
- `DB_PASSWORD` — a strong password (e.g., `openssl rand -base64 32`)
- `JWT_ACCESS_SECRET` — run `openssl rand -base64 48`
- `JWT_REFRESH_SECRET` — run `openssl rand -base64 48`
- `CORS_ORIGINS` — your frontend domain(s)
- `SMTP_USER` / `SMTP_PASS` — Gmail credentials (see Step 7)
- `S3_*` / `CDN_BASE_URL` — Cloudflare R2 credentials (see Step 8)
- `DOMAIN` / `SSL_EMAIL` — for Let's Encrypt SSL (leave as placeholder if no domain yet)

Then re-run:
```bash
bash deploy/scripts/deploy.sh
```

### After first successful deploy — fix Nginx for HTTP-only (no SSL yet)

If you don't have a domain/SSL configured yet, nginx will crash because it references missing cert files. Run this to use HTTP-only mode:

```bash
cat > deploy/nginx/conf.d/default.conf << 'EOF'
upstream api {
    server server:3000;
    keepalive 32;
}

server {
    listen 80;
    server_name _;

    location /api/ {
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
        proxy_read_timeout 86400s;
    }

    location / {
        return 404;
    }
}
EOF

docker compose -f docker-compose.prod.yml restart nginx
```

### Verify

```bash
curl http://localhost/api/v1/products?limit=1
# Should return: {"success":true,"data":[],...}
```

From your browser: `http://YOUR_EC2_PUBLIC_IP/api/v1/products?limit=1`

## Step 6: Point Your Domain

1. In your DNS provider (Cloudflare, Route53, etc.), create:
   - `A` record: `api.yourdomain.com` → `YOUR_EC2_ELASTIC_IP`
2. Update `.env`:
   - `DOMAIN=api.yourdomain.com`
   - `SSL_EMAIL=your@email.com`
3. Run SSL setup:
   ```bash
   bash deploy/scripts/init-ssl.sh api.yourdomain.com your@email.com
   ```

## Step 7: Gmail App Password (Email)

1. Enable **2-Step Verification** on your Google account
2. Go to https://myaccount.google.com/apppasswords
3. Generate an app password for "Mail"
4. Use the 16-character password as `SMTP_PASS` (without spaces)

## Step 8: Cloudflare R2 (File Storage)

1. Create R2 bucket: `oxford-medical-platform-uploads`
2. Create R2 API token → note Access Key + Secret Key
3. Fill in `.env`: `S3_ACCESS_KEY`, `S3_SECRET_KEY`, `S3_ENDPOINT`

---

## Day-to-Day Operations

### View logs
```bash
cd /opt/Oxford-Medical-Platform
docker compose -f docker-compose.prod.yml logs -f server
docker compose -f docker-compose.prod.yml logs -f postgres
```

### Restart server
```bash
docker compose -f docker-compose.prod.yml restart server
```

### Update code (redeploy)
```bash
cd /opt/Oxford-Medical-Platform
git pull origin main
docker compose -f docker-compose.prod.yml up -d --build server
docker compose -f docker-compose.prod.yml exec -T server npx prisma db push
```

### Database access
```bash
docker compose -f docker-compose.prod.yml exec postgres psql -U oxford oxford_medical_platform
```

### Manual backup
```bash
docker compose -f docker-compose.prod.yml exec backup /backup.sh
```

### Check backups
```bash
docker compose -f docker-compose.prod.yml exec backup ls -lh /backups/
```

### Monitor resources
```bash
htop                    # CPU/memory
docker stats            # Per-container resource usage
df -h                   # Disk space
```

---

## Troubleshooting

### Nginx keeps restarting
The default nginx config requires SSL certs. If you don't have a domain yet, use the HTTP-only config from Step 5.

### `git pull` fails with "local changes would be overwritten"
```bash
git stash
git pull origin main
```

### Server container port 3000 not accessible from host
Port 3000 is internal to the Docker network — access via nginx on port 80:
```bash
curl http://localhost/api/v1/products?limit=1    # correct
# NOT: curl http://localhost:3000/...            # won't work
```

### BullMQ "noeviction" warnings
Redis is configured with `allkeys-lru` for caching. BullMQ prefers `noeviction` but works fine with `allkeys-lru`. These warnings are safe to ignore.

---

## AWS Security Checklist

- [ ] SSH key pair stored safely (never share the .pem file)
- [ ] Security group: SSH restricted to your IP only
- [ ] Elastic IP attached (so IP doesn't change on restart)
- [ ] fail2ban running (auto-bans brute-force SSH attempts)
- [ ] UFW firewall enabled (only ports 22, 80, 443 open)
- [ ] Automatic security updates enabled
- [ ] `.env` file has strong passwords (not defaults)
- [ ] Daily database backups running (check `/backups/`)

---

## Cost Summary

| Resource | Monthly Cost |
|----------|-------------|
| EC2 t3.micro (free tier year 1) | $0 |
| EC2 t3.micro (after free tier) | ~$8.50 |
| EBS 20GB gp3 | ~$1.60 |
| Elastic IP | $0 (while attached) |
| Data transfer (first 100GB) | $0 |
| Cloudflare R2 storage | $0 (10GB free) |
| Gmail email | $0 |
| SSL (Let's Encrypt) | $0 |
| Domain | ~$12/year |
| **Total (year 1)** | **~$3/mo** |
| **Total (after free tier)** | **~$11/mo** |
