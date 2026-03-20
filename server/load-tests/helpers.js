const BASE = process.env.API_URL || 'http://localhost:3000/api/v1';

async function api(method, path, { token, body } = {}) {
    const headers = { 'Content-Type': 'application/json' };
    if (token) headers['Authorization'] = `Bearer ${token}`;
    const opts = { method, headers };
    if (body) opts.body = JSON.stringify(body);
    const res = await fetch(`${BASE}${path}`, opts);
    const json = await res.json().catch(() => ({}));
    return { status: res.status, ...json };
}

async function login(email, password) {
    const res = await api('POST', '/auth/login', { body: { email, password } });
    return res.data?.accessToken;
}

async function adminLogin() {
    const res = await api('POST', '/auth/admin/login', { body: { email: 'admin@medorder.com', password: 'admin123456' } });
    return res.data?.accessToken;
}

async function registerDoctor(i) {
    const email = `loadtest.doctor${i}@test.com`;
    const res = await api('POST', '/auth/register', {
        body: {
            fullName: `Load Test Doctor ${i}`,
            email,
            phone: `+2010000${String(i).padStart(4, '0')}`,
            password: 'Password123',
            clinicName: `Test Clinic ${i}`,
            specialty: 'General',
            city: 'Cairo',
        },
    });
    return { email, res };
}

function report(name, results) {
    const succeeded = results.filter(r => r.success).length;
    const failed = results.filter(r => !r.success).length;
    const errors = {};
    results.filter(r => !r.success).forEach(r => {
        const key = r.error || r.code || 'unknown';
        errors[key] = (errors[key] || 0) + 1;
    });
    const durations = results.map(r => r.duration).filter(Boolean).sort((a, b) => a - b);
    const p50 = durations[Math.floor(durations.length * 0.5)] || 0;
    const p95 = durations[Math.floor(durations.length * 0.95)] || 0;
    const p99 = durations[Math.floor(durations.length * 0.99)] || 0;

    console.log(`\n${'='.repeat(60)}`);
    console.log(`  ${name}`);
    console.log(`${'='.repeat(60)}`);
    console.log(`  Total: ${results.length} | Succeeded: ${succeeded} | Failed: ${failed}`);
    console.log(`  p50: ${p50}ms | p95: ${p95}ms | p99: ${p99}ms`);
    if (Object.keys(errors).length > 0) {
        console.log(`  Error breakdown:`);
        Object.entries(errors).forEach(([k, v]) => console.log(`    ${k}: ${v}`));
    }
    console.log(`${'='.repeat(60)}\n`);
    return { name, total: results.length, succeeded, failed, errors, p50, p95, p99 };
}

async function timed(fn) {
    const start = Date.now();
    try {
        const result = await fn();
        return { ...result, duration: Date.now() - start };
    } catch (e) {
        return { success: false, error: e.message, duration: Date.now() - start };
    }
}

async function concurrent(count, fn) {
    return Promise.all(Array.from({ length: count }, (_, i) => timed(() => fn(i))));
}

module.exports = { api, login, adminLogin, registerDoctor, report, timed, concurrent, BASE };
