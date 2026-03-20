# MedOrder — Production Deployment Guide (Render.com)

## Prerequisites
- Render.com account
- Cloudflare account (free)
- Domain name
- GitHub repository

---

## Step 1: Push to GitHub

Make sure your code is pushed to a GitHub repository. Render deploys directly from GitHub.

## Step 2: Create Render Services

### 2.1 PostgreSQL Database
1. Go to Render Dashboard → **New** → **PostgreSQL**
2. Settings:
   - **Name**: `medorder-db`
   - **Plan**: Free (256MB) or Starter ($7/mo for persistence)
   - **Region**: Choose closest to your users
3. Note the **Internal Database URL** (starts with `postgresql://...`)

### 2.2 Redis
1. Go to **New** → **Redis**
2. Settings:
   - **Name**: `medorder-redis`
   - **Plan**: Free (25MB) or Starter ($7/mo)
   - **Max Memory Policy**: `allkeys-lru`
3. Note the **Internal Redis URL** (starts with `redis://...`)

### 2.3 Web Service (API Server)
1. Go to **New** → **Web Service**
2. Connect your GitHub repository
3. Settings:
   - **Name**: `medorder-api`
   - **Region**: Same as your database
   - **Branch**: `main`
   - **Root Directory**: `server`
   - **Runtime**: Docker
   - **Plan**: Starter ($7/mo) or Free (spins down after inactivity)
4. Add environment variables (see Step 3)

## Step 3: Environment Variables

Add these in the Render web service settings → **Environment**:

| Key | Value |
|-----|-------|
| `NODE_ENV` | `production` |
| `PORT` | `3000` |
| `API_PREFIX` | `/api/v1` |
| `CORS_ORIGINS` | `https://app.YOUR_DOMAIN,https://admin.YOUR_DOMAIN` |
| `DATABASE_URL` | *(from Step 2.1 — Internal URL)* |
| `DATABASE_POOL_MIN` | `2` |
| `DATABASE_POOL_MAX` | `10` |
| `REDIS_URL` | *(from Step 2.2 — Internal URL)* |
| `JWT_ACCESS_SECRET` | *(generate: `openssl rand -base64 48`)* |
| `JWT_REFRESH_SECRET` | *(generate: `openssl rand -base64 48`)* |
| `JWT_ACCESS_EXPIRY` | `15m` |
| `JWT_REFRESH_EXPIRY` | `7d` |
| `BCRYPT_ROUNDS` | `12` |
| `S3_BUCKET` | `medorder-uploads` |
| `S3_REGION` | `auto` |
| `S3_ACCESS_KEY` | *(from Cloudflare R2)* |
| `S3_SECRET_KEY` | *(from Cloudflare R2)* |
| `S3_ENDPOINT` | `https://YOUR_ACCOUNT_ID.r2.cloudflarestorage.com` |
| `CDN_BASE_URL` | `https://cdn.YOUR_DOMAIN` |
| `SMTP_HOST` | `smtp.gmail.com` |
| `SMTP_PORT` | `587` |
| `SMTP_USER` | `your.email@gmail.com` |
| `SMTP_PASS` | *(Gmail App Password — 16 chars)* |
| `EMAIL_FROM` | `your.email@gmail.com` |
| `RATE_LIMIT_WINDOW_MS` | `60000` |
| `RATE_LIMIT_MAX` | `100` |
| `LOGIN_RATE_LIMIT_MAX` | `5` |
| `LOGIN_RATE_LIMIT_WINDOW_MS` | `900000` |

## Step 4: Cloudflare R2 Storage (Free)

1. Go to R2 in Cloudflare dashboard
2. Create bucket: `medorder-uploads`
3. Go to R2 → **Manage R2 API tokens** → Create API token
4. Note: Account ID, Access Key ID, Secret Access Key
5. Optional: Connect a custom domain (e.g., `cdn.yourdomain.com`)

## Step 5: Gmail App Password (Free — 500 emails/day)

1. Enable **2-Step Verification** on your Google account
2. Go to https://myaccount.google.com/apppasswords
3. Generate an app password for **Mail**
4. Copy the 16-character password (e.g., `abcd efgh ijkl mnop`)
5. Use it as `SMTP_PASS` (without spaces)

## Step 6: Domain & DNS (Cloudflare — Free)

1. Add your domain to Cloudflare
2. Create DNS records:
   | Type | Name | Content | Proxy |
   |------|------|---------|-------|
   | CNAME | api | `medorder-api.onrender.com` | DNS only (grey cloud) |
   | A | app | *your frontend host* | Yes |
   | A | admin | *your frontend host* | Yes |
3. In Render → your web service → **Settings** → **Custom Domains** → Add `api.yourdomain.com`
4. Render handles SSL automatically

## Step 7: Initialize Database

After the first deploy, open Render **Shell** (your web service → Shell tab):

```bash
npx prisma db push
node dist/scripts/seed.js  # If you have a compiled seed script
```

Or use the Render deploy hook. Add a **Pre-Deploy Command** in your web service settings:
```
npx prisma db push --accept-data-loss=false
```

## Step 8: Render Blueprint (Optional — Infrastructure as Code)

The `render.yaml` file in the repo root lets you deploy everything with one click.

---

## Operations

### View logs
Render Dashboard → Your service → **Logs** tab

### Restart server
Render Dashboard → Your service → **Manual Deploy** → **Clear cache & deploy**

### Database access
```bash
# From Render Shell
npx prisma studio
```

### Backups
- **Free plan**: No automatic backups — set up pg_dump cron externally
- **Starter plan ($7/mo)**: Automatic daily backups included
- **Manual backup**: Render Shell → `pg_dump $DATABASE_URL | gzip > backup.sql.gz`

### Scaling
- Render auto-scales on paid plans
- Upgrade plan for more RAM/CPU as needed
- Add multiple instances for horizontal scaling (Starter+ plans)

---

## Cost Summary

| Service | Provider | Monthly |
|---------|----------|---------|
| API Server | Render Starter | $7.00 |
| PostgreSQL | Render Free / Starter | $0 - $7 |
| Redis | Render Free | $0 |
| Storage | Cloudflare R2 | $0 |
| Email | Gmail App Password | $0 |
| DNS + CDN + SSL | Cloudflare + Render | $0 |
| Monitoring | UptimeRobot | $0 |
| Domain | ~$12/year | ~$1 |
| **Total (minimum)** | | **~$8/mo** |
| **Total (with persistent DB)** | | **~$15/mo** |

### Free Tier Option (~$1/mo, domain only)
Use Render free tier for all services. Caveat: server spins down after 15 min of inactivity (cold start ~30s).
