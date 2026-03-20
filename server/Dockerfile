# ═══════════════════════════════════════════════════════════
# MedOrder — Production Dockerfile
# Multi-stage build for minimal image size
# ═══════════════════════════════════════════════════════════

# ── Stage 1: Build ───────────────────────────────────────
FROM node:22-alpine AS builder

WORKDIR /app

# Copy dependency files first (better caching)
COPY package.json package-lock.json ./
COPY prisma ./prisma/

# Install all dependencies (including dev)
RUN npm ci

# Generate Prisma client
RUN npx prisma generate

# Copy source code
COPY tsconfig.json ./
COPY src ./src/

# Build TypeScript
RUN npm run build

# ── Stage 2: Production ─────────────────────────────────
FROM node:22-alpine AS production

WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S medorder && \
    adduser -S medorder -u 1001

# Copy dependency files
COPY package.json package-lock.json ./
COPY prisma ./prisma/

# Install production dependencies only + clean cache
RUN npm ci --omit=dev && npm cache clean --force

# Generate Prisma client
RUN npx prisma generate

# Copy built code from builder stage
COPY --from=builder /app/dist ./dist/

# Copy seed scripts (needed for initial setup)
COPY scripts ./scripts/

# Switch to non-root user
USER medorder

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:3000/api/v1/products?limit=1 || exit 1

# Start the server
CMD ["node", "dist/index.js"]
