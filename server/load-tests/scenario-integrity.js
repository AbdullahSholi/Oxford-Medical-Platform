/**
 * Data Integrity Scenarios (12-15)
 * Verifies data consistency under concurrent operations
 */
const { api, report, concurrent } = require('./helpers');
const fs = require('fs');

let config;
try { config = JSON.parse(fs.readFileSync(__dirname + '/test-config.json', 'utf8')); }
catch { console.error('Run setup.js first'); process.exit(1); }

// ─────────────────────────────────────────────────────────
// Scenario 12: Order Number Uniqueness
// 30 concurrent order creations — all order numbers must be unique
// ─────────────────────────────────────────────────────────
async function scenario12_orderNumberUniqueness() {
    console.log('\n🏁 Scenario 12: Order Number Uniqueness');
    console.log('   30 concurrent order creations, checking uniqueness...\n');

    const product = config.products[0];
    if (!product) return;

    // Set high stock
    await api('PATCH', `/admin/products/${product.id}`, {
        token: config.adminToken,
        body: { stock: 500 },
    });

    const doctors = config.doctors.slice(0, 30);

    // Each doctor: clear cart → add → checkout
    const results = await concurrent(doctors.length, async (i) => {
        const doc = doctors[i];
        await api('DELETE', '/cart', { token: doc.token });
        await api('POST', '/cart/items', {
            token: doc.token,
            body: { productId: product.id, quantity: 1 },
        });
        const res = await api('POST', '/orders', {
            token: doc.token,
            body: { addressId: doc.addressId },
        });
        return {
            success: res.success,
            error: res.error?.code,
            orderNumber: res.data?.orderNumber,
        };
    });

    const stat = report('Scenario 12: Order Number Uniqueness', results);

    const orderNumbers = results.filter(r => r.orderNumber).map(r => r.orderNumber);
    const uniqueNumbers = new Set(orderNumbers);
    const hasDuplicates = uniqueNumbers.size !== orderNumbers.length;
    const duplicates = orderNumbers.filter((n, i) => orderNumbers.indexOf(n) !== i);

    console.log(`   📊 Orders created: ${orderNumbers.length}`);
    console.log(`   📊 Unique numbers: ${uniqueNumbers.size}`);
    if (hasDuplicates) console.log(`   📊 Duplicates: ${duplicates.join(', ')}`);

    const pass = !hasDuplicates;
    console.log(`   ${pass ? '✅ PASS' : '❌ FAIL'}: All order numbers unique\n`);

    // Restore stock
    await api('PATCH', `/admin/products/${product.id}`, {
        token: config.adminToken,
        body: { stock: product.stock },
    });

    return { ...stat, pass };
}

// ─────────────────────────────────────────────────────────
// Scenario 13: Stock Never Goes Negative
// Multiple concurrent checkouts depleting stock
// ─────────────────────────────────────────────────────────
async function scenario13_stockNeverNegative() {
    console.log('\n🏁 Scenario 13: Stock Never Goes Negative');
    console.log('   Setting stock to 10, 40 doctors try to buy 1 each...\n');

    const product = config.products[0];
    if (!product) return;

    const INITIAL_STOCK = 10;
    await api('PATCH', `/admin/products/${product.id}`, {
        token: config.adminToken,
        body: { stock: INITIAL_STOCK },
    });

    const doctors = config.doctors.slice(0, 40);

    const results = await concurrent(doctors.length, async (i) => {
        const doc = doctors[i];
        await api('DELETE', '/cart', { token: doc.token });
        await api('POST', '/cart/items', {
            token: doc.token,
            body: { productId: product.id, quantity: 1 },
        });
        const res = await api('POST', '/orders', {
            token: doc.token,
            body: { addressId: doc.addressId },
        });
        return { success: res.success, error: res.error?.code };
    });

    const stat = report('Scenario 13: Stock Never Negative', results);

    // Check final stock
    const finalProduct = await api('GET', `/products/${product.id}`, { token: doctors[0].token });
    const finalStock = finalProduct.data?.stock ?? 'unknown';
    const ordersCreated = stat.succeeded;

    console.log(`   📊 Initial stock: ${INITIAL_STOCK}`);
    console.log(`   📊 Orders created: ${ordersCreated} (expected: ≤${INITIAL_STOCK})`);
    console.log(`   📊 Final stock: ${finalStock} (expected: ≥0)`);
    console.log(`   📊 Stock math: ${INITIAL_STOCK} - ${ordersCreated} = ${INITIAL_STOCK - ordersCreated} (actual: ${finalStock})`);

    const stockValid = typeof finalStock === 'number' && finalStock >= 0;
    const countValid = ordersCreated <= INITIAL_STOCK;
    const mathValid = finalStock === INITIAL_STOCK - ordersCreated;
    const pass = stockValid && countValid && mathValid;

    console.log(`   ${pass ? '✅ PASS' : '❌ FAIL'}: Stock integrity maintained\n`);

    await api('PATCH', `/admin/products/${product.id}`, {
        token: config.adminToken,
        body: { stock: product.stock },
    });

    return { ...stat, pass };
}

