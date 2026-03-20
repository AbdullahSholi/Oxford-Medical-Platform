/**
 * Race Condition Scenarios (1-6)
 * Tests concurrent access to shared resources under contention
 */
const { api, adminLogin, report, concurrent } = require('./helpers');
const fs = require('fs');

let config;
try { config = JSON.parse(fs.readFileSync(__dirname + '/test-config.json', 'utf8')); }
catch { console.error('Run setup.js first'); process.exit(1); }

// ─────────────────────────────────────────────────────────
// Scenario 1: Last-Item Stock Race
// 50 doctors try to buy a product with stock=1
// ─────────────────────────────────────────────────────────
async function scenario1_lastItemRace() {
    console.log('\n🏁 Scenario 1: Last-Item Stock Race');
    console.log('   Setting product stock to 1, then 50 doctors race to buy it...\n');

    const product = config.products[0];
    if (!product) { console.log('   ⚠️  No products available'); return; }

    // Admin sets stock to 1
    await api('PATCH', `/admin/products/${product.id}`, {
        token: config.adminToken,
        body: { stock: 1 },
    });
    console.log(`   Product "${product.name}" stock set to 1`);

    const doctors = config.doctors.slice(0, 50);

    // Each doctor: clear cart → add product → checkout
    const results = await concurrent(doctors.length, async (i) => {
        const doc = doctors[i];

        // Clear cart first
        await api('DELETE', '/cart', { token: doc.token });

        // Add product to cart
        const addRes = await api('POST', '/cart/items', {
            token: doc.token,
            body: { productId: product.id, quantity: 1 },
        });
        if (!addRes.success) {
            return { success: false, error: addRes.error?.code || 'ADD_FAILED', code: addRes.error?.code };
        }

        // Checkout
        const orderRes = await api('POST', '/orders', {
            token: doc.token,
            body: { addressId: doc.addressId },
        });
        return {
            success: orderRes.success,
            error: orderRes.error?.code || orderRes.error?.message,
            code: orderRes.error?.code,
            orderId: orderRes.data?.id,
        };
    });

    const stat = report('Scenario 1: Last-Item Stock Race', results);

    // Verify: check final stock
    const finalProduct = await api('GET', `/products/${product.id}`, { token: doctors[0].token });
    const finalStock = finalProduct.data?.stock ?? 'unknown';
    console.log(`   📊 Final stock: ${finalStock} (expected: 0)`);
    console.log(`   📊 Orders created: ${stat.succeeded} (expected: exactly 1)`);

    const pass = stat.succeeded === 1 && finalStock === 0;
    console.log(`   ${pass ? '✅ PASS' : '❌ FAIL'}: ${stat.succeeded} orders created\n`);

    // Restore stock
    await api('PATCH', `/admin/products/${product.id}`, {
        token: config.adminToken,
        body: { stock: product.stock },
    });

    return { ...stat, pass };
}

// ─────────────────────────────────────────────────────────
// Scenario 2: Simultaneous Checkout Same Cart
// 1 doctor sends 20 concurrent checkout requests
// ─────────────────────────────────────────────────────────
async function scenario2_doubleCheckout() {
    console.log('\n🏁 Scenario 2: Simultaneous Checkout Same Cart');
    console.log('   1 doctor sends 20 concurrent checkout requests...\n');

    const doc = config.doctors[0];
    const product = config.products[0];
    if (!doc || !product) { console.log('   ⚠️  Missing data'); return; }

    // Ensure stock is available
    await api('PATCH', `/admin/products/${product.id}`, {
        token: config.adminToken,
        body: { stock: 100 },
    });

    // Set up cart
    await api('DELETE', '/cart', { token: doc.token });
    await api('POST', '/cart/items', {
        token: doc.token,
        body: { productId: product.id, quantity: 1 },
    });

    // 20 concurrent checkouts
    const results = await concurrent(20, async () => {
        const res = await api('POST', '/orders', {
            token: doc.token,
            body: { addressId: doc.addressId },
        });
        return { success: res.success, error: res.error?.code, orderId: res.data?.id };
    });

    const stat = report('Scenario 2: Double Checkout', results);
    const pass = stat.succeeded === 1;
    console.log(`   📊 Orders created: ${stat.succeeded} (expected: exactly 1)`);
    console.log(`   ${pass ? '✅ PASS' : '❌ FAIL'}\n`);

    // Restore stock
    await api('PATCH', `/admin/products/${product.id}`, {
        token: config.adminToken,
        body: { stock: product.stock },
    });

    return { ...stat, pass };
}

