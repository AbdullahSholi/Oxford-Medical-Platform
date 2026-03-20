/**
 * Stress & Recovery Scenarios (16-19)
 * Tests system resilience under extreme load and failure conditions
 */
const { api, report, concurrent } = require('./helpers');
const fs = require('fs');

let config;
try { config = JSON.parse(fs.readFileSync(__dirname + '/test-config.json', 'utf8')); }
catch { console.error('Run setup.js first'); process.exit(1); }

// ─────────────────────────────────────────────────────────
// Scenario 16: Connection Pool Exhaustion
// 200 concurrent checkout-like operations to stress the pool
// ─────────────────────────────────────────────────────────
async function scenario16_poolExhaustion() {
    console.log('\n🏁 Scenario 16: Connection Pool Exhaustion');
    console.log('   200 concurrent heavy requests to stress DB pool...\n');

    const token = config.doctors[0]?.token;
    const product = config.products[0];

    // Heavy mixed workload: products + orders listing + dashboard
    const results = await concurrent(200, async (i) => {
        try {
            const endpoints = [
                '/products?limit=50',
                '/orders',
                '/products?limit=20&page=1',
                `/products/${product?.id}`,
                '/banners',
                '/categories',
            ];
            const endpoint = endpoints[i % endpoints.length];
            const useAdmin = i % 6 === 1;
            const t = useAdmin ? config.adminToken : token;
            const fullEndpoint = useAdmin ? '/admin/dashboard/stats' : endpoint;

            const res = await api('GET', fullEndpoint, { token: t });
            return { success: res.success, error: res.error?.code };
        } catch (e) {
            return { success: false, error: e.message };
        }
    });

    const stat = report('Scenario 16: Pool Exhaustion (200 reqs)', results);
    // Server should survive — some timeouts acceptable but no crashes
    const pass = stat.succeeded >= 150; // 75% success rate minimum
    console.log(`   📊 Success rate: ${stat.succeeded}/200 (target: ≥150)`);
    console.log(`   📊 p99 latency: ${stat.p99}ms`);
    console.log(`   ${pass ? '✅ PASS' : '❌ FAIL'}: Server survived\n`);

    // Verify server still alive
    const health = await api('GET', '/products?limit=1', { token });
    console.log(`   📊 Post-stress health check: ${health.success ? 'OK' : 'DOWN'}`);

    return { ...stat, pass };
}

// ─────────────────────────────────────────────────────────
// Scenario 17: Redis Down During Request
// We can't kill Redis from here, but we can test cache miss path
// by flooding with unique cache-busting requests
// ─────────────────────────────────────────────────────────
async function scenario17_cacheMissFlood() {
    console.log('\n🏁 Scenario 17: Cache Miss Flood (simulating Redis pressure)');
    console.log('   100 concurrent requests with varied params to bypass cache...\n');

    const token = config.doctors[0]?.token;

    // Use unique query params to bypass any caching layer
    const results = await concurrent(100, async (i) => {
        const res = await api('GET', `/products?limit=${(i % 50) + 1}&page=${(i % 5) + 1}`, { token });
        return { success: res.success, error: res.error?.code };
    });

    const stat = report('Scenario 17: Cache Miss Flood (100 reqs)', results);
    const pass = stat.succeeded >= 90 && stat.p95 < 5000;
    console.log(`   📊 Success rate: ${stat.succeeded}/100 (target: ≥90)`);
    console.log(`   📊 p95 latency: ${stat.p95}ms (target: <5000ms)`);
    console.log(`   ${pass ? '✅ PASS' : '❌ FAIL'}: DB handles direct load\n`);

    return { ...stat, pass };
}

