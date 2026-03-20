// ═══════════════════════════════════════════════════════════
// MedOrder — Database Bootstrap Script (Node.js)
// Cross-platform alternative to db-bootstrap.sh
// Usage: npx tsx scripts/db-bootstrap.ts
// ═══════════════════════════════════════════════════════════

import { execSync } from 'child_process';
import { readFileSync, readdirSync, existsSync } from 'fs';
import path from 'path';
import { PrismaClient } from '@prisma/client';

const SQL_DIR = path.resolve(__dirname, '../prisma/sql');

async function main() {
    console.log('╔══════════════════════════════════════════════╗');
    console.log('║  MedOrder — Database Bootstrap               ║');
    console.log('╚══════════════════════════════════════════════╝');
    console.log('');

    // Step 1: Prisma migrate
    console.log('▸ Step 1: Running Prisma migrations...');
    execSync('npx prisma migrate deploy', { stdio: 'inherit' });
    console.log('  ✓ Prisma migrations applied\n');

    // Step 2: Run SQL scripts
    console.log('▸ Step 2: Applying supplementary SQL scripts...');

    if (!existsSync(SQL_DIR)) {
        console.log('  ⚠ No SQL directory found, skipping.\n');
    } else {
        const prisma = new PrismaClient();

        const sqlFiles = readdirSync(SQL_DIR)
            .filter((f) => f.endsWith('.sql'))
            .sort();

        for (const file of sqlFiles) {
            const filePath = path.join(SQL_DIR, file);
            const sql = readFileSync(filePath, 'utf-8');

            console.log(`  ⏳ Running ${file}...`);
            try {
                // Split by statements that end with semicolons,
                // but handle $$ function bodies properly
                await prisma.$executeRawUnsafe(sql);
                console.log(`  ✓ ${file} applied`);
            } catch (error: any) {
                // Some statements may fail due to IF NOT EXISTS or idempotent operations
                // Try running statement-by-statement
                const statements = splitSqlStatements(sql);
                let applied = 0;
                let skipped = 0;

                for (const stmt of statements) {
                    const trimmed = stmt.trim();
                    if (!trimmed || trimmed.startsWith('--')) continue;
                    try {
                        await prisma.$executeRawUnsafe(trimmed);
                        applied++;
                    } catch (stmtError: any) {
                        // Log but continue — idempotent statements may fail
                        if (!stmtError.message?.includes('already exists')) {
                            console.warn(`     ⚠ Statement skipped: ${stmtError.message?.slice(0, 80)}`);
                        }
                        skipped++;
                    }
                }
                console.log(`  ✓ ${file}: ${applied} applied, ${skipped} skipped`);
            }
        }

        await prisma.$disconnect();
    }
    console.log('');

    // Step 3: Seed
    console.log('▸ Step 3: Seeding database...');
    execSync('npx tsx scripts/seed.ts', { stdio: 'inherit' });
    console.log('  ✓ Seed data inserted\n');

    console.log('╔══════════════════════════════════════════════╗');
    console.log('║  ✅ Database bootstrap complete!              ║');
    console.log('╚══════════════════════════════════════════════╝');
}

/**
 * Split SQL text into individual statements.
 * Handles $$ delimited function bodies correctly.
 */
function splitSqlStatements(sql: string): string[] {
    const statements: string[] = [];
    let current = '';
    let inDollarQuote = false;

    const lines = sql.split('\n');
    for (const line of lines) {
        const stripped = line.trim();

        // Track $$ blocks (function bodies)
        const dollarCount = (stripped.match(/\$\$/g) || []).length;
        if (dollarCount % 2 !== 0) {
            inDollarQuote = !inDollarQuote;
        }

        current += line + '\n';

        // Statement ends with semicolon at end of line, outside $$ blocks
        if (!inDollarQuote && stripped.endsWith(';')) {
            statements.push(current.trim());
            current = '';
        }
    }

    // Remainder
    if (current.trim()) {
        statements.push(current.trim());
    }

    return statements;
}

main().catch((e) => {
    console.error('❌ Bootstrap failed:', e);
    process.exit(1);
});