// ─────────────────────────────────────────────────────────
// Scenario 3: Discount Code Exhaustion Race
// Create discount with usage_limit=1, 30 doctors race to use it
// ─────────────────────────────────────────────────────────
async function scenario3_discountRace() {
    console.log('\n🏁 Scenario 3: Discount Code Exhaustion Race');
    console.log('   Creating discount with limit=1, 30 doctors race to use it...\n');

    const product = config.products[0];
    if (!product) { console.log('   ⚠️  No products'); return; }

    // Create a limited discount
    const discountRes = await api('POST', '/admin/discounts', {
        token: config.adminToken,
        body: {
            code: `RACE${Date.now()}`,
            type: 'percentage',
            value: 10,
            usageLimit: 1,
            perUserLimit: 1,
            startsAt: new Date(Date.now() - 86400000).toISOString(),
            endsAt: new Date(Date.now() + 86400000).toISOString(),
            isActive: true,
        },
    });

    if (!discountRes.success) {
        console.log('   ⚠️  Could not create discount:', discountRes.error);
        return;
    }
    const discountCode = discountRes.data?.code || `RACE${Date.now()}`;
    console.log(`   Discount code: ${discountCode}`);

    // Ensure stock
    await api('PATCH', `/admin/products/${product.id}`, {
        token: config.adminToken,
        body: { stock: 100 },
    });

    const doctors = config.doctors.slice(0, 30);

    // Each doctor: clear cart → add product → apply coupon → checkout
    const results = await concurrent(doctors.length, async (i) => {
        const doc = doctors[i];
        await api('DELETE', '/cart', { token: doc.token });
        await api('POST', '/cart/items', {
            token: doc.token,
            body: { productId: product.id, quantity: 1 },
        });

        const orderRes = await api('POST', '/orders', {
            token: doc.token,
            body: { addressId: doc.addressId, discountCode },
        });
        return {
            success: orderRes.success,
            error: orderRes.error?.code,
            hasDiscount: orderRes.data?.discountAmount > 0,
        };
    });

    const stat = report('Scenario 3: Discount Exhaustion Race', results);
    const discountedOrders = results.filter(r => r.hasDiscount).length;
    console.log(`   📊 Orders with discount: ${discountedOrders} (expected: ≤1)`);
    const pass = discountedOrders <= 1;
    console.log(`   ${pass ? '✅ PASS' : '❌ FAIL'}\n`);

    // Restore stock
    await api('PATCH', `/admin/products/${product.id}`, {
        token: config.adminToken,
        body: { stock: product.stock },
    });

    return { ...stat, pass };
}

// ─────────────────────────────────────────────────────────
// Scenario 4: Per-User Discount Limit Race
// Same doctor sends 15 concurrent checkouts with same discount
// ─────────────────────────────────────────────────────────
async function scenario4_perUserDiscountRace() {
    console.log('\n🏁 Scenario 4: Per-User Discount Limit Race');
    console.log('   Same doctor sends 15 concurrent checkouts with same discount...\n');

    const doc = config.doctors[0];
    const product = config.products[0];
    if (!doc || !product) { console.log('   ⚠️  Missing data'); return; }

    // Create discount with high global limit but per_user=1
    const discountRes = await api('POST', '/admin/discounts', {
        token: config.adminToken,
        body: {
            code: `PERUSER${Date.now()}`,
            type: 'percentage',
            value: 5,
            usageLimit: 100,
            perUserLimit: 1,
            startsAt: new Date(Date.now() - 86400000).toISOString(),
            endsAt: new Date(Date.now() + 86400000).toISOString(),
            isActive: true,
        },
    });

    if (!discountRes.success) {
        console.log('   ⚠️  Could not create discount:', discountRes.error);
        return;
    }
    const discountCode = discountRes.data?.code || `PERUSER${Date.now()}`;

    await api('PATCH', `/admin/products/${product.id}`, {
        token: config.adminToken,
        body: { stock: 100 },
    });

    // Prep: add item to cart once — each concurrent checkout will try the same cart
    await api('DELETE', '/cart', { token: doc.token });
    await api('POST', '/cart/items', {
        token: doc.token,
        body: { productId: product.id, quantity: 1 },
    });

    const results = await concurrent(15, async () => {
        const res = await api('POST', '/orders', {
            token: doc.token,
            body: { addressId: doc.addressId, discountCode },
        });
        return {
            success: res.success,
            error: res.error?.code,
            hasDiscount: res.data?.discountAmount > 0,
        };
    });

    const stat = report('Scenario 4: Per-User Discount Race', results);
    const discountedOrders = results.filter(r => r.hasDiscount).length;
    // Only 1 order should succeed at all (cart gets cleared), and at most 1 gets discount
    console.log(`   📊 Orders with discount: ${discountedOrders} (expected: ≤1)`);
    const pass = discountedOrders <= 1;
    console.log(`   ${pass ? '✅ PASS' : '❌ FAIL'}\n`);

    await api('PATCH', `/admin/products/${product.id}`, {
        token: config.adminToken,
        body: { stock: product.stock },
    });

    return { ...stat, pass };
}