// ─────────────────────────────────────────────────────────
// Scenario 18: Transaction Timeout
// Create lock contention by many concurrent checkouts on same product
// ─────────────────────────────────────────────────────────
async function scenario18_transactionTimeout() {
    console.log('\n🏁 Scenario 18: Transaction Timeout / Lock Contention');
    console.log('   40 doctors checkout same product simultaneously (high contention)...\n');

    const product = config.products[0];
    if (!product) return;

    await api('PATCH', `/admin/products/${product.id}`, {
        token: config.adminToken,
        body: { stock: 500 },
    });

    const doctors = config.doctors.slice(0, 40);

    // All add same product to cart first
    await Promise.all(doctors.map(async (doc) => {
        await api('DELETE', '/cart', { token: doc.token });
        await api('POST', '/cart/items', {
            token: doc.token,
            body: { productId: product.id, quantity: 1 },
        });
    }));

    // All checkout simultaneously — maximum lock contention on product row
    const start = Date.now();
    const results = await concurrent(doctors.length, async (i) => {
        const doc = doctors[i];
        const res = await api('POST', '/orders', {
            token: doc.token,
            body: { addressId: doc.addressId },
        });
        return { success: res.success, error: res.error?.code || res.error?.message };
    });
    const totalTime = Date.now() - start;

    const stat = report('Scenario 18: Transaction Lock Contention (40 reqs)', results);

    const timeouts = results.filter(r => r.error && (r.error.includes('timeout') || r.error.includes('TIMEOUT'))).length;
    console.log(`   📊 Total time: ${totalTime}ms`);
    console.log(`   📊 Timeouts: ${timeouts}`);
    console.log(`   📊 Orders created: ${stat.succeeded}`);

    // Check stock consistency
    const finalProduct = await api('GET', `/products/${product.id}`, { token: doctors[0].token });
    const finalStock = finalProduct.data?.stock ?? 'unknown';
    const stockConsistent = finalStock === 500 - stat.succeeded;
    console.log(`   📊 Stock: ${finalStock} (expected: ${500 - stat.succeeded})`);

    const pass = stockConsistent && (typeof finalStock === 'number' && finalStock >= 0);
    console.log(`   ${pass ? '✅ PASS' : '❌ FAIL'}: Stock consistent after contention\n`);

    await api('PATCH', `/admin/products/${product.id}`, {
        token: config.adminToken,
        body: { stock: product.stock },
    });

    return { ...stat, pass };
}

// ─────────────────────────────────────────────────────────
// Scenario 19: Notification Queue Backpressure
// Rapid order creation to flood the notification queue
// (We verify orders aren't blocked by notification failures)
// ─────────────────────────────────────────────────────────
async function scenario19_notificationBackpressure() {
    console.log('\n🏁 Scenario 19: Notification Queue Backpressure');
    console.log('   20 rapid sequential orders to flood notification queue...\n');

    const product = config.products[0];
    if (!product) return;

    await api('PATCH', `/admin/products/${product.id}`, {
        token: config.adminToken,
        body: { stock: 500 },
    });

    const doctors = config.doctors.slice(0, 20);
    const results = [];

    // Sequential rapid-fire orders
    for (const doc of doctors) {
        const start = Date.now();
        await api('DELETE', '/cart', { token: doc.token });
        await api('POST', '/cart/items', {
            token: doc.token,
            body: { productId: product.id, quantity: 1 },
        });
        const res = await api('POST', '/orders', {
            token: doc.token,
            body: { addressId: doc.addressId },
        });
        results.push({
            success: res.success,
            error: res.error?.code,
            duration: Date.now() - start,
        });
    }

    const stat = report('Scenario 19: Notification Backpressure (20 orders)', results);

    // Key check: later orders shouldn't be slower than early ones
    // (notification queue shouldn't block order creation)
    const firstHalf = results.slice(0, 10).map(r => r.duration);
    const secondHalf = results.slice(10).map(r => r.duration);
    const avgFirst = firstHalf.reduce((a, b) => a + b, 0) / firstHalf.length;
    const avgSecond = secondHalf.reduce((a, b) => a + b, 0) / secondHalf.length;

    console.log(`   📊 Avg time first 10: ${Math.round(avgFirst)}ms`);
    console.log(`   📊 Avg time last 10: ${Math.round(avgSecond)}ms`);

    // Second half shouldn't be >3x slower (indicates backpressure)
    const pass = stat.succeeded >= 18 && avgSecond < avgFirst * 3;
    console.log(`   📊 Slowdown ratio: ${(avgSecond / avgFirst).toFixed(2)}x (target: <3x)`);
    console.log(`   ${pass ? '✅ PASS' : '❌ FAIL'}: No backpressure detected\n`);

    await api('PATCH', `/admin/products/${product.id}`, {
        token: config.adminToken,
        body: { stock: product.stock },
    });

    return { ...stat, pass };
}

async function main() {
    console.log('╔══════════════════════════════════════════════════════════╗');
    console.log('║         STRESS & RECOVERY TESTS (Scenarios 16-19)       ║');
    console.log('╚══════════════════════════════════════════════════════════╝');

    const results = [];
    results.push(await scenario16_poolExhaustion());
    results.push(await scenario17_cacheMissFlood());
    results.push(await scenario18_transactionTimeout());
    results.push(await scenario19_notificationBackpressure());

    console.log('\n╔══════════════════════════════════════════════════════════╗');
    console.log('║                    SUMMARY                              ║');
    console.log('╚══════════════════════════════════════════════════════════╝');
    results.filter(Boolean).forEach(r => {
        console.log(`  ${r.pass ? '✅' : '❌'} ${r.name}`);
    });
}

main().catch(e => { console.error('Fatal:', e); process.exit(1); });
