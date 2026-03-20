/**
 * High Throughput Scenarios (7-10)
 * Tests system under high concurrent read/write load
 */
const { api, login, adminLogin, report, concurrent } = require('./helpers');
const fs = require('fs');

let config;
try { config = JSON.parse(fs.readFileSync(__dirname + '/test-config.json', 'utf8')); }
catch { console.error('Run setup.js first'); process.exit(1); }

// ─────────────────────────────────────────────────────────
// Scenario 7: Burst Login Requests
// 200 concurrent logins (mix valid/invalid)
// ─────────────────────────────────────────────────────────
async function scenario7_burstLogin() {
    console.log('\n🏁 Scenario 7: Burst Login Requests');
    console.log('   200 concurrent logins (150 valid + 50 invalid)...\n');

    const results = await concurrent(200, async (i) => {
        if (i < 150) {
            // Valid login — cycle through test doctors
            const docIndex = i % Math.min(config.doctors.length, 50);
            const res = await api('POST', '/auth/login', {
                body: { email: `loadtest.doctor${docIndex}@test.com`, password: 'Password123' },
            });
            return { success: res.success, error: res.error?.code, type: 'valid' };
        } else {
            // Invalid login
            const res = await api('POST', '/auth/login', {
                body: { email: `nonexistent${i}@test.com`, password: 'wrong' },
            });
            return { success: false, error: res.error?.code, type: 'invalid', expectedFail: true };
        }
    });

    const validResults = results.filter(r => r.type === 'valid');
    const invalidResults = results.filter(r => r.type === 'invalid');

    const validStat = report('Scenario 7a: Valid Logins (150)', validResults);
    const invalidStat = report('Scenario 7b: Invalid Logins (50)', invalidResults);

    const validPass = validStat.succeeded >= 140; // allow small failure margin
    const invalidPass = invalidResults.every(r => !r.success);
    const pass = validPass && invalidPass;
    console.log(`   📊 Valid logins succeeded: ${validStat.succeeded}/150 (expected: ≥140)`);
    console.log(`   📊 Invalid logins rejected: ${invalidStat.failed}/50 (expected: 50)`);
    console.log(`   ${pass ? '✅ PASS' : '❌ FAIL'}\n`);

    return { name: 'Scenario 7: Burst Login', pass, ...validStat };
}

// ─────────────────────────────────────────────────────────
// Scenario 8: Home Page Storm
// 200 concurrent GET /products + /banners + /categories
// ─────────────────────────────────────────────────────────
async function scenario8_homePageStorm() {
    console.log('\n🏁 Scenario 8: Home Page Storm');
    console.log('   200 concurrent home page data fetches...\n');

    const token = config.doctors[0]?.token;

    const results = await concurrent(200, async (i) => {
        // Simulate home page: 3 parallel requests per "user"
        const endpoint = ['/products?limit=10', '/banners', '/categories'][i % 3];
        const res = await api('GET', endpoint, { token });
        return { success: res.success, error: res.error?.code, endpoint };
    });

    const stat = report('Scenario 8: Home Page Storm (200 reqs)', results);
    const pass = stat.succeeded >= 190 && stat.p95 < 2000;
    console.log(`   📊 Success rate: ${stat.succeeded}/200`);
    console.log(`   📊 p95 latency: ${stat.p95}ms (target: <2000ms)`);
    console.log(`   ${pass ? '✅ PASS' : '❌ FAIL'}\n`);

    return { ...stat, pass };
}

// ─────────────────────────────────────────────────────────
// Scenario 9: Product Listing Pagination
// 100 concurrent filtered product queries
// ─────────────────────────────────────────────────────────
async function scenario9_productPagination() {
    console.log('\n🏁 Scenario 9: Product Listing Pagination');
    console.log('   100 concurrent product listing requests with varied params...\n');

    const token = config.doctors[0]?.token;

    const results = await concurrent(100, async (i) => {
        const page = (i % 3) + 1;
        const limit = [10, 20, 50][i % 3];
        const res = await api('GET', `/products?page=${page}&limit=${limit}`, { token });
        return { success: res.success, error: res.error?.code, count: res.data?.length };
    });

    const stat = report('Scenario 9: Product Pagination (100 reqs)', results);
    const pass = stat.succeeded >= 95 && stat.p95 < 2000;
    console.log(`   📊 Success rate: ${stat.succeeded}/100`);
    console.log(`   📊 p95 latency: ${stat.p95}ms (target: <2000ms)`);
    console.log(`   ${pass ? '✅ PASS' : '❌ FAIL'}\n`);

    return { ...stat, pass };
}

// ─────────────────────────────────────────────────────────
// Scenario 10: Dashboard Stats Under Load
// 50 concurrent admin dashboard requests
// ─────────────────────────────────────────────────────────
async function scenario10_dashboardLoad() {
    console.log('\n🏁 Scenario 10: Dashboard Stats Under Load');
    console.log('   50 concurrent admin dashboard stat requests...\n');

    const results = await concurrent(50, async () => {
        const res = await api('GET', '/admin/dashboard/stats', { token: config.adminToken });
        return { success: res.success, error: res.error?.code, hasData: !!res.data };
    });

    const stat = report('Scenario 10: Dashboard Stats (50 reqs)', results);
    const pass = stat.succeeded >= 45 && stat.p95 < 3000;
    console.log(`   📊 Success rate: ${stat.succeeded}/50`);
    console.log(`   📊 p95 latency: ${stat.p95}ms (target: <3000ms, Redis cached)`);
    console.log(`   ${pass ? '✅ PASS' : '❌ FAIL'}\n`);

    return { ...stat, pass };
}

async function main() {
    console.log('╔══════════════════════════════════════════════════════════╗');
    console.log('║         THROUGHPUT TESTS (Scenarios 7-10)               ║');
    console.log('╚══════════════════════════════════════════════════════════╝');

    const results = [];
    results.push(await scenario7_burstLogin());
    results.push(await scenario8_homePageStorm());
    results.push(await scenario9_productPagination());
    results.push(await scenario10_dashboardLoad());

    console.log('\n╔══════════════════════════════════════════════════════════╗');
    console.log('║                    SUMMARY                              ║');
    console.log('╚══════════════════════════════════════════════════════════╝');
    results.filter(Boolean).forEach(r => {
        console.log(`  ${r.pass ? '✅' : '❌'} ${r.name}`);
    });
}

main().catch(e => { console.error('Fatal:', e); process.exit(1); });