// ─────────────────────────────────────────────────────────
// Scenario 5: Concurrent Cancel + Status Update
// Doctor cancels while admin confirms simultaneously
// ─────────────────────────────────────────────────────────
async function scenario5_cancelVsUpdate() {
    console.log('\n🏁 Scenario 5: Concurrent Cancel + Status Update');
    console.log('   Doctor cancels while admin confirms the same order...\n');

    const doc = config.doctors[1];
    const product = config.products[0];
    if (!doc || !product) { console.log('   ⚠️  Missing data'); return; }

    // Create a fresh order
    await api('PATCH', `/admin/products/${product.id}`, {
        token: config.adminToken,
        body: { stock: 100 },
    });
    await api('DELETE', '/cart', { token: doc.token });
    await api('POST', '/cart/items', {
        token: doc.token,
        body: { productId: product.id, quantity: 1 },
    });
    const orderRes = await api('POST', '/orders', {
        token: doc.token,
        body: { addressId: doc.addressId },
    });

    if (!orderRes.success) {
        console.log('   ⚠️  Could not create test order:', orderRes.error);
        return;
    }
    const orderId = orderRes.data.id;
    console.log(`   Created order ${orderId}`);

    // Race: doctor cancel vs admin confirm
    const [cancelResult, confirmResult] = await Promise.all([
        (async () => {
            const start = Date.now();
            const res = await api('POST', `/orders/${orderId}/cancel`, {
                token: doc.token,
                body: { reason: 'Changed my mind' },
            });
            return { action: 'cancel', success: res.success, error: res.error?.code, duration: Date.now() - start };
        })(),
        (async () => {
            const start = Date.now();
            const res = await api('PATCH', `/admin/orders/${orderId}/status`, {
                token: config.adminToken,
                body: { status: 'confirmed', notes: 'Admin confirmed' },
            });
            return { action: 'confirm', success: res.success, error: res.error?.code, duration: Date.now() - start };
        })(),
    ]);

    console.log(`   Cancel: ${cancelResult.success ? 'won' : 'lost'} (${cancelResult.duration}ms) ${cancelResult.error || ''}`);
    console.log(`   Confirm: ${confirmResult.success ? 'won' : 'lost'} (${confirmResult.duration}ms) ${confirmResult.error || ''}`);

    // Exactly one should succeed
    const totalSuccess = [cancelResult, confirmResult].filter(r => r.success).length;
    const pass = totalSuccess === 1;
    console.log(`   📊 Operations succeeded: ${totalSuccess} (expected: exactly 1)`);
    console.log(`   ${pass ? '✅ PASS' : '⚠️  CHECK'}: One operation should win\n`);

    await api('PATCH', `/admin/products/${product.id}`, {
        token: config.adminToken,
        body: { stock: product.stock },
    });

    return { name: 'Scenario 5: Cancel vs Update', pass, cancelResult, confirmResult };
}

