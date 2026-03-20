# Oxford Medical Platform — Test Scenarios

**Total Scenarios: 1,000**
**Generated: 2026-03-14**

This document contains comprehensive test scenarios covering all system functionalities, edge cases, security flows, error handling, and cross-module interactions.

---

## Table of Contents

1. [Authentication & Authorization (SC-001 → SC-120)](#1-authentication--authorization)
2. [Doctor Profile & Addresses (SC-121 → SC-180)](#2-doctor-profile--addresses)
3. [Product Catalog & Browsing (SC-181 → SC-270)](#3-product-catalog--browsing)
4. [Search & Filtering (SC-271 → SC-340)](#4-search--filtering)
5. [Shopping Cart (SC-341 → SC-430)](#5-shopping-cart)
6. [Orders & Checkout (SC-431 → SC-560)](#6-orders--checkout)
7. [Reviews & Ratings (SC-561 → SC-620)](#7-reviews--ratings)
8. [Wishlist (SC-621 → SC-660)](#8-wishlist)
9. [Notifications (SC-661 → SC-710)](#9-notifications)
10. [Discounts & Promo Codes (SC-711 → SC-770)](#10-discounts--promo-codes)
11. [Flash Sales (SC-771 → SC-810)](#11-flash-sales)
12. [Banners (SC-811 → SC-850)](#12-banners)
13. [File Uploads & Storage (SC-851 → SC-890)](#13-file-uploads--storage)
14. [Admin Dashboard & Reports (SC-891 → SC-930)](#14-admin-dashboard--reports)
15. [Admin Doctor Management (SC-931 → SC-970)](#15-admin-doctor-management)
16. [Admin Product Management (SC-971 → SC-1000)](#16-admin-product--order-management)
17. [Localization & Accessibility (Appendix A)](#appendix-a-localization--accessibility)
18. [Performance & Concurrency (Appendix B)](#appendix-b-performance--concurrency)

---

## 1. Authentication & Authorization

### 1.1 Doctor Registration

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-001 | Register with valid full name, email, phone, password, clinic name, specialty, city, license image | Account created with status `pending`, welcome email sent, redirected to home |
| SC-002 | Register with email already used by another doctor | 409 Conflict — "Email already registered" |
| SC-003 | Register with phone already used by another doctor | 409 Conflict — "Phone already registered" |
| SC-004 | Register with invalid email format (e.g., "notanemail") | 400 — Zod validation: "Invalid email" |
| SC-005 | Register with password shorter than 8 characters | 400 — "Password must be at least 8 characters" |
| SC-006 | Register with password longer than 128 characters | 400 — "Password must be at most 128 characters" |
| SC-007 | Register with full name shorter than 3 characters | 400 — "Full name must be at least 3 characters" |
| SC-008 | Register with full name longer than 200 characters | 400 — Validation error |
| SC-009 | Register with invalid phone format (e.g., "12345") | 400 — "Invalid phone number" |
| SC-010 | Register with valid international phone (+201234567890) | Account created successfully |
| SC-011 | Register without providing optional fields (clinicName, specialty, city) | Account created with optional fields null |
| SC-012 | Register with clinic name shorter than 2 characters | 400 — Validation error |
| SC-013 | Register with clinic name longer than 300 characters | 400 — Validation error |
| SC-014 | Register with specialty shorter than 2 characters | 400 — Validation error |
| SC-015 | Register with license image upload (JPEG) | License uploaded to S3, URL stored in doctor record |
| SC-016 | Register with license image upload (PNG) | License uploaded successfully |
| SC-017 | Register with license image upload (WebP) | License uploaded successfully |
| SC-018 | Register with license PDF upload | License uploaded successfully |
| SC-019 | Register with license file exceeding 5MB | 400 — "File too large" |
| SC-020 | Register with unsupported file type (e.g., .exe, .txt) | 400 — "Invalid file type" |
| SC-021 | Register without uploading license file | Account created without license URL |
| SC-022 | Register with email containing leading/trailing whitespace | Whitespace trimmed, account created with clean email |
| SC-023 | Register with SQL injection attempt in email field | Sanitized by Zod, no SQL executed |
| SC-024 | Register with XSS attempt in full name field ("<script>alert(1)</script>") | HTML escaped/sanitized, stored safely |
| SC-025 | Register and verify welcome email is sent asynchronously | Registration completes immediately, email sent in background |
| SC-026 | Register when email service is down | Registration succeeds (email fire-and-forget), no error shown |
| SC-027 | Submit registration form with empty body | 400 — Multiple validation errors for required fields |
| SC-028 | Submit registration with Content-Type text/plain instead of JSON | 400 — Parse error |
| SC-029 | Register two accounts rapidly with same email (race condition) | First succeeds, second gets 409 (unique constraint) |
| SC-030 | Register with unicode characters in full name ("Dr. عمرو") | Account created with unicode name preserved |

### 1.2 Doctor Login

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-031 | Login with valid email and password (approved doctor) | 200 — Access token + refresh token returned, redirected to home |
| SC-032 | Login with valid email but wrong password | 401 — "Invalid credentials" |
| SC-033 | Login with non-existent email | 401 — "Invalid credentials" (no email enumeration) |
| SC-034 | Login with empty email field | 400 — Validation error |
| SC-035 | Login with empty password field | 400 — "Password must be at least 1 character" |
| SC-036 | Login with pending doctor status | 403 — "Account pending verification" |
| SC-037 | Login with rejected doctor status | 403 — "Account has been rejected" |
| SC-038 | Login with suspended doctor status | 403 — "Account has been suspended" |
| SC-039 | Login with email in different case ("DR.AHMAD@CLINIC.COM") | Login succeeds (case-insensitive match) |
| SC-040 | Login with email containing whitespace (" dr.ahmad@clinic.com ") | Whitespace trimmed, login succeeds |
| SC-041 | Login and verify access token contains correct sub, role, jti claims | Token decoded with valid claims |
| SC-042 | Login and verify refresh token is stored with hashed value in DB | RefreshToken record created with tokenHash |
| SC-043 | Login and verify cart is created if not exists | Cart record created for doctor |
| SC-044 | Login when doctor already has a cart | Existing cart preserved, no duplicate created |
| SC-045 | Login and verify lastLoginAt timestamp updated | Doctor.lastLoginAt set to current time |
| SC-046 | Attempt 6 logins within 15 minutes (rate limit = 5) | 6th request returns 429 — "Too many requests" |
| SC-047 | Wait 15 minutes after rate limit, then login | Login succeeds (rate limit window expired) |
| SC-048 | Login from rate-limited IP, then login from different IP | Different IP not rate-limited |
| SC-049 | Login with password containing special characters (!@#$%^&*) | Login succeeds if password matches |
| SC-050 | Login and verify response includes doctor profile data | Response contains fullName, email, specialty, status |

### 1.3 Admin Login

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-051 | Admin login with valid credentials | 200 — Access token (role=admin) + refresh token |
| SC-052 | Admin login with wrong password | 401 — "Invalid credentials" |
| SC-053 | Admin login with non-existent email | 401 — "Invalid credentials" |
| SC-054 | Admin login with inactive admin account | 401 — "Account is inactive" |
| SC-055 | Admin login and verify token role is "admin" | JWT contains role: "admin" |
| SC-056 | Admin login updates lastLoginAt | Admin.lastLoginAt updated |
| SC-057 | Admin login rate limited after 5 attempts | 429 on 6th attempt |
| SC-058 | Doctor credentials used on admin login endpoint | 401 — "Invalid credentials" (separate tables) |
| SC-059 | Admin credentials used on doctor login endpoint | 401 — "Invalid credentials" (separate tables) |
| SC-060 | Admin login with empty body | 400 — Validation errors |

### 1.4 Token Management

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-061 | Access API with valid access token | 200 — Request succeeds |
| SC-062 | Access API with expired access token | 401 — "Token expired" |
| SC-063 | Access API with malformed token ("not-a-jwt") | 401 — "Invalid token" |
| SC-064 | Access API with no Authorization header | 401 — "No token provided" |
| SC-065 | Access API with Authorization header but no Bearer prefix | 401 — "Invalid token format" |
| SC-066 | Refresh token with valid refresh token | 200 — New access token + new refresh token (rotation) |
| SC-067 | Refresh token with expired refresh token | 401 — "Refresh token expired" |
| SC-068 | Refresh token with revoked refresh token | 401 — "Token revoked" |
| SC-069 | Reuse old refresh token after rotation (token theft detection) | All tokens in family revoked |
| SC-070 | Refresh token with token from different user | 401 — Token mismatch |
| SC-071 | Access API with blacklisted (logged-out) access token | 401 — "Token revoked" |
| SC-072 | Verify token blacklist checked in Redis | Redis SISMEMBER called with token jti |
| SC-073 | Access doctor endpoint with admin token | 403 — "Insufficient permissions" |
| SC-074 | Access admin endpoint with doctor token | 403 — "Insufficient permissions" |
| SC-075 | Access public endpoint (GET /products) without token | 200 — Public access allowed |
| SC-076 | Access public endpoint (GET /banners) without token | 200 — Public access allowed |
| SC-077 | Access public endpoint (GET /categories) without token | 200 — Public access allowed |
| SC-078 | Access public endpoint (GET /brands) without token | 200 — Public access allowed |
| SC-079 | Access authenticated endpoint (POST /cart/items) without token | 401 |
| SC-080 | Token with tampered payload (modified sub claim) | 401 — Signature verification fails |

### 1.5 OTP & Password Reset

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-081 | Send OTP to registered email | 200 — OTP sent, stored in Redis with TTL |
| SC-082 | Send OTP to non-existent email | 200 — Same response (no email enumeration) |
| SC-083 | Send OTP with invalid email format | 400 — Validation error |
| SC-084 | Send OTP and verify 6-digit code generated | OTP is exactly 6 digits |
| SC-085 | Send OTP and verify expiry (default 300 seconds) | OTP expires after 5 minutes |
| SC-086 | Verify OTP with correct code | 200 — OTP verified |
| SC-087 | Verify OTP with incorrect code | 400 — "Invalid OTP" |
| SC-088 | Verify OTP after expiry | 400 — "OTP expired" |
| SC-089 | Verify OTP twice (replay) | Second attempt fails — OTP consumed |
| SC-090 | Reset password with valid email + OTP + new password | 200 — Password updated |
| SC-091 | Reset password with invalid OTP | 400 — "Invalid OTP" |
| SC-092 | Reset password with new password < 8 chars | 400 — Validation error |
| SC-093 | Reset password and login with new password | Login succeeds |
| SC-094 | Reset password and login with old password | 401 — "Invalid credentials" |
| SC-095 | Send multiple OTPs — only latest is valid | Previous OTPs invalidated |
| SC-096 | Send OTP rate limited (5 attempts in 15 min) | 429 on 6th attempt |
| SC-097 | Reset password for suspended account | Password resets but login still blocked by status |
| SC-098 | Reset password for pending account | Password resets, login blocked until approved |
| SC-099 | Send OTP with empty email field | 400 — Validation error |
| SC-100 | Verify OTP with OTP length ≠ 6 | 400 — "OTP must be exactly 6 characters" |

### 1.6 Logout

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-101 | Logout with valid token | 200 — Refresh token revoked, access token blacklisted |
| SC-102 | Logout and try to use same access token | 401 — "Token revoked" |
| SC-103 | Logout and try to use same refresh token | 401 — "Token revoked" |
| SC-104 | Logout without token | 401 — "No token provided" |
| SC-105 | Logout twice with same token | Second attempt fails gracefully |
| SC-106 | Logout and verify Redis blacklist entry created | Token jti added to Redis set |
| SC-107 | Logout from one device, other device tokens still valid | Only current session invalidated |
| SC-108 | Admin logout | Same flow — tokens revoked |
| SC-109 | Logout clears secure storage (Flutter client) | Tokens removed from FlutterSecureStorage |
| SC-110 | Logout redirects to login page (Flutter client) | GoRouter redirects to /auth/login |

### 1.7 Authorization & Role Enforcement

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-111 | Doctor accesses GET /admin/dashboard/stats | 403 — Forbidden |
| SC-112 | Doctor accesses POST /admin/products | 403 — Forbidden |
| SC-113 | Doctor accesses PATCH /admin/doctors/:id/approve | 403 — Forbidden |
| SC-114 | Admin accesses GET /doctors/me | Works if middleware allows admin role |
| SC-115 | Admin accesses POST /orders | 403 — Only doctor role allowed |
| SC-116 | Admin accesses GET /cart | 403 — Only doctor role allowed |
| SC-117 | Access protected route with expired token | 401 before role check |
| SC-118 | Doctor A accesses Doctor B's order detail | 404 or 403 — Ownership enforced |
| SC-119 | Doctor A deletes Doctor B's address | 404 — Address not found for this doctor |
| SC-120 | Doctor A deletes Doctor B's review | 403 or 404 — Ownership enforced |

---

## 2. Doctor Profile & Addresses

### 2.1 Profile Management

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-121 | Get own profile (GET /doctors/me) | 200 — Full profile with addresses |
| SC-122 | Update full name | 200 — Name updated |
| SC-123 | Update phone to valid number | 200 — Phone updated |
| SC-124 | Update phone to already-used number | 409 — "Phone already in use" |
| SC-125 | Update clinic name | 200 — Clinic name updated |
| SC-126 | Update specialty | 200 — Specialty updated |
| SC-127 | Update city | 200 — City updated |
| SC-128 | Update clinic address | 200 — Address updated |
| SC-129 | Update with empty full name | 400 — Validation error |
| SC-130 | Update with invalid phone format | 400 — Validation error |
| SC-131 | Update email (should not be allowed) | 400 or field ignored — Email immutable |
| SC-132 | Update password via profile endpoint (should use reset flow) | 400 — Not supported |
| SC-133 | Get profile of unauthenticated user | 401 |
| SC-134 | Update profile with unicode characters | 200 — Unicode preserved |
| SC-135 | Update profile with very long clinic address (>1000 chars) | Stored in text field, no truncation |
| SC-136 | Get profile includes doctor status | Status field present (pending/approved/rejected/suspended) |
| SC-137 | Get profile includes avatar URL if set | avatarUrl included when present |
| SC-138 | Update profile with XSS in clinic name | Sanitized/escaped on output |
| SC-139 | Profile shows license URL | licenseUrl present in response |
| SC-140 | Profile shows approval date if approved | approvedAt present for approved doctors |

### 2.2 Delivery Addresses

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-141 | Get all addresses for authenticated doctor | 200 — Array of addresses |
| SC-142 | Create address with all fields (label, recipientName, phone, city, streetAddress, buildingInfo, landmark, lat, lng) | 201 — Address created |
| SC-143 | Create address with only required fields | 201 — Optional fields null |
| SC-144 | Create address with label "home" | Address labeled "home" |
| SC-145 | Create address with label "office" | Address labeled "office" |
| SC-146 | Create address with isDefault = true | New address set as default, previous default unset |
| SC-147 | Create first address — auto-set as default | First address becomes default |
| SC-148 | Create address with invalid phone | 400 — Validation error |
| SC-149 | Create address with empty city | 400 — Validation error |
| SC-150 | Create address with empty streetAddress | 400 — Validation error |
| SC-151 | Update address label from "home" to "clinic" | 200 — Label updated |
| SC-152 | Update address city | 200 — City updated |
| SC-153 | Update address and set as new default | Previous default unset, this one set |
| SC-154 | Update address that belongs to another doctor | 404 — Not found |
| SC-155 | Delete address | 204 — Address removed |
| SC-156 | Delete default address when other addresses exist | Another address becomes default |
| SC-157 | Delete only address | 204 — No addresses remain |
| SC-158 | Delete address that belongs to another doctor | 404 — Not found |
| SC-159 | Delete address referenced by existing order | Address deleted (order has snapshot) |
| SC-160 | Create address with latitude/longitude | Coordinates stored as decimals |
| SC-161 | Create address with latitude out of range (-91) | 400 — Validation error |
| SC-162 | Create address with longitude out of range (181) | 400 — Validation error |
| SC-163 | Get addresses when doctor has 0 addresses | 200 — Empty array |
| SC-164 | Create 10 addresses for same doctor | All created, no limit error |
| SC-165 | Update address recipientName | 200 — Name updated |
| SC-166 | Create address with very long streetAddress | Text field accepts long values |
| SC-167 | Create address with landmark containing special characters | Stored correctly |
| SC-168 | Delete non-existent address ID | 404 — Not found |
| SC-169 | Create address with buildingInfo "Floor 3, Apt 5B" | Stored correctly |
| SC-170 | Get addresses sorted by creation date | Addresses returned in order |
| SC-171 | Create address without authentication | 401 |
| SC-172 | Update address without authentication | 401 |
| SC-173 | Delete address without authentication | 401 |
| SC-174 | Create address with SQL injection in city field | Parameterized query prevents injection |
| SC-175 | Create address with empty body | 400 — Multiple validation errors |
| SC-176 | Update only buildingInfo field (partial update) | Only that field changes |
| SC-177 | Create address with recipientName > 200 chars | 400 — Validation error |
| SC-178 | Create address with label > 50 chars | 400 — Validation error |
| SC-179 | Create address with phone in local format (01234567890) | Depends on regex validation |
| SC-180 | Verify address used in order is snapshot, not reference | Order deliveryAddress is JSONB copy |

---

## 3. Product Catalog & Browsing

### 3.1 List Products

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-181 | GET /products with no params | 200 — First 20 active products, sorted by totalSold DESC |
| SC-182 | GET /products?page=1&limit=10 | 200 — 10 products, meta shows page=1 |
| SC-183 | GET /products?page=2&limit=10 | 200 — Next 10 products |
| SC-184 | GET /products?page=999 | 200 — Empty data array, meta.total correct |
| SC-185 | GET /products?limit=0 | 400 or defaults to 1 (clamped) |
| SC-186 | GET /products?limit=200 | Clamped to 100 max |
| SC-187 | GET /products?limit=-5 | Clamped to 1 min |
| SC-188 | GET /products?categoryId=valid-uuid | 200 — Only products in that category |
| SC-189 | GET /products?categoryId=invalid-uuid | 400 or empty results |
| SC-190 | GET /products?brandId=valid-uuid | 200 — Only products of that brand |
| SC-191 | GET /products?minPrice=10&maxPrice=50 | 200 — Products with price between 10-50 |
| SC-192 | GET /products?minPrice=50&maxPrice=10 | 200 — Empty results (min > max) |
| SC-193 | GET /products?minPrice=-1 | 400 or ignored |
| SC-194 | GET /products?inStock=true | 200 — Only products with stock > 0 |
| SC-195 | GET /products?search=gloves | 200 — Full-text search results |
| SC-196 | GET /products with multiple filters combined | All filters applied with AND logic |
| SC-197 | Verify response includes product images | Each product has images array |
| SC-198 | Verify response includes category name | Category name joined in response |
| SC-199 | Verify response includes brand name | Brand name present if brandId set |
| SC-200 | Verify inactive products not returned | isActive=false products excluded |
| SC-201 | Verify meta includes total, page, limit, totalPages | All meta fields present |
| SC-202 | GET /products without authentication (public) | 200 — Works without token |
| SC-203 | Verify products with salePrice show both prices | price and salePrice both present |
| SC-204 | Verify products show avgRating and reviewCount | Aggregate fields present |
| SC-205 | Verify products show totalSold | totalSold field present |
| SC-206 | GET /products?categoryId=x&brandId=y&minPrice=10&maxPrice=50&inStock=true | All filters applied simultaneously |

### 3.2 Product Detail

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-207 | GET /products/:id with valid product ID | 200 — Full product detail |
| SC-208 | GET /products/:id with non-existent ID | 404 — "Product not found" |
| SC-209 | GET /products/:id with invalid UUID format | 400 — "Invalid ID format" |
| SC-210 | Verify product detail includes all images sorted by sortOrder | Images array ordered |
| SC-211 | Verify product detail includes primary image flag | isPrimary=true on main image |
| SC-212 | Verify product detail includes bulk pricing tiers | bulkPricing array with minQty, maxQty, unitPrice |
| SC-213 | Verify product detail includes medicalDetails (JSONB) | Parsed JSON object returned |
| SC-214 | Verify product detail includes stock count | stock field present |
| SC-215 | Verify product detail includes lowStockThreshold | Threshold value present |
| SC-216 | Verify product detail includes minOrderQty | Minimum order quantity present |
| SC-217 | Verify product detail includes category info | Category name, id present |
| SC-218 | Verify product detail includes brand info | Brand name, id, logo present |
| SC-219 | Verify product detail includes SKU | SKU field present |
| SC-220 | Verify product detail includes slug | Slug field present |
| SC-221 | GET /products/:id for inactive product | 404 — Hidden from public |
| SC-222 | Verify product detail includes createdAt | Timestamp present |
| SC-223 | Product with sale price shows discount percentage | Calculated from price vs salePrice |
| SC-224 | Product with no sale price | salePrice is null |
| SC-225 | Product with stock = 0 | Shows "Out of Stock" indicator |
| SC-226 | Product with stock = 1 | Shows "Low Stock" or stock count |

### 3.3 Product Reviews (Public)

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-227 | GET /products/:id/reviews | 200 — Paginated reviews |
| SC-228 | GET /products/:id/reviews?page=1&limit=5 | 200 — 5 reviews max |
| SC-229 | Reviews sorted by newest first | createdAt DESC |
| SC-230 | Review includes doctor name (not email) | Privacy — only name shown |
| SC-231 | Review includes rating (1-5) | Integer rating present |
| SC-232 | Review includes title and body | Text fields present |
| SC-233 | Review includes isVerified flag | Verified purchase indicator |
| SC-234 | Review includes helpfulCount | Count present |
| SC-235 | GET reviews for product with no reviews | 200 — Empty array |
| SC-236 | Hidden reviews (isVisible=false) not returned | Filtered out in public API |

### 3.4 Categories

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-237 | GET /categories | 200 — All active top-level categories |
| SC-238 | Categories include name, slug, iconUrl | All fields present |
| SC-239 | Categories sorted by sortOrder | Ordered correctly |
| SC-240 | Inactive categories not returned | isActive=false excluded |
| SC-241 | Categories include child categories | Children array present |
| SC-242 | GET /categories/:id/products | 200 — Products in category |
| SC-243 | GET /categories/:id/products with pagination | Paginated results |
| SC-244 | GET /categories for non-existent category ID | 404 |
| SC-245 | Categories accessible without authentication | Public endpoint |
| SC-246 | Category hierarchy: parent → child → products | Three-level navigation works |
| SC-247 | Category with no products | 200 — Empty products array |
| SC-248 | Category with 100+ products | Pagination works correctly |
| SC-249 | Category slug is URL-friendly | No spaces or special chars |
| SC-250 | Verify category description field | Description present when set |

### 3.5 Brands

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-251 | GET /brands | 200 — All active brands |
| SC-252 | Brands include name, slug, logoUrl | All fields present |
| SC-253 | Inactive brands not returned | isActive=false excluded |
| SC-254 | Brands accessible without authentication | Public endpoint |
| SC-255 | Brand with no products | Brand still listed |
| SC-256 | Brand slug is URL-friendly | Clean slug format |
| SC-257 | Verify brand description field | Description present when set |
| SC-258 | Brand logoUrl is valid URL or null | URL format or null |
| SC-259 | Brands sorted alphabetically or by creation | Consistent ordering |
| SC-260 | Filter products by brand in product listing | brandId filter works |

### 3.6 Product Display (Flutter Client)

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-261 | Home screen shows category chips horizontally scrollable | Categories in horizontal list |
| SC-262 | Home screen shows "Best Sellers" section | Products sorted by totalSold |
| SC-263 | Product card shows name, price, sale price, image | All info visible |
| SC-264 | Product card shows "Add to Cart" quick button | Heart/cart icon present |
| SC-265 | Tap product card navigates to detail page | Navigation works |
| SC-266 | Product detail page has Description tab | Tab content shows |
| SC-267 | Product detail page has Medical Information tab | medicalDetails rendered |
| SC-268 | Product detail page has Reviews tab | Reviews list rendered |
| SC-269 | Product images swipeable in detail | Image carousel works |
| SC-270 | "View All" button on home navigates to full product list | Navigation to categories |

---

## 4. Search & Filtering

### 4.1 Full-Text Search (PostgreSQL TSVECTOR)

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-271 | Search "surgical gloves" | Returns products matching both terms |
| SC-272 | Search "glove" (singular) | Prefix matching returns "gloves" results |
| SC-273 | Search "SURGICAL" (uppercase) | Case-insensitive, returns results |
| SC-274 | Search with special characters "gloves!@#" | Special chars stripped, "gloves" searched |
| SC-275 | Search empty string | Returns all products (no FTS filter) |
| SC-276 | Search whitespace-only string | Returns all products |
| SC-277 | Search with "or" keyword: "gloves or masks" | OR logic in tsquery |
| SC-278 | Search with multiple words: "sterile surgical" | AND logic: both terms required |
| SC-279 | Search non-existent term "xyznonexistent" | FTS returns 0, triggers trigram fallback |
| SC-280 | Search with typo "glovs" (trigram fallback) | Fuzzy match returns "gloves" results (similarity > 0.2) |
| SC-281 | Search with 1-2 char query | No trigram fallback (length check > 2) |
| SC-282 | Search results include relevance score | ts_rank value present |
| SC-283 | Search results include highlighted snippets | ts_headline present |
| SC-284 | Search results sorted by relevance then totalSold | Correct ordering |
| SC-285 | Search via GET /products/search?q=gloves | Same results as filtered products |
| SC-286 | Search with SQL injection attempt "'; DROP TABLE products;--" | Sanitized by toTsQuery, no SQL executed |
| SC-287 | Search with very long query (500 chars) | Processed without error, sanitized |
| SC-288 | Search with only special characters "!@#$%^" | All stripped, returns null tsquery, all products |
| SC-289 | Search "blood pressure monitor" (3 words) | All three terms matched with AND |
| SC-290 | Search with debounce on Flutter client (500ms) | API called after 500ms of no typing |

### 4.2 Trigram Fuzzy Search

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-291 | Trigram search "panadl" (typo for "panadol") | Returns "Panadol" products (similarity > 0.2) |
| SC-292 | Trigram search "strilize" (typo for "sterilize") | Fuzzy match returns results |
| SC-293 | Trigram search with ILIKE fallback | Products matched by name ILIKE '%query%' |
| SC-294 | Trigram search results sorted by similarity DESC | Most similar first |
| SC-295 | Trigram meta includes fuzzy: true flag | Client knows results are fuzzy |
| SC-296 | Trigram search pagination | Approximate pagination with limit/offset |
| SC-297 | Trigram search with no matches (similarity < 0.2) | Empty results |
| SC-298 | Trigram search only activated when FTS returns 0 | Fallback mechanism works |
| SC-299 | Search parameters (limit, offset) are parameterized | No SQL injection via limit/offset |
| SC-300 | Search with page parameter bounds (Math.max/Math.min) | Page clamped to valid range |

### 4.3 Product Filters (Flutter Client)

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-301 | Open filter sheet from categories page | Filter dialog slides up |
| SC-302 | Filter by single category "Surgical Supplies" | Only surgical products shown |
| SC-303 | Filter by single category "Diagnostic Equipment" | Only diagnostic products shown |
| SC-304 | Filter by brand "MEDIGRIP" | Only MEDIGRIP products shown |
| SC-305 | Filter by brand "Medline" | Only Medline products shown |
| SC-306 | Filter by brand "SurgiCare" | Only SurgiCare products shown |
| SC-307 | Filter by price range EGP 0 - EGP 50 | Products within range |
| SC-308 | Filter by price range EGP 50 - EGP 100 | Products within range |
| SC-309 | Toggle "In Stock Only" ON | Out-of-stock products hidden |
| SC-310 | Toggle "In Stock Only" OFF | All products shown |
| SC-311 | Combine category + brand filter | Intersection of both filters |
| SC-312 | Combine category + price range filter | Both filters applied |
| SC-313 | Combine all filters simultaneously | All criteria applied with AND |
| SC-314 | Apply filters and verify API call includes params | Query string has all filter params |
| SC-315 | Reset filters via "Reset" button | All filters cleared, all products shown |
| SC-316 | Apply filters → navigate away → come back | Filters reset (no persistence) |
| SC-317 | Price range slider minimum = maximum | Shows products at exact price |
| SC-318 | Price range slider at extremes (0 to 10000) | All products in range |
| SC-319 | Filter results empty (no matching products) | "No products found" message |
| SC-320 | Filter by category "All" | No category filter applied |
| SC-321 | Filter by brand "All" | No brand filter applied |
| SC-322 | Verify filter counts update | Number of results visible |
| SC-323 | Filter + search combination | Both applied |
| SC-324 | Filter with pagination (more results than page size) | Pagination works with filters |
| SC-325 | Sort products by price ascending | Products ordered low to high |
| SC-326 | Sort products by price descending | Products ordered high to low |
| SC-327 | Sort products by newest first | createdAt DESC |
| SC-328 | Sort products by rating | avgRating DESC |
| SC-329 | Sort products by most sold | totalSold DESC (default) |
| SC-330 | Filter inactive products excluded | isActive=false never shown |
| SC-331 | Filter by category with subcategories | Include child category products |
| SC-332 | Price slider handles decimal prices | EGP 38.50 within range 30-40 |
| SC-333 | Filter works on Categories tab | Filters apply to current view |
| SC-334 | Filter dialog accessible via filter icon | Icon in app bar triggers dialog |
| SC-335 | "Apply Filters" button closes dialog and refreshes list | Dialog dismissed, list updated |
| SC-336 | Filter by price 0-0 | Shows free products or empty |
| SC-337 | Multiple rapid filter changes | Only final state applied (no race) |
| SC-338 | Filter results show product count | Total count visible |
| SC-339 | Clear individual filter (deselect category) | Only that filter removed |
| SC-340 | Filter persists while scrolling results | Scroll doesn't reset filters |

---

## 5. Shopping Cart

### 5.1 Add to Cart

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-341 | Add product to empty cart | 201 — CartItem created, quantity=1 |
| SC-342 | Add same product again | Quantity incremented (1→2) |
| SC-343 | Add different product | New CartItem created |
| SC-344 | Add product with specific quantity=5 | CartItem quantity=5 |
| SC-345 | Add product with quantity=0 | 400 — Invalid quantity |
| SC-346 | Add product with negative quantity | 400 — Invalid quantity |
| SC-347 | Add product with quantity exceeding stock | 400 — "Insufficient stock" |
| SC-348 | Add out-of-stock product (stock=0) | 400 — "Product out of stock" |
| SC-349 | Add inactive product | 404 or 400 — "Product not found" |
| SC-350 | Add non-existent product ID | 404 — "Product not found" |
| SC-351 | Add product without authentication | 401 |
| SC-352 | Verify cart auto-created on first add | Cart record created for doctor |
| SC-353 | Add product and verify subtotal updates | Cart total recalculated |
| SC-354 | Add product with sale price — uses sale price | salePrice used in cart total |
| SC-355 | Add product and verify "Added to cart" toast (Flutter) | Snackbar appears |
| SC-356 | Add product from product detail page | "Add to Cart" button works |
| SC-357 | Add product from product card quick-add button | Quick-add icon works |
| SC-358 | Cart badge counter updates after add | Badge shows item count |
| SC-359 | Add 50 different products to cart | All added, no limit hit |
| SC-360 | Add product during flash sale — flash price used | Flash sale price applied |

### 5.2 View Cart

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-361 | GET /cart with items | 200 — Items with product details, prices, quantities |
| SC-362 | GET /cart with empty cart | 200 — Empty items array |
| SC-363 | Cart shows product name, image, price per item | All info present |
| SC-364 | Cart shows quantity per item | Quantity displayed |
| SC-365 | Cart shows line total (price × quantity) | Calculated correctly |
| SC-366 | Cart shows subtotal (sum of all line totals) | Sum calculated |
| SC-367 | Cart with bulk pricing applied | Lower unit price for qualifying quantities |
| SC-368 | Cart reflects current product prices (not cached) | Latest price from DB |
| SC-369 | Cart shows "Apply Coupon" field | Input + Apply button visible |
| SC-370 | Cart shows "Proceed to Checkout" button | Button visible when items exist |
| SC-371 | Empty cart shows "Your cart is empty" | Empty state message |
| SC-372 | Empty cart hides checkout button | Button not visible |
| SC-373 | Cart accessible via bottom navigation Cart tab | Tab navigates to /cart |
| SC-374 | Cart shows delivery fee preview | Delivery amount shown |
| SC-375 | Cart shows total (subtotal + delivery - discount) | Total calculated |

### 5.3 Update Cart Quantity

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-376 | PATCH /cart/items/:productId with quantity=3 | 200 — Quantity updated to 3 |
| SC-377 | Increment quantity with "+" button | Quantity increases by 1 |
| SC-378 | Decrement quantity with "-" button | Quantity decreases by 1 |
| SC-379 | Decrement quantity to 0 | Item removed from cart |
| SC-380 | Update quantity to value exceeding stock | 400 — "Insufficient stock" |
| SC-381 | Update quantity with non-numeric value | 400 — Validation error |
| SC-382 | Update quantity for non-existent cart item | 404 — "Item not in cart" |
| SC-383 | Update quantity and verify subtotal recalculates | New total shown |
| SC-384 | Update quantity triggers bulk pricing recalculation | New unit price if tier changes |
| SC-385 | Update quantity without authentication | 401 |
| SC-386 | Update quantity of another doctor's cart item | 404 — Not found |
| SC-387 | Rapid +/- clicks (debounce behavior) | Final quantity reflected |
| SC-388 | Update quantity to 1000 (very large) | Validates against stock |
| SC-389 | Update quantity with pessimistic lock | Row locked during update |
| SC-390 | Cart total updates in real-time on UI | Total recalculates visually |

### 5.4 Remove from Cart

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-391 | DELETE /cart/items/:productId | 204 — Item removed |
| SC-392 | Remove last item from cart | Cart empty but not deleted |
| SC-393 | Remove item and verify cart badge updates | Badge decrements |
| SC-394 | Remove item and verify subtotal updates | Total recalculated |
| SC-395 | Remove non-existent cart item | 404 — "Item not in cart" |
| SC-396 | Remove item without authentication | 401 |
| SC-397 | Remove item from another doctor's cart | 404 |
| SC-398 | Swipe to delete on Flutter client | Swipe gesture triggers delete |
| SC-399 | Delete icon on cart item (Flutter) | Trash icon triggers delete |
| SC-400 | Remove all items one by one | Cart becomes empty |

### 5.5 Clear Cart

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-401 | DELETE /cart (clear all items) | 204 — All items removed |
| SC-402 | Clear already empty cart | 204 — No error |
| SC-403 | Clear cart without authentication | 401 |
| SC-404 | Clear cart and verify badge shows 0 | Badge cleared |
| SC-405 | Cart cleared automatically after order placed | Cart empty after POST /orders |

### 5.6 Cart Edge Cases & Concurrency

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-406 | Product price changes after adding to cart | Cart reflects new price on next GET |
| SC-407 | Product goes out of stock after adding to cart | Warning shown at checkout |
| SC-408 | Product deactivated after adding to cart | Item removed or warning at checkout |
| SC-409 | Two tabs add same product simultaneously | Quantity incremented correctly (no race) |
| SC-410 | Cart persists across login/logout | Cart data persists in DB |
| SC-411 | Cart data matches between API and Flutter UI | No discrepancy |
| SC-412 | Product with bulk pricing tier 1: 1-9 units at $10 | $10 unit price for qty 5 |
| SC-413 | Product with bulk pricing tier 2: 10-49 units at $8 | $8 unit price for qty 15 |
| SC-414 | Product with bulk pricing tier 3: 50+ units at $6 | $6 unit price for qty 50 |
| SC-415 | Crossing bulk pricing threshold updates unit price | Price changes when qty changes tier |
| SC-416 | Cart item for product with minOrderQty=5 and qty=3 | Warning — below minimum |
| SC-417 | Add product during checkout (cart locked) | Fails or queues (pessimistic lock) |
| SC-418 | Multiple doctors add same product simultaneously | Each doctor's cart independent |
| SC-419 | Cart item with product that has no images | Placeholder image shown |
| SC-420 | Cart preserves items after app restart | Data persisted server-side |
| SC-421 | Cart with 0 total (all items free or removed) | Checkout blocked or shows $0 |
| SC-422 | Add product with sale price, then sale ends | Next cart view shows regular price |
| SC-423 | Product stock reduced to below cart quantity by another order | Stock warning at checkout |
| SC-424 | Cart shows correct currency format (EGP) | Currency prefix on all prices |
| SC-425 | Cart handles decimal prices correctly | EGP 38.50 displayed properly |
| SC-426 | Cart pagination if many items (>20) | Scrollable list |
| SC-427 | Cart item quantity display (e.g., "×3") | Quantity clearly shown |
| SC-428 | Re-add removed item to cart | Works normally |
| SC-429 | Cart subtotal with mix of regular and sale prices | Both prices used correctly |
| SC-430 | Add to cart with network timeout | Retry or error shown |

---

## 6. Orders & Checkout

### 6.1 Create Order

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-431 | Place order with cash on delivery, valid address, items in cart | 201 — Order created, cart cleared |
| SC-432 | Place order with empty cart | 400 — "Cart is empty" |
| SC-433 | Place order without authentication | 401 |
| SC-434 | Place order with non-existent delivery address ID | 400 — "Invalid delivery address" |
| SC-435 | Place order with address belonging to another doctor | 400 — "Address not found" |
| SC-436 | Place order when product stock insufficient | 400 — "Insufficient stock for [product]" |
| SC-437 | Place order and verify stock decremented | Product stock reduced by order qty |
| SC-438 | Place order and verify order number generated | Unique orderNumber like "MO260300XX" |
| SC-439 | Place order and verify status = "pending" | Initial status is pending |
| SC-440 | Place order and verify order items snapshot product data | OrderItem has productName, productSku, unitPrice |
| SC-441 | Place order and verify delivery address snapshot | Order.deliveryAddress is JSONB copy |
| SC-442 | Place order with valid discount code | Discount applied, discountAmount calculated |
| SC-443 | Place order with invalid discount code | 400 — "Invalid discount code" |
| SC-444 | Place order with expired discount code | 400 — "Discount has expired" |
| SC-445 | Place order with discount code usage limit reached | 400 — "Discount usage limit exceeded" |
| SC-446 | Place order with discount code per-user limit reached | 400 — "You have already used this code" |
| SC-447 | Place order with percentage discount (20%) | Discount = subtotal × 0.20, capped by maxDiscount |
| SC-448 | Place order with fixed discount ($10) | Discount = $10 |
| SC-449 | Place order with discount below minOrderAmount | 400 — "Order does not meet minimum amount" |
| SC-450 | Place order with discount maxDiscount cap | Percentage discount capped |
| SC-451 | Place order and verify delivery fee calculated | deliveryFee added to total |
| SC-452 | Place order total = subtotal - discount + deliveryFee | Math correct |
| SC-453 | Place order and verify confirmation email sent | Email with order details sent async |
| SC-454 | Place order and verify notification created | "Order Confirmed" notification for doctor |
| SC-455 | Place order and verify cart cleared | GET /cart returns empty |
| SC-456 | Place order and verify it appears in order history | GET /orders includes new order |
| SC-457 | Place order with notes field | Notes stored in order |
| SC-458 | Place two orders rapidly (race condition) | First succeeds, second fails on stock if insufficient |
| SC-459 | Place order with pessimistic locking | Cart and product rows locked during checkout |
| SC-460 | Place order deadlock prevention | Product IDs sorted before locking |
| SC-461 | Place order with products from multiple categories | All items included in single order |
| SC-462 | Place order with 1 item | Order created with single OrderItem |
| SC-463 | Place order with 20 items | Order created with all items |
| SC-464 | Place order and verify OrderStatusHistory entry created | "pending" status entry with timestamp |
| SC-465 | Place order with discount that has scope restriction | Only applicable products get discount |
| SC-466 | Place order creates DiscountUsage record | Usage tracked per doctor per discount |
| SC-467 | Place order and verify Discount.usedCount incremented | Global usage counter increased |
| SC-468 | Place order with payment method COD | paymentMethod = "cod", isPaid = false |
| SC-469 | Place order success screen shows order number | "Order #MO260300XX" displayed |
| SC-470 | Place order success screen shows "Track Order" button | Button navigates to tracking |

### 6.2 Order History

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-471 | GET /orders (doctor's orders) | 200 — Paginated list |
| SC-472 | Orders sorted by createdAt DESC | Newest first |
| SC-473 | Orders include orderNumber, status, total, itemCount, date | All fields present |
| SC-474 | Filter orders by status "pending" | Only pending orders |
| SC-475 | Filter orders by status "delivered" | Only delivered orders |
| SC-476 | Filter orders by status "cancelled" | Only cancelled orders |
| SC-477 | Filter orders by status "active" (pending+confirmed+processing+shipped) | Multiple statuses included |
| SC-478 | Orders tab in bottom navigation | Navigates to /orders |
| SC-479 | "All" tab shows all orders | No status filter |
| SC-480 | "Active" tab shows non-terminal orders | Excludes delivered, cancelled |
| SC-481 | "Delivered" tab shows delivered orders | Only delivered |
| SC-482 | "Cancelled" tab shows cancelled orders | Only cancelled |
| SC-483 | Tap order card navigates to order detail | Detail page loads |
| SC-484 | Order pagination works | Page 2 loads correctly |
| SC-485 | Doctor A cannot see Doctor B's orders | Filtered by doctorId |

### 6.3 Order Detail

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-486 | GET /orders/:id | 200 — Full order detail |
| SC-487 | Order detail shows all items with quantities and prices | OrderItems listed |
| SC-488 | Order detail shows delivery address | JSONB address displayed |
| SC-489 | Order detail shows payment method | "Cash on Delivery" |
| SC-490 | Order detail shows discount if applied | Discount amount shown |
| SC-491 | Order detail shows subtotal, delivery fee, total | All financial fields |
| SC-492 | Order detail shows status timeline | Status progression rendered |
| SC-493 | Order detail shows admin notes if any | Notes visible |
| SC-494 | GET /orders/:id for non-existent order | 404 |
| SC-495 | GET /orders/:id for another doctor's order | 404 (ownership enforced) |
| SC-496 | Order detail shows "Re-Order" for delivered orders | Button visible |
| SC-497 | Order detail shows "Cancel" for pending orders | Button visible |
| SC-498 | Order detail hides "Cancel" for shipped orders | Button not visible |

### 6.4 Order Tracking

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-499 | GET /orders/:id/tracking | 200 — Status history array |
| SC-500 | Tracking shows all status transitions with timestamps | History entries present |
| SC-501 | Tracking shows notes for each transition | Admin notes visible |
| SC-502 | Tracking shows current status highlighted | Active step marked |
| SC-503 | Tracking timeline: Pending → Confirmed → Processing → Shipped → Delivered | Full lifecycle |
| SC-504 | Real-time status update via WebSocket | Push notification received |
| SC-505 | Tracking for cancelled order shows cancellation | Cancelled step with reason |

### 6.5 Cancel Order

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-506 | POST /orders/:id/cancel for pending order | 200 — Status changed to cancelled |
| SC-507 | Cancel order with reason "Changed my mind" | cancelReason stored |
| SC-508 | Cancel order and verify stock returned | Product stock incremented back |
| SC-509 | Cancel order and verify cancelledAt timestamp set | Timestamp recorded |
| SC-510 | Cancel confirmed order | 200 — Cancellable status |
| SC-511 | Cancel processing order | 200 or 400 depending on business rule |
| SC-512 | Cancel shipped order | 400 — "Cannot cancel shipped order" |
| SC-513 | Cancel delivered order | 400 — "Cannot cancel delivered order" |
| SC-514 | Cancel already cancelled order | 400 — "Order already cancelled" |
| SC-515 | Cancel order without authentication | 401 |
| SC-516 | Cancel another doctor's order | 404 or 403 |
| SC-517 | Cancel order and verify notification created | Cancellation notification |
| SC-518 | Cancel order with discount — discount usage decremented | usedCount reduced |

### 6.6 Reorder

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-519 | Reorder from delivered order | Items added to cart with same quantities |
| SC-520 | Reorder when product no longer exists | Skip unavailable products, add available ones |
| SC-521 | Reorder when product out of stock | Warning about unavailable items |
| SC-522 | Reorder adds to existing cart items | Quantities merged/added |
| SC-523 | Reorder and verify "X item(s) added to cart" toast | Snackbar shows count |
| SC-524 | Reorder navigates to cart page | Cart tab activated |
| SC-525 | Reorder from pending order | Button not visible (only delivered) |
| SC-526 | Reorder preserves product quantities from original order | Same quantities |
| SC-527 | Reorder with modified quantities before checkout | User can edit cart |
| SC-528 | Reorder same order multiple times | Works each time |

### 6.7 Order Status Workflow (Admin)

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-529 | Admin updates order pending → confirmed | Status updated, notification sent |
| SC-530 | Admin updates order confirmed → processing | Valid transition |
| SC-531 | Admin updates order processing → shipped | Valid transition |
| SC-532 | Admin updates order shipped → out_for_delivery | Valid transition |
| SC-533 | Admin updates order out_for_delivery → delivered | Valid transition, isPaid=true for COD |
| SC-534 | Admin updates order pending → delivered (skip steps) | May be allowed or blocked |
| SC-535 | Admin updates order delivered → pending (reverse) | 400 — Invalid transition |
| SC-536 | Admin updates order cancelled → confirmed | 400 — Cannot reactivate |
| SC-537 | Admin adds notes to status update | Notes stored in OrderStatusHistory |
| SC-538 | Status update creates OrderStatusHistory entry | History entry with changedBy, timestamp |
| SC-539 | Each status update sends notification to doctor | Doctor receives notification |
| SC-540 | Status update sends email notification | Email sent async |
| SC-541 | Admin views order detail with all items | Full order info visible |
| SC-542 | Admin views all orders with pagination | GET /admin/orders paginated |
| SC-543 | Admin filters orders by status | Status filter works |
| SC-544 | Admin searches orders by order number | Search works |

### 6.8 Order Edge Cases

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-545 | Place order with product at minOrderQty | Validates minimum quantity |
| SC-546 | Place order with product exactly at stock limit | Succeeds, stock becomes 0 |
| SC-547 | Two doctors order last item simultaneously | One succeeds, one gets stock error |
| SC-548 | Order with 0 delivery fee (above threshold) | deliveryFee = 0 |
| SC-549 | Order with delivery fee applied | deliveryFee > 0 |
| SC-550 | Order total with all calculations: subtotal - discount + delivery | Math verified |
| SC-551 | Very large order (50+ items, high value) | Handles without timeout |
| SC-552 | Order with product that has costPrice set | costPrice not exposed to doctor |
| SC-553 | Order number unique across system | No duplicate orderNumbers |
| SC-554 | Order preserves product image URL in snapshot | productImage stored in OrderItem |
| SC-555 | Order with discount scope = specific category | Only matching items discounted |
| SC-556 | Order with discount scope = all | All items discounted |
| SC-557 | Checkout transaction timeout (15s) | Transaction rolls back |
| SC-558 | Checkout with stale cart data (price changed mid-checkout) | Uses current prices |
| SC-559 | Order created with correct createdAt timestamp | Server timestamp, not client |
| SC-560 | Order items sum matches order subtotal | No rounding errors |

---

## 7. Reviews & Ratings

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-561 | Create review with rating=5 and text | 201 — Review created |
| SC-562 | Create review with rating=1 | Valid rating accepted |
| SC-563 | Create review with rating=0 | 400 — "Rating must be 1-5" |
| SC-564 | Create review with rating=6 | 400 — "Rating must be 1-5" |
| SC-565 | Create review with negative rating | 400 — Validation error |
| SC-566 | Create review without text (rating only) | 201 — Body optional |
| SC-567 | Create review with title and body | Both stored |
| SC-568 | Create review for product already reviewed by same doctor | 409 — "Already reviewed" |
| SC-569 | Create review for non-existent product | 404 |
| SC-570 | Create review for product doctor has purchased (delivered order) | isVerified = true |
| SC-571 | Create review for product doctor hasn't purchased | isVerified = false |
| SC-572 | Create review without authentication | 401 |
| SC-573 | Verify product avgRating updated after review | Aggregate recalculated |
| SC-574 | Verify product reviewCount incremented | Count increased by 1 |
| SC-575 | Create review and verify it appears on product detail | Review visible in list |
| SC-576 | Update review rating from 3 to 5 | 200 — Rating updated |
| SC-577 | Update review text | 200 — Body updated |
| SC-578 | Update review of another doctor | 403 — Forbidden |
| SC-579 | Update non-existent review | 404 |
| SC-580 | Delete own review | 204 — Review deleted |
| SC-581 | Delete review and verify avgRating recalculated | Aggregate updated |
| SC-582 | Delete review and verify reviewCount decremented | Count decreased |
| SC-583 | Delete review of another doctor | 403 |
| SC-584 | Delete non-existent review | 404 |
| SC-585 | Review title max 200 characters | Validated |
| SC-586 | Review with very long body (1000+ chars) | Text field accepts |
| SC-587 | Review with XSS in body | Sanitized on output |
| SC-588 | Review helpfulCount initial = 0 | Default value |
| SC-589 | Multiple reviews for same product by different doctors | All accepted |
| SC-590 | Product with 100 reviews — avgRating accurate | Correct calculation |
| SC-591 | Product with 0 reviews — avgRating = 0.0 | Default displayed |
| SC-592 | Review from delivered order shows "Verified Purchase" badge | isVerified flag in response |
| SC-593 | Admin hides review (isVisible=false) | Review hidden from public list |
| SC-594 | Hidden review not in GET /products/:id/reviews | Excluded from results |
| SC-595 | Review shown on Reviews tab in product detail (Flutter) | Tab content renders |
| SC-596 | Star rating tappable in Flutter UI | 1-5 stars interactive |
| SC-597 | Review submission shows success message | Toast/snackbar |
| SC-598 | Review date displayed | createdAt formatted |
| SC-599 | Review shows doctor name | Doctor's fullName |
| SC-600 | Review includes orderItemId if from order | Link to specific order item |
| SC-601 | Edit review updates updatedAt timestamp | Timestamp changes |
| SC-602 | Review with rating=3 — avgRating calculation correct | Weighted average |
| SC-603 | First review for product sets avgRating | Exact rating value |
| SC-604 | Delete only review — avgRating resets to 0.0 | Reset to default |
| SC-605 | Review with SQL injection in body | Parameterized, no injection |
| SC-606 | Create review with empty body and title | Rating-only review accepted |
| SC-607 | Review pagination on product detail | Page through reviews |
| SC-608 | Reviews sorted by newest first | createdAt DESC |
| SC-609 | Multiple reviews affect product avgRating correctly | Average of all ratings |
| SC-610 | Review with title > 200 chars | 400 — Validation error |
| SC-611 | Review for inactive product | 404 or allowed |
| SC-612 | Review with decimal rating (3.5) | 400 — Must be integer |
| SC-613 | Review with rating as string "five" | 400 — Type error |
| SC-614 | Update review and verify avgRating recalculated | Old rating replaced |
| SC-615 | Create review from order detail page "Write Review" | Navigation works |
| SC-616 | Verified review badge shown in Flutter | Badge rendered for isVerified |
| SC-617 | Review body with newlines and formatting | Preserved in display |
| SC-618 | Review body with emoji characters | Emoji stored and displayed |
| SC-619 | Review without rating (body only) | 400 — Rating required |
| SC-620 | Create review and cancel before submitting | Nothing saved |

---

## 8. Wishlist

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-621 | Add product to wishlist | 201 — Wishlist entry created |
| SC-622 | Add same product again | 409 — "Already in wishlist" |
| SC-623 | Add non-existent product | 404 |
| SC-624 | Add product without authentication | 401 |
| SC-625 | Remove product from wishlist | 204 — Entry removed |
| SC-626 | Remove product not in wishlist | 404 |
| SC-627 | Remove without authentication | 401 |
| SC-628 | Get wishlist (paginated) | 200 — Products with details |
| SC-629 | Get wishlist page 2 | Pagination works |
| SC-630 | Get empty wishlist | 200 — Empty array |
| SC-631 | Wishlist shows product name, price, image | Full product info |
| SC-632 | Wishlist shows stock availability | In-stock/out-of-stock indicator |
| SC-633 | Heart icon toggles on product detail (Flutter) | Visual toggle |
| SC-634 | Heart icon filled = in wishlist | Filled icon state |
| SC-635 | Heart icon outline = not in wishlist | Outline icon state |
| SC-636 | Add to wishlist toast "Added to wishlist" | Snackbar shown |
| SC-637 | Remove from wishlist toast "Removed from wishlist" | Snackbar shown |
| SC-638 | Wishlist accessible from Profile menu | Profile → Wishlist navigation |
| SC-639 | Wishlist product tap navigates to product detail | Navigation works |
| SC-640 | Add to cart from wishlist | Product added to cart |
| SC-641 | Remove from wishlist after adding to cart | Optional behavior |
| SC-642 | Wishlist persists across sessions | Server-side storage |
| SC-643 | Wishlist for inactive product | Product may still show in wishlist |
| SC-644 | Wishlist for deleted product | Entry remains or cleaned up |
| SC-645 | Doctor A cannot see Doctor B's wishlist | Filtered by doctorId |
| SC-646 | Wishlist with 50 products | All listed, pagination |
| SC-647 | Add to wishlist from product card | Quick wishlist action |
| SC-648 | Wishlist product price updates | Shows current price |
| SC-649 | Wishlist shows sale price if on sale | Sale price displayed |
| SC-650 | Wishlist count badge | Count shown in profile menu |
| SC-651 | Add and remove same product rapidly | Final state correct |
| SC-652 | Wishlist API with invalid productId format | 400 — Validation error |
| SC-653 | Wishlist product out of stock indicator | Visual indicator |
| SC-654 | Wishlist sort by date added | createdAt ordering |
| SC-655 | Bulk remove from wishlist | Multiple deletions |
| SC-656 | Wishlist item click shows product detail | Full detail page |
| SC-657 | Wishlist shows product category | Category name present |
| SC-658 | Wishlist shows product rating | avgRating displayed |
| SC-659 | Product removed from wishlist updates heart icon | Real-time UI update |
| SC-660 | Wishlist accessible offline (cached) | Cached data shown |

---

## 9. Notifications

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-661 | Get notifications (paginated) | 200 — List with unread count |
| SC-662 | Notifications sorted newest first | createdAt DESC |
| SC-663 | Notification includes title, body, type, timestamp | All fields present |
| SC-664 | Notification types: order, promotion, system, approval | Type field present |
| SC-665 | Order notification includes order data (JSONB) | data field with orderId |
| SC-666 | Unread notifications count shown | unreadCount in response or badge |
| SC-667 | Mark single notification as read | PATCH returns 200, isRead=true |
| SC-668 | Mark already-read notification as read | No error, idempotent |
| SC-669 | Mark all notifications as read | POST returns 200, all isRead=true |
| SC-670 | Delete notification | 204 — Removed |
| SC-671 | Delete non-existent notification | 404 |
| SC-672 | Delete notification of another doctor | 404 |
| SC-673 | Get notifications without authentication | 401 |
| SC-674 | Notification created on order placement | "Order Confirmed" notification |
| SC-675 | Notification created on order status change | Status update notification |
| SC-676 | Notification created on account approval | "Account Approved" notification |
| SC-677 | Notification created on account rejection | "Account Rejected" notification |
| SC-678 | Bell icon badge shows unread count (Flutter) | Badge counter visible |
| SC-679 | Tap notification navigates to relevant page | Order notification → order detail |
| SC-680 | "Mark all read" button clears badge | Badge hidden after mark all |
| SC-681 | Notification with empty data field | data defaults to {} |
| SC-682 | FCM token registration | POST /notifications/fcm-token stores token |
| SC-683 | FCM token update (new device) | Token replaced |
| SC-684 | Push notification sent via FCM | Firebase Cloud Messaging triggered |
| SC-685 | Push notification when FCM not configured | Graceful fallback (no crash) |
| SC-686 | Bulk notification to multiple doctors | All receive notification |
| SC-687 | Notification pagination page 2 | Next page loads |
| SC-688 | Notification list empty | "No notifications" message |
| SC-689 | Notification timestamp relative ("Just now", "1d ago") | Human-readable format |
| SC-690 | Notification with long body text | Text truncated or scrollable |
| SC-691 | Notification persists across sessions | Server-side storage |
| SC-692 | 100+ notifications performance | Pagination handles large lists |
| SC-693 | Notification for promotion type | Promo notification rendered |
| SC-694 | Notification for system type | System notification rendered |
| SC-695 | Read notification visual difference | Read items styled differently |
| SC-696 | Swipe to delete notification (Flutter) | Swipe gesture works |
| SC-697 | Notification sound/vibration (mobile) | System notification alert |
| SC-698 | Notification received while app in background | Push notification shown |
| SC-699 | Notification received while app in foreground | In-app notification shown |
| SC-700 | Notification data includes orderId for navigation | Deep link data present |
| SC-701 | Mark notification read then navigate | Both actions work |
| SC-702 | Notification with special characters in title | Rendered correctly |
| SC-703 | Notification body with HTML content | Stripped or escaped |
| SC-704 | Create notification with empty title | 400 — Validation error |
| SC-705 | Create notification with empty body | 400 — Validation error |
| SC-706 | Notification cascade delete when doctor deleted | All notifications removed |
| SC-707 | Notification index on doctorId + createdAt | Query performance optimized |
| SC-708 | Notification with type not in enum | 400 — Validation error |
| SC-709 | FCM token with empty string | 400 — Validation error |
| SC-710 | Register FCM token without authentication | 401 |

---

## 10. Discounts & Promo Codes

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-711 | Apply valid percentage discount "WELCOME20" | 20% discount applied to subtotal |
| SC-712 | Apply valid fixed discount "$10OFF" | $10 deducted from subtotal |
| SC-713 | Apply discount code that doesn't exist | 400 — "Invalid discount code" |
| SC-714 | Apply expired discount (endsAt < now) | 400 — "Discount has expired" |
| SC-715 | Apply discount not yet started (startsAt > now) | 400 — "Discount not yet active" |
| SC-716 | Apply inactive discount (isActive=false) | 400 — "Discount not active" |
| SC-717 | Apply discount with usageLimit reached | 400 — "Usage limit exceeded" |
| SC-718 | Apply discount with perUserLimit reached for this doctor | 400 — "Already used this code" |
| SC-719 | Apply discount below minOrderAmount | 400 — "Minimum order amount not met" |
| SC-720 | Apply percentage discount with maxDiscount cap | Discount capped at maxDiscount |
| SC-721 | Apply discount code case-insensitive | "welcome20" = "WELCOME20" |
| SC-722 | Apply discount with leading/trailing spaces | Trimmed, valid code |
| SC-723 | Apply discount on cart page | Coupon field + Apply button |
| SC-724 | Apply discount on checkout page | Coupon field on checkout |
| SC-725 | Remove applied discount | Discount removed, total recalculated |
| SC-726 | Apply discount and verify total recalculates | Subtotal - discount + delivery = total |
| SC-727 | Discount code visible in order detail | Code and amount shown |
| SC-728 | Discount usage tracked per doctor | DiscountUsage record created |
| SC-729 | Discount usedCount incremented on order | Global counter updated |
| SC-730 | Admin creates percentage discount | POST /admin/discounts succeeds |
| SC-731 | Admin creates fixed discount | POST /admin/discounts succeeds |
| SC-732 | Admin creates discount with usage limit 100 | Limit stored |
| SC-733 | Admin creates discount with date range | startsAt/endsAt stored |
| SC-734 | Admin creates discount with minOrderAmount | Minimum stored |
| SC-735 | Admin creates discount with maxDiscount | Cap stored |
| SC-736 | Admin creates discount with perUserLimit=1 | Per-user limit stored |
| SC-737 | Admin views all discounts | GET /admin/discounts paginated |
| SC-738 | Admin updates discount value | PATCH /admin/discounts/:id |
| SC-739 | Admin deactivates discount | isActive set to false |
| SC-740 | Discount with scope "all" applies to everything | All items discounted |
| SC-741 | Discount with scope for specific category | Only category items |
| SC-742 | Discount shows status: Active/Expired/Upcoming | Based on dates and isActive |
| SC-743 | Apply two discount codes to same order | Only one allowed |
| SC-744 | Discount with 100% value | Full discount (if no cap) |
| SC-745 | Discount that makes total negative | Total clamped to 0 or delivery only |
| SC-746 | Discount code with special characters | 400 — Validation error |
| SC-747 | Discount code > 50 characters | 400 — Exceeds varchar(50) |
| SC-748 | Admin creates duplicate discount code | 409 — "Code already exists" |
| SC-749 | Discount usage after order cancellation | Usage decremented |
| SC-750 | Discount value > 100 for percentage type | 400 — Invalid value |
| SC-751 | Discount value = 0 | 400 — No discount applied |
| SC-752 | Discount with no expiry date | Always valid (until deactivated) |
| SC-753 | Apply discount via cart "Apply Coupon" field | Input + button interaction |
| SC-754 | Invalid coupon shows error message in Flutter | Error toast/inline message |
| SC-755 | Valid coupon shows discount breakdown | Discount line in summary |
| SC-756 | Discount applied persists through checkout | Not lost during navigation |
| SC-757 | Admin discount list shows usage count | usedCount / usageLimit |
| SC-758 | Discount with perUserLimit=3 — doctor uses it twice | Third use allowed |
| SC-759 | Discount with perUserLimit=1 — doctor's second order | Blocked |
| SC-760 | Discount description field | Optional text |
| SC-761 | Admin creates discount without authentication | 401 |
| SC-762 | Doctor accesses admin discount endpoint | 403 |
| SC-763 | Discount with 0.5% value | Decimal percentage |
| SC-764 | Discount calculation rounding (EGP 38.50 × 20% = 7.70) | Correct to 2 decimal places |
| SC-765 | Discount on order with single item | Applied to that item's total |
| SC-766 | Discount on order with multiple items | Applied to subtotal |
| SC-767 | Fixed discount exceeding subtotal | Total = 0 + delivery |
| SC-768 | Admin updates discount dates to past | Discount becomes expired |
| SC-769 | Admin updates discount dates to future | Discount becomes upcoming |
| SC-770 | Discount code SQL injection attempt | Parameterized, safe |

---

## 11. Flash Sales

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-771 | GET /flash-sales/active | 200 — Active flash sale with products |
| SC-772 | No active flash sale | 200 — null or empty |
| SC-773 | Flash sale shows countdown timer | endsAt used for countdown |
| SC-774 | Flash sale products show flash price | flashPrice displayed |
| SC-775 | Flash sale products show original price | Regular price for comparison |
| SC-776 | Flash sale products show discount percentage | Calculated savings |
| SC-777 | Flash sale product added to cart uses flash price | Flash price applied |
| SC-778 | Flash sale expired — regular price restored | Normal pricing |
| SC-779 | Flash sale product sold out (soldCount = flashStock) | "Sold Out" shown |
| SC-780 | Flash sale soldCount incremented on purchase | Counter updated |
| SC-781 | Flash sale not yet started (startsAt > now) | Not shown in active endpoint |
| SC-782 | Admin creates flash sale with products | POST /admin/flash-sales |
| SC-783 | Admin sets flash sale date range | startsAt/endsAt stored |
| SC-784 | Admin sets flash price per product | flashPrice stored |
| SC-785 | Admin sets flash stock per product | flashStock stored |
| SC-786 | Admin lists all flash sales | GET /admin/flash-sales |
| SC-787 | Admin activates flash sale | isActive = true |
| SC-788 | Admin deactivates flash sale | isActive = false |
| SC-789 | Flash sale auto-activates (scheduler) | Scheduler enables at startsAt |
| SC-790 | Flash sale auto-deactivates (scheduler) | Scheduler disables at endsAt |
| SC-791 | Multiple products in one flash sale | All products shown |
| SC-792 | Same product in two flash sales (unique constraint) | Only one per flash sale |
| SC-793 | Flash sale banner shown on home page | Banner position = flash_sale |
| SC-794 | Flash sale countdown reaches 0 | Sale ends, prices revert |
| SC-795 | Flash sale with 0 stock | Shows sold out immediately |
| SC-796 | Flash sale product with flashPrice > regular price | Validation should prevent |
| SC-797 | Admin creates flash sale without authentication | 401 |
| SC-798 | Doctor accesses admin flash sale endpoint | 403 |
| SC-799 | Flash sale accessible without authentication (public) | Public endpoint |
| SC-800 | Flash sale product detail shows flash price | Special pricing displayed |
| SC-801 | Order during flash sale records flash price | OrderItem.unitPrice = flashPrice |
| SC-802 | Flash sale ends during checkout | Price reverts if not locked |
| SC-803 | Flash sale with overlapping dates with another sale | System handles or prevents |
| SC-804 | Flash sale product with bulk pricing | Flash price overrides bulk |
| SC-805 | Flash sale title and banner URL | Both displayed |
| SC-806 | Flash sale pagination for products | If many products |
| SC-807 | Flash sale scheduler runs periodically | Cron job activates/deactivates |
| SC-808 | Flash sale mobile UI shows timer | Countdown widget |
| SC-809 | Flash sale product quick-add to cart | Add button works with flash price |
| SC-810 | Flash sale product in wishlist shows flash price | Price updated |

---

## 12. Banners

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-811 | GET /banners (public) | 200 — Active banners |
| SC-812 | Banners filtered by isActive=true | Inactive hidden |
| SC-813 | Banners filtered by date range | startsAt ≤ now ≤ endsAt |
| SC-814 | Banners sorted by sortOrder | Correct display order |
| SC-815 | Banner shows title and subtitle | Text visible |
| SC-816 | Banner shows image | imageUrl rendered |
| SC-817 | Banner with linkType "product" | Navigates to product detail |
| SC-818 | Banner with linkType "category" | Navigates to category |
| SC-819 | Banner with linkType "url" | Opens external URL |
| SC-820 | Banner with no link | Tap does nothing or shows info |
| SC-821 | Banner positions: home_slider, category_banner, flash_sale | Positioned correctly |
| SC-822 | Admin creates banner with image upload | POST /admin/banners |
| SC-823 | Admin creates banner with title and subtitle | Fields stored |
| SC-824 | Admin creates banner with link type and target | Link configured |
| SC-825 | Admin creates banner with schedule (start/end dates) | Date range stored |
| SC-826 | Admin creates banner with sort order | Order set |
| SC-827 | Admin lists all banners | GET /admin/banners |
| SC-828 | Admin updates banner title | PATCH /admin/banners/:id |
| SC-829 | Admin toggles banner active status | PATCH /admin/banners/:id/toggle |
| SC-830 | Admin deletes banner | DELETE /admin/banners/:id |
| SC-831 | Admin creates banner without authentication | 401 |
| SC-832 | Doctor accesses admin banner endpoint | 403 |
| SC-833 | Banners accessible without authentication (public) | Public endpoint |
| SC-834 | Home screen displays banners in slider | Auto-scroll carousel |
| SC-835 | Banner image 1080x400 aspect ratio | Rendered correctly |
| SC-836 | Banner with expired date not shown | Filtered by endsAt |
| SC-837 | Banner with future start date not shown | Filtered by startsAt |
| SC-838 | No active banners | Home screen shows no slider |
| SC-839 | Admin deactivates banner → disappears from mobile | Real-time update on next load |
| SC-840 | Admin reactivates banner → appears on mobile | Visible again |
| SC-841 | Banner title with special characters | Rendered safely |
| SC-842 | Banner subtitle with HTML | Escaped on display |
| SC-843 | Banner image URL invalid | Placeholder or broken image |
| SC-844 | Multiple banners in home_slider position | All shown in carousel |
| SC-845 | Single banner in home_slider | No auto-scroll needed |
| SC-846 | Banner click tracking | Navigation to linked content |
| SC-847 | Banner with linkTarget as UUID (product/category) | Valid navigation |
| SC-848 | Banner with linkTarget as external URL | Opens in browser |
| SC-849 | Admin creates banner with no dates (always active) | Shows indefinitely |
| SC-850 | Admin updates banner sort order | New order reflected |

---

## 13. File Uploads & Storage

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-851 | Upload single JPEG image | 201 — S3 key and URL returned |
| SC-852 | Upload single PNG image | 201 — Success |
| SC-853 | Upload single WebP image | 201 — Success |
| SC-854 | Upload PDF document | 201 — Success |
| SC-855 | Upload unsupported file type (.exe) | 400 — "Invalid file type" |
| SC-856 | Upload unsupported file type (.txt) | 400 — "Invalid file type" |
| SC-857 | Upload file > 5MB | 400 — "File too large" |
| SC-858 | Upload file exactly 5MB | 201 — Success (at limit) |
| SC-859 | Upload with no file attached | 400 — "No file provided" |
| SC-860 | Upload without authentication | 401 |
| SC-861 | Upload product image (POST /uploads/product-image) | 201 — Stored in products/ folder |
| SC-862 | Upload avatar (POST /uploads/avatar) | 201 — Stored in avatars/ folder |
| SC-863 | Upload generic image with folder query param | 201 — Stored in specified folder |
| SC-864 | Upload multiple images (POST /uploads/images, max 5) | 201 — Array of results |
| SC-865 | Upload 6 images (exceeds max 5) | 400 — "Too many files" |
| SC-866 | Upload 0 images to multiple endpoint | 400 — "No files provided" |
| SC-867 | Delete uploaded file by key | 204 — File removed from S3 |
| SC-868 | Delete non-existent file key | 204 or 404 (S3 behavior) |
| SC-869 | Delete file without authentication | 401 |
| SC-870 | File stored in MinIO (S3-compatible) | Object accessible via MinIO |
| SC-871 | File URL accessible for download | Valid presigned URL |
| SC-872 | Upload preserves original filename | Original name in metadata |
| SC-873 | Upload generates unique S3 key | UUID-based key, no collision |
| SC-874 | Upload with custom folder "licenses" | File in licenses/ prefix |
| SC-875 | Upload with custom folder "banners" | File in banners/ prefix |
| SC-876 | S3 endpoint configured for MinIO (localhost:9000) | ForcePathStyle=true |
| SC-877 | CDN_BASE_URL configured | URLs use CDN prefix |
| SC-878 | CDN_BASE_URL not configured | URLs use S3/MinIO endpoint |
| SC-879 | Presigned URL generation | Time-limited download URL |
| SC-880 | Upload with file containing spaces in name | Filename sanitized |
| SC-881 | Upload with unicode filename | Filename handled correctly |
| SC-882 | Upload MIME type validation (not just extension) | Content-Type header checked |
| SC-883 | Upload concurrent files | All succeed independently |
| SC-884 | S3 bucket doesn't exist | Error handled gracefully |
| SC-885 | S3 credentials invalid | Error handled, 500 |
| SC-886 | MinIO container down | Upload fails, error message |
| SC-887 | Upload returns both url and key | Both fields in response |
| SC-888 | Delete by key removes from storage | S3 DeleteObject called |
| SC-889 | Upload product image for product create flow | Used in admin product form |
| SC-890 | Upload banner image for banner create flow | Used in admin banner form |

---

## 14. Admin Dashboard & Reports

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-891 | GET /admin/dashboard/stats | 200 — totalDoctors, totalOrders, totalRevenue, recentOrders |
| SC-892 | Dashboard totalDoctors count accurate | Matches Doctor table count |
| SC-893 | Dashboard totalOrders count accurate | Matches Order table count |
| SC-894 | Dashboard totalRevenue sum accurate | Sum of all order totals |
| SC-895 | Dashboard recentOrders list (latest 10) | Newest orders shown |
| SC-896 | Dashboard stats without authentication | 401 |
| SC-897 | Dashboard stats with doctor token | 403 |
| SC-898 | GET /admin/reports/revenue | 200 — Revenue metrics |
| SC-899 | Revenue report by date range | Filtered by period |
| SC-900 | Revenue report includes product breakdown | Revenue per product |
| SC-901 | GET /admin/reports/products | 200 — Product performance |
| SC-902 | Products report includes units sold | totalSold per product |
| SC-903 | Products report includes revenue per product | Calculated from orders |
| SC-904 | Products report includes review metrics | avgRating, reviewCount |
| SC-905 | GET /admin/reports/doctors | 200 — Doctor metrics |
| SC-906 | Doctors report includes order count per doctor | Aggregated |
| SC-907 | Doctors report includes revenue per doctor | Sum of their orders |
| SC-908 | Doctors report includes status distribution | Count by status |
| SC-909 | Dashboard page in admin Flutter app | Stats cards rendered |
| SC-910 | Dashboard shows 4 stat cards | Doctors, Orders, Revenue, Pending |
| SC-911 | Dashboard shows recent orders table | DataTable with order info |
| SC-912 | Dashboard revenue value formatted as currency | EGP formatting |
| SC-913 | Dashboard null revenue value | Handles null without crash |
| SC-914 | Dashboard with 0 orders | Shows 0 counts |
| SC-915 | Dashboard with 0 doctors | Shows 0 |
| SC-916 | Admin sidebar navigation: Dashboard | Navigates to / |
| SC-917 | Admin sidebar navigation: Orders | Navigates to /orders |
| SC-918 | Admin sidebar navigation: Products | Navigates to /products |
| SC-919 | Admin sidebar navigation: Doctors | Navigates to /doctors |
| SC-920 | Admin sidebar navigation: Discounts | Navigates to /discounts |
| SC-921 | Admin sidebar navigation: Banners | Navigates to /banners |
| SC-922 | Admin responsive layout (drawer on mobile) | Sidebar becomes drawer |
| SC-923 | Admin auth redirect (unauthenticated → login) | GoRouter redirect |
| SC-924 | Admin refresh page stays on current route | Route persists |
| SC-925 | Admin page title updates per route | Browser tab title changes |
| SC-926 | Reports with large dataset | Performance acceptable |
| SC-927 | Revenue report date range validation | Start ≤ End |
| SC-928 | Products report pagination | Paginated if many products |
| SC-929 | Doctors report pagination | Paginated if many doctors |
| SC-930 | Admin dashboard auto-refresh | Manual refresh button |

---

## 15. Admin Doctor Management

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-931 | GET /admin/doctors | 200 — Paginated doctor list |
| SC-932 | Doctor list shows Name, Email, Specialty, Status | DataTable columns |
| SC-933 | Filter doctors by status "pending" | Only pending doctors |
| SC-934 | Filter doctors by status "approved" | Only approved doctors |
| SC-935 | Filter doctors by status "rejected" | Only rejected doctors |
| SC-936 | Filter doctors by status "suspended" | Only suspended doctors |
| SC-937 | GET /admin/doctors/:id | 200 — Full doctor detail |
| SC-938 | Doctor detail shows license URL | License viewable |
| SC-939 | Doctor detail shows addresses | Address list shown |
| SC-940 | Doctor detail shows order count | Aggregated orders |
| SC-941 | Approve pending doctor | PATCH returns 200, status=approved |
| SC-942 | Approve already approved doctor | 400 — "Already approved" |
| SC-943 | Approve rejected doctor | May be allowed (re-approval) |
| SC-944 | Approve doctor and verify approvedAt set | Timestamp recorded |
| SC-945 | Approve doctor and verify approvedBy set | Admin ID stored |
| SC-946 | Approve doctor sends approval email | Email with congratulations |
| SC-947 | Approve doctor creates notification | "Account Approved" notification |
| SC-948 | Approved doctor can now login | Login succeeds |
| SC-949 | Reject pending doctor with reason | PATCH returns 200, status=rejected |
| SC-950 | Reject doctor with empty reason | 400 — "Reason required" |
| SC-951 | Reject doctor sends rejection email | Email with reason |
| SC-952 | Reject doctor creates notification | "Account Rejected" notification |
| SC-953 | Rejected doctor cannot login | 403 on login attempt |
| SC-954 | Suspend approved doctor | PATCH returns 200, status=suspended |
| SC-955 | Suspended doctor cannot login | 403 on login attempt |
| SC-956 | Suspend already suspended doctor | Idempotent or 400 |
| SC-957 | Doctor management without authentication | 401 |
| SC-958 | Doctor management with doctor token | 403 |
| SC-959 | Approve doctor that doesn't exist | 404 |
| SC-960 | Reject doctor that doesn't exist | 404 |
| SC-961 | Doctors list pagination page 2 | Next page loads |
| SC-962 | Doctors list with no doctors | Empty table shown |
| SC-963 | Doctors table shows "Approve" button for pending | Action button visible |
| SC-964 | Doctors table shows "Suspend" button for approved | Action button visible |
| SC-965 | Reject dialog asks for reason text | Dialog with text input |
| SC-966 | Approve button triggers confirmation | Immediate or dialog |
| SC-967 | Refresh button reloads doctor list | Data refreshed |
| SC-968 | Doctor status badge color coding | Green=Approved, Red=Rejected, Yellow=Pending |
| SC-969 | Admin approves doctor → doctor receives push notification | FCM notification sent |
| SC-970 | Rejection reason stored in doctor record | rejectionReason field set |

---

## 16. Admin Product & Order Management

### 16.1 Admin Product CRUD

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-971 | Admin lists all products | GET /admin/products with pagination |
| SC-972 | Admin creates product with all fields | POST /admin/products, 201 |
| SC-973 | Admin creates product with name, SKU, description, price, stock | Required fields |
| SC-974 | Admin creates product with category assignment | categoryId set |
| SC-975 | Admin creates product with brand assignment | brandId set |
| SC-976 | Admin creates product with images | Image URLs stored |
| SC-977 | Admin creates product with bulk pricing tiers | BulkPricing records created |
| SC-978 | Admin creates product with medicalDetails (JSONB) | JSON stored |
| SC-979 | Admin creates product with salePrice | Sale price stored |
| SC-980 | Admin creates product with duplicate SKU | 409 — "SKU already exists" |
| SC-981 | Admin updates product price | PATCH /admin/products/:id |
| SC-982 | Admin updates product stock | Stock updated |
| SC-983 | Admin updates product description | Description updated |
| SC-984 | Admin deactivates product (isActive=false) | Product hidden from catalog |
| SC-985 | Admin reactivates product (isActive=true) | Product visible again |
| SC-986 | Admin deletes product | DELETE /admin/products/:id |
| SC-987 | Admin deletes product with existing orders | Soft delete (isActive=false) |
| SC-988 | Admin creates product with auto-generated slug | Slug from name |
| SC-989 | Admin product form validation — no name | 400 error |
| SC-990 | Admin product form validation — negative price | 400 error |

### 16.2 Admin Category & Order Management

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-991 | Admin creates category | POST /admin/categories, 201 |
| SC-992 | Admin creates subcategory (with parentId) | Child category created |
| SC-993 | Admin updates category name | PATCH /admin/categories/:id |
| SC-994 | Admin deletes empty category | DELETE /admin/categories/:id |
| SC-995 | Admin deletes category with products | 400 — "Category has products" |
| SC-996 | Admin views all orders | GET /admin/orders paginated |
| SC-997 | Admin views order detail | GET /admin/orders/:id |
| SC-998 | Admin updates order status with notes | PATCH /admin/orders/:id/status |
| SC-999 | Admin order list filter by status | Status filter applied |
| SC-1000 | Admin order list search by order number | Search functionality |

---

## Appendix A: Localization & Accessibility

| # | Scenario | Expected Result |
|---|----------|-----------------|
| A-001 | Toggle language to Arabic | All UI text translates to Arabic |
| A-002 | Arabic mode enables RTL layout | Text and layout direction reversed |
| A-003 | Arabic mode — bottom navigation labels in Arabic | All tabs translated |
| A-004 | Arabic mode — product names remain in original language | Product data unchanged |
| A-005 | Toggle back to English | LTR layout restored |
| A-006 | Language preference persists across sessions | Stored locally |
| A-007 | Arabic input in search field | RTL text input works |
| A-008 | Arabic input in forms (address, profile) | RTL input supported |
| A-009 | Date formatting in Arabic locale | Correct date format |
| A-010 | Currency formatting in Arabic locale | EGP display correct |
| A-011 | Flutter semantics enabled for screen readers | Accessibility tree present |
| A-012 | All buttons have accessible labels | ARIA labels present |
| A-013 | Form fields have accessible labels | Input labels present |
| A-014 | Error messages accessible | Error text readable |
| A-015 | Color contrast meets WCAG AA | Sufficient contrast |
| A-016 | Touch targets minimum 48x48dp | Tappable areas large enough |
| A-017 | Font size respects system settings | Dynamic type supported |
| A-018 | App works in landscape orientation | Layout adapts |
| A-019 | App works on tablet screen size | Responsive design |
| A-020 | Keyboard navigation on web | Tab order logical |

---

## Appendix B: Performance & Concurrency

| # | Scenario | Expected Result |
|---|----------|-----------------|
| B-001 | 100 concurrent product listing requests | All return 200 within 2s |
| B-002 | 50 concurrent search requests | All return results |
| B-003 | 10 concurrent checkout operations | All complete or fail gracefully |
| B-004 | Database connection pool exhaustion | Requests queue, no crash |
| B-005 | Redis connection failure | Rate limiting disabled, app continues |
| B-006 | S3/MinIO connection failure | Upload fails gracefully |
| B-007 | Server restart during active requests | In-flight requests fail, new ones succeed |
| B-008 | Database migration during operation | Handled by connection retry |
| B-009 | Large product catalog (10,000 products) | Pagination handles scale |
| B-010 | Large order history (1,000 orders per doctor) | Pagination works |
| B-011 | Full-text search index performance | Search returns in <500ms |
| B-012 | Token blacklist Redis performance | Check in <5ms |
| B-013 | Image upload 5MB over slow network | Upload completes with timeout |
| B-014 | API response time < 200ms (p95) | Performance target met |
| B-015 | Database query N+1 prevention | Joins used instead of loops |
| B-016 | Response compression enabled | gzip/br compression active |
| B-017 | Rate limiter distributed across instances | Redis-backed rate limit |
| B-018 | Checkout deadlock prevention (sorted locks) | No deadlocks |
| B-019 | Checkout timeout (15s) with rollback | Transaction rolled back |
| B-020 | Memory usage under load | No memory leaks |

---

## Summary Statistics

| Category | Scenarios | Range |
|----------|-----------|-------|
| Authentication & Authorization | 120 | SC-001 → SC-120 |
| Doctor Profile & Addresses | 60 | SC-121 → SC-180 |
| Product Catalog & Browsing | 90 | SC-181 → SC-270 |
| Search & Filtering | 70 | SC-271 → SC-340 |
| Shopping Cart | 90 | SC-341 → SC-430 |
| Orders & Checkout | 130 | SC-431 → SC-560 |
| Reviews & Ratings | 60 | SC-561 → SC-620 |
| Wishlist | 40 | SC-621 → SC-660 |
| Notifications | 50 | SC-661 → SC-710 |
| Discounts & Promo Codes | 60 | SC-711 → SC-770 |
| Flash Sales | 40 | SC-771 → SC-810 |
| Banners | 40 | SC-811 → SC-850 |
| File Uploads & Storage | 40 | SC-851 → SC-890 |
| Admin Dashboard & Reports | 40 | SC-891 → SC-930 |
| Admin Doctor Management | 40 | SC-931 → SC-970 |
| Admin Product & Order Mgmt | 30 | SC-971 → SC-1000 |
| Localization & Accessibility | 20 | A-001 → A-020 |
| Performance & Concurrency | 20 | B-001 → B-020 |
| **TOTAL** | **1,040** | |

Each scenario covers a unique user interaction, edge case, error path, security check, or cross-module flow across the entire MedOrder platform.
