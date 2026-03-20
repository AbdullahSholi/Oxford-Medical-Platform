# Contributing to MedOrder

## Git Workflow & Branch Strategy

```
main (production)
  └── develop (staging)
        ├── feature/auth-registration
        ├── feature/product-catalog
        ├── feature/order-flow
        ├── fix/cart-calculation-bug
        └── hotfix/stock-race-condition (→ main directly)
```

### Branch Naming

```
{type}/{description}
```

| Type | Usage |
|------|-------|
| `feature/` | New functionality |
| `fix/` | Bug fixes |
| `hotfix/` | Critical production fixes |
| `refactor/` | Code restructuring without behavior change |
| `chore/` | Tooling, dependencies, configs |

### Commit Format (Conventional Commits)

```
feat(auth): add OTP verification endpoint
fix(cart): correct bulk pricing calculation for edge case
refactor(product): extract search service from product service
chore(deps): update prisma to v5.10
test(order): add concurrent checkout race condition test
docs(api): update OpenAPI spec for discount endpoints
```

**Commit types:** `feat`, `fix`, `refactor`, `chore`, `test`, `docs`, `perf`, `ci`, `build`

**Scope examples:** `auth`, `cart`, `order`, `product`, `category`, `review`, `admin`, `db`, `config`, `deps`

### Pull Request Process

1. Create feature branch from `develop`
2. Write code and tests
3. Ensure `npx tsc --noEmit` passes with 0 errors
4. Ensure `npm run lint` passes
5. Ensure `npm test` passes (unit tests)
6. Ensure `npm run test:integration` passes (if applicable)
7. Open PR against `develop`
8. Request code review
9. Squash merge when approved

### Hotfix Process

1. Create `hotfix/` branch from `main`
2. Fix the issue with minimal changes
3. Open PR against `main`
4. After merge to `main`, cherry-pick to `develop`

---

## Development Setup

```bash
# Clone and install
git clone <repo-url>
cd server
npm install

# Set up environment
cp .env.example .env
# Edit .env with your local values

# Database setup
npm run db:bootstrap    # Prisma migrate + SQL scripts + seed

# Development server
npm run dev             # Hot-reload with tsx

# Type checking
npx tsc --noEmit

# Tests
npm test                # Unit tests
npm run test:integration # Integration tests (requires test DB)
```

---

## Code Standards

### TypeScript

- **Strict mode** enabled — no `any` unless explicitly justified
- **Path aliases** — use `@/`, `@config/`, `@shared/`, `@modules/`
- **Zod** for all request validation
- **Prisma** for database access — no raw SQL unless needed for locking

### Architecture

- **Layered**: routes → controllers → services → repositories
- **Manual DI**: instantiate and inject in route files
- **Error handling**: throw `AppError` subclasses, caught by global handler
- **Locking**: use `db-locks.ts` utilities for all pessimistic operations
- **Retry**: wrap deadlock-prone operations with `withDeadlockRetry()`

### Testing

| Layer | Test Type | Required |
|-------|-----------|----------|
| Services | Unit | ✅ All services |
| BLoCs | Unit | ✅ All BLoCs |
| Controllers | Integration | ✅ All endpoints |
| Concurrency | Race condition | ✅ All FOR UPDATE queries |

**Race condition tests are mandatory** for any operation using pessimistic locking.

---

## Environment Variables

See [`.env.example`](.env.example) for all required variables.

**Required for development:**
- `DATABASE_URL` — PostgreSQL connection string
- `JWT_ACCESS_SECRET` — At least 16 characters
- `JWT_REFRESH_SECRET` — At least 16 characters

**Optional for development:**
- `REDIS_URL` — Falls back to `redis://localhost:6379`
- `SENTRY_DSN` — Empty disables Sentry
- `S3_*` — Only needed for upload testing