// ─────────────────────────────────────────────────────────
// Scenario 6: Cancel During Checkout (Stock Restore vs Deduct)
// Doctor A cancels (restoring stock) while Doctor B checks out
// ─────────────────────────────────────────────────────────
async function scenario6_cancelDuringCheckout() {
    console.log('\n🏁 Scenario 6: Cancel During Checkout');
    console.log('   Doctor A cancels order while Doctor B checks out same product...\n');

    const docA = config.doctors[2];
    const docB = config.doctors[3];
    const product = config.products[0];
    if (!docA || !docB || !product) { console.log('   ⚠️  Missing data'); return; }

    // Set stock to 5
    await api('PATCH', `/admin/products/${product.id}`, {
        token: config.adminToken,
        body: { stock: 5 },
    });

    // Doctor A creates order for 3 items
    await api('DELETE', '/cart', { token: docA.token });
    await api('POST', '/cart/items', {
        token: docA.token,
        body: { productId: product.id, quantity: 3 },
    });
    const orderA = await api('POST', '/orders', {
        token: docA.token,
        body: { addressId: docA.addressId },
    });

    if (!orderA.success) {
        console.log('   ⚠️  Could not create order A:', orderA.error);
        return;
    }
    // Stock is now 2

    // Doctor B adds 4 items to cart (needs 4, only 2 available unless A cancels)
    await api('DELETE', '/cart', { token: docB.token });
    await api('POST', '/cart/items', {
        token: docB.token,
        body: { productId: product.id, quantity: 4 },
    });

    // Race: A cancels (restoring 3 → stock becomes 5) while B checkouts (needs 4)
    const [cancelRes, checkoutRes] = await Promise.all([
        (async () => {
            const start = Date.now();
            const res = await api('POST', `/orders/${orderA.data.id}/cancel`, {
                token: docA.token,
                body: { reason: 'Testing' },
            });
            return { action: 'cancel', success: res.success, error: res.error?.code, duration: Date.now() - start };
        })(),
        (async () => {
            const start = Date.now();
            const res = await api('POST', '/orders', {
                token: docB.token,
                body: { addressId: docB.addressId },
            });
            return { action: 'checkout', success: res.success, error: res.error?.code, duration: Date.now() - start };
        })(),
    ]);

    console.log(`   Cancel A: ${cancelRes.success ? 'succeeded' : 'failed'} (${cancelRes.duration}ms)`);
    console.log(`   Checkout B: ${checkoutRes.success ? 'succeeded' : 'failed'} (${checkoutRes.duration}ms)`);

    // Check final stock
    const finalProduct = await api('GET', `/products/${product.id}`, { token: docA.token });
    const finalStock = finalProduct.data?.stock ?? 'unknown';
    console.log(`   📊 Final stock: ${finalStock}`);

    // Stock should be consistent: never negative
    const pass = typeof finalStock === 'number' && finalStock >= 0;
    console.log(`   ${pass ? '✅ PASS' : '❌ FAIL'}: Stock is non-negative\n`);

    // Restore
    await api('PATCH', `/admin/products/${product.id}`, {
        token: config.adminToken,
        body: { stock: product.stock },
    });

    return { name: 'Scenario 6: Cancel During Checkout', pass, finalStock, cancelRes, checkoutRes };
}

// ─────────────────────────────────────────────────────────
// Run all race condition scenarios
// ─────────────────────────────────────────────────────────
async function main() {
    console.log('╔══════════════════════════════════════════════════════════╗');
    console.log('║         RACE CONDITION TESTS (Scenarios 1-6)           ║');
    console.log('╚══════════════════════════════════════════════════════════╝');

    const results = [];
    results.push(await scenario1_lastItemRace());
    results.push(await scenario2_doubleCheckout());
    results.push(await scenario3_discountRace());
    results.push(await scenario4_perUserDiscountRace());
    results.push(await scenario5_cancelVsUpdate());
    results.push(await scenario6_cancelDuringCheckout());

    console.log('\n╔══════════════════════════════════════════════════════════╗');
    console.log('║                    SUMMARY                              ║');
    console.log('╚══════════════════════════════════════════════════════════╝');
    results.filter(Boolean).forEach(r => {
        console.log(`  ${r.pass ? '✅' : '❌'} ${r.name}`);
    });
}

main().catch(e => { console.error('Fatal:', e); process.exit(1); });
