/**
 * Master runner — executes all load test scenario suites sequentially
 */
const { execSync } = require('child_process');
const path = require('path');

const suites = [
    'scenario-race-conditions.js',
    'scenario-throughput.js',
    'scenario-integrity.js',
    'scenario-stress.js',
];

console.log('╔══════════════════════════════════════════════════════════════╗');
console.log('║            OXFORD MEDICAL PLATFORM - LOAD TESTS            ║');
console.log('║                    Full Test Suite                          ║');
console.log('╚══════════════════════════════════════════════════════════════╝');
console.log(`\nStarted at: ${new Date().toISOString()}\n`);

for (const suite of suites) {
    const file = path.join(__dirname, suite);
    console.log(`\n${'━'.repeat(62)}`);
    console.log(`  Running: ${suite}`);
    console.log(`${'━'.repeat(62)}\n`);
    try {
        execSync(`node "${file}"`, { stdio: 'inherit', timeout: 300000 });
    } catch (e) {
        console.error(`\n❌ Suite ${suite} failed with exit code ${e.status}\n`);
    }
}

console.log(`\n${'━'.repeat(62)}`);
console.log(`  Completed at: ${new Date().toISOString()}`);
console.log(`${'━'.repeat(62)}\n`);