// ─────────────────────────────────────────────────────────
// Scenario 14: Cart Isolation
// 20 doctors modify their carts simultaneously — no cross-contamination
// ─────────────────────────────────────────────────────────
async function scenario14_cartIsolation() {
    console.log('\n🏁 Scenario 14: Cart Isolation');
    console.log('   20 doctors modify carts simultaneously...\n');

    const doctors = config.doctors.slice(0, 20);
    const products = config.products;
    if (products.length < 2) { console.log('   ⚠️  Need at least 2 products'); return; }

    // Each doctor adds a different product (or pattern)
    const results = await concurrent(doctors.length, async (i) => {
        const doc = doctors[i];
        const product = products[i % products.length];

        await api('DELETE', '/cart', { token: doc.token });
        await api('POST', '/cart/items', {
            token: doc.token,
            body: { productId: product.id, quantity: i + 1 },
        });

        // Read back cart
        const cart = await api('GET', '/cart', { token: doc.token });
        const items = cart.data?.items || [];
        const hasCorrectProduct = items.some(item => item.productId === product.id);
        const hasCorrectQty = items.some(item => item.quantity === i + 1);
        const hasOtherDoctorItems = items.length > 1; // Should only have 1 item

        return {
            success: hasCorrectProduct && hasCorrectQty && !hasOtherDoctorItems,
            error: !hasCorrectProduct ? 'WRONG_PRODUCT' : !hasCorrectQty ? 'WRONG_QTY' : hasOtherDoctorItems ? 'CONTAMINATION' : null,
            itemCount: items.length,
        };
    });

    const stat = report('Scenario 14: Cart Isolation', results);
    const contaminated = results.filter(r => r.error === 'CONTAMINATION').length;
    const pass = contaminated === 0 && stat.succeeded === doctors.length;
    console.log(`   📊 Contaminated carts: ${contaminated} (expected: 0)`);
    console.log(`   ${pass ? '✅ PASS' : '❌ FAIL'}: No cross-contamination\n`);

    // Cleanup
    for (const doc of doctors) {
        await api('DELETE', '/cart', { token: doc.token });
    }

    return { ...stat, pass };
}

// ─────────────────────────────────────────────────────────
// Scenario 15: Concurrent Product Update + Checkout
// Admin changes price while doctor checks out
// ─────────────────────────────────────────────────────────
async function scenario15_priceChangeRace() {
    console.log('\n🏁 Scenario 15: Concurrent Product Update + Checkout');
    console.log('   Admin changes price while doctor checks out...\n');

    const doc = config.doctors[4];
    const product = config.products[0];
    if (!doc || !product) return;

    await api('PATCH', `/admin/products/${product.id}`, {
        token: config.adminToken,
        body: { stock: 100, price: 100 },
    });

    // Doctor adds to cart at price=100
    await api('DELETE', '/cart', { token: doc.token });
    await api('POST', '/cart/items', {
        token: doc.token,
        body: { productId: product.id, quantity: 1 },
    });

    // Race: admin updates price to 200 while doctor checks out
    const [priceUpdate, checkout] = await Promise.all([
        (async () => {
            const res = await api('PATCH', `/admin/products/${product.id}`, {
                token: config.adminToken,
                body: { price: 200 },
            });
            return { action: 'price_update', success: res.success };
        })(),
        (async () => {
            const res = await api('POST', '/orders', {
                token: doc.token,
                body: { addressId: doc.addressId },
            });
            return {
                action: 'checkout',
                success: res.success,
                total: res.data?.total,
                subtotal: res.data?.subtotal,
                error: res.error?.code,
            };
        })(),
    ]);

    console.log(`   Price update: ${priceUpdate.success ? 'succeeded' : 'failed'}`);
    console.log(`   Checkout: ${checkout.success ? 'succeeded' : 'failed'}, subtotal=${checkout.subtotal}`);

    // The order should have captured a consistent price (either 100 or 200, not a mix)
    const validPrice = checkout.subtotal === 100 || checkout.subtotal === 200 || !checkout.success;
    const pass = validPrice;
    console.log(`   📊 Order subtotal: ${checkout.subtotal} (should be 100 or 200, atomic)`);
    console.log(`   ${pass ? '✅ PASS' : '❌ FAIL'}: Price captured atomically\n`);

    // Restore
    await api('PATCH', `/admin/products/${product.id}`, {
        token: config.adminToken,
        body: { stock: product.stock, price: product.price },
    });

    return { name: 'Scenario 15: Price Change Race', pass };
}

async function main() {
    console.log('╔══════════════════════════════════════════════════════════╗');
    console.log('║         DATA INTEGRITY TESTS (Scenarios 12-15)          ║');
    console.log('╚══════════════════════════════════════════════════════════╝');

    const results = [];
    results.push(await scenario12_orderNumberUniqueness());
    results.push(await scenario13_stockNeverNegative());
    results.push(await scenario14_cartIsolation());
    results.push(await scenario15_priceChangeRace());

    console.log('\n╔══════════════════════════════════════════════════════════╗');
    console.log('║                    SUMMARY                              ║');
    console.log('╚══════════════════════════════════════════════════════════╝');
    results.filter(Boolean).forEach(r => {
        console.log(`  ${r.pass ? '✅' : '❌'} ${r.name}`);
    });
}

main().catch(e => { console.error('Fatal:', e); process.exit(1); });
