// ═══════════════════════════════════════════════════════════
// MedOrder — Full-Text Search Utility
// Provides helpers for PostgreSQL TSVECTOR search + trigram
// fuzzy matching on product data.
// ═══════════════════════════════════════════════════════════

import { Prisma, PrismaClient } from '@prisma/client';

/**
 * Search products using PostgreSQL full-text search (tsvector).
 * Falls back to trigram LIKE search if FTS returns no results.
 *
 * All queries use parameterized inputs to prevent SQL injection.
 */
export async function searchProducts(
    prisma: PrismaClient,
    query: string,
    options: {
        page?: number;
        limit?: number;
        categoryId?: string;
        minPrice?: number;
        maxPrice?: number;
        inStock?: boolean;
    } = {},
) {
    const page = Math.max(1, Math.floor(options.page ?? 1));
    const limit = Math.min(100, Math.max(1, Math.floor(options.limit ?? 20)));
    const offset = (page - 1) * limit;

    // Sanitize and convert to tsquery format
    const tsQuery = toTsQuery(query);

    // Build parameterized WHERE clauses
    const conditions: string[] = ['p.is_active = true'];
    const params: unknown[] = [];
    let paramIndex = 1;

    if (tsQuery) {
        conditions.push(`p.search_vector @@ to_tsquery('english', $${paramIndex})`);
        params.push(tsQuery);
        paramIndex++;
    }

    if (options.categoryId) {
        conditions.push(`p.category_id = $${paramIndex}::uuid`);
        params.push(options.categoryId);
        paramIndex++;
    }

    if (options.minPrice !== undefined) {
        conditions.push(`p.price >= $${paramIndex}`);
        params.push(options.minPrice);
        paramIndex++;
    }

    if (options.maxPrice !== undefined) {
        conditions.push(`p.price <= $${paramIndex}`);
        params.push(options.maxPrice);
        paramIndex++;
    }

    if (options.inStock) {
        conditions.push('p.stock > 0');
    }

    const whereClause = conditions.join(' AND ');

    // LIMIT and OFFSET are also parameterized
    const limitParamIdx = paramIndex++;
    const offsetParamIdx = paramIndex++;
    params.push(limit, offset);

    // Rank by FTS relevance when searching, otherwise by total_sold
    const orderBy = tsQuery
        ? `ts_rank(p.search_vector, to_tsquery('english', $1)) DESC, p.total_sold DESC`
        : 'p.total_sold DESC';

    const selectCols = `
        p.id, p.name, p.slug, p.sku, p.price, p.sale_price,
        p.stock, p.avg_rating, p.review_count, p.total_sold,
        p.is_active, p.created_at,
        c.name AS category_name`;

    const ftsSelect = tsQuery
        ? `, ts_rank(p.search_vector, to_tsquery('english', $1)) AS relevance,
           ts_headline('english', p.name || ' ' || p.description, to_tsquery('english', $1), 'MaxWords=50, MinWords=10') AS highlight`
        : `, '' AS highlight`;

    const [rows, countResult] = await Promise.all([
        prisma.$queryRawUnsafe<any[]>(
            `SELECT ${selectCols}${ftsSelect}
            FROM products p
            LEFT JOIN categories c ON c.id = p.category_id
            WHERE ${whereClause}
            ORDER BY ${orderBy}
            LIMIT $${limitParamIdx} OFFSET $${offsetParamIdx}`,
            ...params,
        ),
        prisma.$queryRawUnsafe<Array<{ count: bigint }>>(
            `SELECT COUNT(*) AS count FROM products p WHERE ${whereClause}`,
            ...params.slice(0, -2), // Exclude limit/offset for count query
        ),
    ]);

    const total = Number(countResult[0]?.count ?? 0);

    // If FTS returned 0 results and query was provided, try trigram fallback
    if (rows.length === 0 && query.trim().length > 2 && tsQuery) {
        return trigramSearch(prisma, query, options);
    }

    return {
        data: rows,
        meta: {
            total,
            page,
            limit,
            totalPages: Math.ceil(total / limit),
        },
    };
}

/**
 * Trigram-based fuzzy search fallback.
 * Uses pg_trgm similarity for typo-tolerant matching.
 * All parameters are parameterized — no string interpolation.
 */
async function trigramSearch(
    prisma: PrismaClient,
    query: string,
    options: { page?: number; limit?: number } = {},
) {
    const page = Math.max(1, Math.floor(options.page ?? 1));
    const limit = Math.min(100, Math.max(1, Math.floor(options.limit ?? 20)));
    const offset = (page - 1) * limit;

    const rows = await prisma.$queryRawUnsafe<any[]>(
        `SELECT
            p.id, p.name, p.slug, p.sku, p.price, p.sale_price,
            p.stock, p.avg_rating, p.review_count, p.total_sold,
            p.is_active, p.created_at,
            similarity(p.name, $1) AS relevance
        FROM products p
        WHERE p.is_active = true
          AND (
            similarity(p.name, $1) > 0.2
            OR p.name ILIKE '%' || $1 || '%'
          )
        ORDER BY similarity(p.name, $1) DESC, p.total_sold DESC
        LIMIT $2 OFFSET $3`,
        query,
        limit,
        offset,
    );

    return {
        data: rows,
        meta: {
            total: rows.length,
            page,
            limit,
            totalPages: 1, // Approximation for fuzzy
            fuzzy: true,
        },
    };
}

/**
 * Convert user search input into a PostgreSQL tsquery string.
 * Strips all non-alphanumeric characters to prevent injection.
 */
function toTsQuery(input: string): string | null {
    if (!input || !input.trim()) return null;

    const sanitized = input
        .trim()
        .replace(/[^\w\s]/g, '')  // Remove special chars (prevents tsquery injection)
        .replace(/\s+/g, ' ')     // Collapse whitespace
        .toLowerCase();

    if (!sanitized) return null;

    const words = sanitized.split(' ');
    return words
        .map((w) => (w === 'or' ? '|' : w + ':*'))  // Prefix matching with :*
        .join(' & ')
        .replace(/& \| &/g, ' | ');  // Fix "word & | & word" → "word | word"
}
