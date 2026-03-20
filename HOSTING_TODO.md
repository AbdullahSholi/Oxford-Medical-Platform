# Backend Hosting Plan — Oxford Medical Platform
**Goal**: Production-ready deployment with minimal cost

---

## Phase 1: Infrastructure Setup

### 1.1 Choose Cloud Provider
- [ ] **Option A: Railway.app** (~$5-20/mo) — Easiest, auto-deploy from GitHub
  - Free tier: 500 hours/mo, 512MB RAM
  - Pro: $5/mo base + usage, auto-scaling, built-in PostgreSQL & Redis
- [ ] **Option B: Render.com** (~$7-25/mo) — Simple, good free tier
  - Free web service (spins down after inactivity)
  - Starter: $7/mo per service, always-on
- [ ] **Option C: DigitalOcean App Platform** (~$12-24/mo) — More control
  - Basic: $5/mo droplet + $7/mo managed DB
- [ ] **Option D: VPS (Hetzner/Contabo)** (~$4-8/mo) — Cheapest, most manual
  - Hetzner CX22: €4.35/mo (2 vCPU, 4GB RAM, 40GB SSD)
  - Run everything on one VPS with Docker Compose

### 1.2 Database (PostgreSQL)
- [ ] **Option A: Neon.dev** — Free tier: 0.5GB storage, auto-suspend
- [ ] **Option B: Supabase** — Free tier: 500MB, 2 projects
- [ ] **Option C: Railway/Render managed** — Included with platform ($7/mo)
- [ ] **Option D: Self-hosted on VPS** — $0 extra, runs in Docker

### 1.3 Redis
- [ ] **Option A: Upstash** — Free tier: 10K commands/day, serverless
- [ ] **Option B: Redis Cloud** — Free tier: 30MB
- [ ] **Option C: Self-hosted on VPS** — $0 extra, runs in Docker

### 1.4 Object Storage (S3/MinIO replacement)
- [ ] **Option A: Cloudflare R2** — Free: 10GB storage, 10M reads/mo, no egress fees
- [ ] **Option B: Backblaze B2** — Free: 10GB, cheap egress via Cloudflare
- [ ] **Option C: DigitalOcean Spaces** — $5/mo, 250GB + CDN

---

## Phase 2: Pre-Deployment Prep

### 2.1 Environment & Security
- [ ] Generate strong JWT secrets (32+ chars)
- [ ] Set `NODE_ENV=production`
- [ ] Set `BCRYPT_ROUNDS=12` (keep current)
- [ ] Configure CORS for production domain only
- [ ] Set up `.env.production` (never commit to git)
- [ ] Enable HTTPS (auto via platform or Let's Encrypt)

### 2.2 Database Migration
- [ ] Run `npx prisma migrate deploy` in production
- [ ] Create production admin account
- [ ] Seed initial categories and essential data
- [ ] Set up automated daily backups (pg_dump or managed snapshots)

### 2.3 Docker Setup
- [ ] Create optimized `Dockerfile` for Node.js server
  ```
  - Multi-stage build (builder + runner)
  - Use node:22-alpine for small image
  - Only copy dist + node_modules (production)
  ```
- [ ] Create `docker-compose.prod.yml` with:
  - Server (Node.js)
  - PostgreSQL 16
  - Redis 7
  - Nginx reverse proxy
- [ ] Add health check endpoints

### 2.4 Code Changes for Production
- [ ] Switch from MinIO to Cloudflare R2 / S3 (update S3 config)
- [ ] Configure email service (Resend.com free tier: 3K emails/mo)
- [ ] Set up push notifications (Firebase — free tier sufficient)
- [ ] Add `trust proxy` for Express behind reverse proxy
- [ ] Ensure rate limiting uses Redis store (not in-memory) for multi-instance

---

## Phase 3: Deployment

### 3.1 CI/CD Pipeline
- [ ] GitHub Actions workflow:
  - Run tests on PR
  - Build Docker image on merge to `main`
  - Push to container registry (GitHub Packages — free)
  - Deploy to server (SSH or platform API)
- [ ] Set up staging environment (optional, same infra at smaller scale)

### 3.2 Domain & DNS
- [ ] Buy domain (~$10/yr on Namecheap/Cloudflare)
- [ ] Set up Cloudflare DNS (free tier) for:
  - `api.yourdomain.com` → backend server
  - `app.yourdomain.com` → mobile web app
  - `admin.yourdomain.com` → admin dashboard
- [ ] Enable Cloudflare proxy for DDoS protection + caching (free)

### 3.3 SSL/TLS
- [ ] Auto-SSL via Cloudflare (free) or Let's Encrypt + Certbot

---

## Phase 4: Monitoring & Maintenance

### 4.1 Monitoring (Free Tools)
- [ ] **UptimeRobot** — Free: 50 monitors, 5-min checks
- [ ] **Sentry** — Free tier: 5K errors/mo (already in .env)
- [ ] **BetterStack Logs** — Free: 1GB/mo log ingestion

### 4.2 Backups
- [ ] Daily automated PostgreSQL backups (cron + pg_dump to R2)
- [ ] Keep 7 daily + 4 weekly backups
- [ ] Test restore procedure monthly

### 4.3 Scaling Plan (When Needed)
- [ ] Add Redis caching to more endpoints (already started)
- [ ] Horizontal scaling: run 2+ server instances behind load balancer
- [ ] Move to managed DB if self-hosted becomes bottleneck
- [ ] CDN for static assets (Cloudflare — already free)

---

## Recommended Stack: Render.com (Managed, Low DevOps)

| Service | Provider | Cost/mo |
|---------|----------|---------|
| API Server | Render Starter | $7.00 |
| PostgreSQL | Render Free / Starter | $0 - $7 |
| Redis | Render Free | $0 |
| Object Storage | Cloudflare R2 | $0 (free tier) |
| Email | Gmail App Password | $0 (500/day free) |
| DNS + CDN + SSL | Cloudflare + Render | $0 |
| Monitoring | UptimeRobot + Sentry | $0 |
| Domain | Cloudflare Registrar | ~$1/mo |
| **TOTAL (min)** | | **~$8/mo** |
| **TOTAL (persistent DB)** | | **~$15/mo** |

---

## Priority Order
1. **Push to GitHub** — Render deploys from repo
2. **Create Render services** — PostgreSQL, Redis, Web Service
3. **Switch MinIO → R2** — production storage (Cloudflare)
4. **Domain + Cloudflare DNS** — point `api.domain` to Render
5. **Set env vars** — fill in secrets on Render dashboard
6. **CI/CD** — Render auto-deploys on push to main
6. **Monitoring** — Sentry + UptimeRobot
7. **Backups** — automated pg_dump
