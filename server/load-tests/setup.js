/**
 * Setup script: creates test doctors, sets up low-stock products, creates limited discounts
 */
const { api, adminLogin, registerDoctor, login } = require('./helpers');

const NUM_TEST_DOCTORS = 50;

async function setup() {
    console.log('🔧 Setting up load test data...\n');

    // 1. Get admin token
    const adminToken = await adminLogin();
    if (!adminToken) throw new Error('Admin login failed');
    console.log('✅ Admin logged in');

    // 2. Register test doctors
    console.log(`\n📋 Registering ${NUM_TEST_DOCTORS} test doctors...`);
    const doctorResults = [];
    // Register in batches of 10 to avoid overwhelming
    for (let batch = 0; batch < NUM_TEST_DOCTORS; batch += 10) {
        const promises = [];
        for (let i = batch; i < Math.min(batch + 10, NUM_TEST_DOCTORS); i++) {
            promises.push(registerDoctor(i));
        }
        const results = await Promise.all(promises);
        doctorResults.push(...results);
        const ok = results.filter(r => r.res.success || r.res.error?.code === 'DUPLICATE_EMAIL').length;
        console.log(`  Batch ${batch / 10 + 1}: ${ok}/${results.length} ok`);
    }

    // 3. Approve all test doctors
    console.log('\n📋 Approving test doctors...');
    const allDoctors = await api('GET', '/admin/doctors?limit=100', { token: adminToken });
    const testDoctors = (allDoctors.data || []).filter(d => d.email.startsWith('loadtest.doctor'));
    let approved = 0;
    for (const doc of testDoctors) {
        if (doc.status !== 'approved') {
            await api('PATCH', `/admin/doctors/${doc.id}/approve`, { token: adminToken });
            approved++;
        }
    }
    console.log(`  Approved ${approved} doctors (${testDoctors.length} total test doctors)`);

    // 4. Login all test doctors and create addresses
    console.log('\n📋 Logging in doctors and creating addresses...');
    const tokens = [];
    for (let i = 0; i < NUM_TEST_DOCTORS; i++) {
        const token = await login(`loadtest.doctor${i}@test.com`, 'Password123');
        if (token) {
            tokens.push({ index: i, token });
            // Create address if none exists
            const addrs = await api('GET', '/doctors/me/addresses', { token });
            if (!addrs.data || addrs.data.length === 0) {
                await api('POST', '/doctors/me/addresses', {
                    token,
                    body: {
                        label: 'Clinic',
                        recipientName: `Dr. Test ${i}`,
                        phone: `+2010000${String(i).padStart(4, '0')}`,
                        city: 'Cairo',
                        streetAddress: `${i} Test Street`,
                        buildingInfo: 'Floor 1',
                        isDefault: true,
                    },
                });
            }
        }
    }
    console.log(`  ${tokens.length} doctors logged in with addresses`);

    // 5. Get product & address data for test config
    const products = await api('GET', '/products', { token: tokens[0]?.token });
    const productIds = (products.data || []).map(p => ({ id: p.id, name: p.name, stock: p.stock, price: p.price }));
    console.log(`\n📦 Available products: ${productIds.length}`);
    productIds.forEach(p => console.log(`  ${p.name}: stock=${p.stock}, price=${p.price}`));

    // Get addresses for each doctor
    const doctorData = [];
    for (const t of tokens) {
        const addrs = await api('GET', '/doctors/me/addresses', { token: t.token });
        const addr = (addrs.data || [])[0];
        if (addr) {
            doctorData.push({ index: t.index, token: t.token, addressId: addr.id });
        }
    }

    // 6. Get discounts
    const discounts = await api('GET', '/admin/discounts', { token: adminToken });
    console.log(`\n🏷️  Discounts: ${(discounts.data || []).length}`);
    (discounts.data || []).forEach(d => console.log(`  ${d.code}: limit=${d.usageLimit}, used=${d.usedCount}`));

    // Save config
    const config = {
        adminToken,
        doctors: doctorData,
        products: productIds,
        discounts: (discounts.data || []).map(d => ({ id: d.id, code: d.code })),
        createdAt: new Date().toISOString(),
    };

    const fs = require('fs');
    fs.writeFileSync(__dirname + '/test-config.json', JSON.stringify(config, null, 2));
    console.log(`\n✅ Setup complete! Config saved. ${doctorData.length} doctors ready.`);
    return config;
}

setup().catch(e => { console.error('Setup failed:', e); process.exit(1); });
