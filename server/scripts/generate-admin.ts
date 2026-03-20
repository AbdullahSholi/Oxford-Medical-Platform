// ═══════════════════════════════════════════════════════════
// MedOrder — Generate Initial Admin User
// Run: npx tsx scripts/generate-admin.ts
// ═══════════════════════════════════════════════════════════

import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
    const email = process.argv[2] || 'admin@medorder.com';
    const password = process.argv[3] || 'admin123456';
    const name = process.argv[4] || 'System Administrator';

    const passwordHash = await bcrypt.hash(password, 12);

    const admin = await prisma.admin.upsert({
        where: { email },
        update: { passwordHash, fullName: name },
        create: {
            email,
            passwordHash,
            fullName: name,
            role: 'super_admin',
        },
    });

    console.log(`✅ Admin created/updated:`);
    console.log(`   Email: ${admin.email}`);
    console.log(`   Name:  ${admin.fullName}`);
    console.log(`   Role:  ${admin.role}`);
    console.log(`   ID:    ${admin.id}`);
}

main()
    .catch(console.error)
    .finally(async () => {
        await prisma.$disconnect();
    });
