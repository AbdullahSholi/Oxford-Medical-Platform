// ═══════════════════════════════════════════════════════════
// MedOrder — Database Seed Script
// Seeds initial data for local development
// Run: npm run db:seed
// ═══════════════════════════════════════════════════════════

import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import bcrypt from 'bcryptjs';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(__dirname, '../.env') });

const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL! });
const prisma = new PrismaClient({ adapter });

async function main() {
    console.log('🌱 Seeding database...');

    // ── Create Admin ──────────────────────────────────────
    const adminPassword = await bcrypt.hash('admin123456', 12);
    const admin = await prisma.admin.upsert({
        where: { email: 'admin@medorder.com' },
        update: {},
        create: {
            email: 'admin@medorder.com',
            passwordHash: adminPassword,
            fullName: 'System Administrator',
            role: 'super_admin',
        },
    });
    console.log(`✅ Admin created: ${admin.email}`);

    // ── Create Categories ─────────────────────────────────
    const categories = await Promise.all([
        prisma.category.upsert({
            where: { slug: 'surgical-supplies' },
            update: {},
            create: { name: 'Surgical Supplies', slug: 'surgical-supplies', sortOrder: 1 },
        }),
        prisma.category.upsert({
            where: { slug: 'injectable-supplies' },
            update: {},
            create: { name: 'Injectable Supplies', slug: 'injectable-supplies', sortOrder: 2 },
        }),
        prisma.category.upsert({
            where: { slug: 'diagnostic-equipment' },
            update: {},
            create: { name: 'Diagnostic Equipment', slug: 'diagnostic-equipment', sortOrder: 3 },
        }),
        prisma.category.upsert({
            where: { slug: 'wound-care' },
            update: {},
            create: { name: 'Wound Care', slug: 'wound-care', sortOrder: 4 },
        }),
        prisma.category.upsert({
            where: { slug: 'personal-protective' },
            update: {},
            create: { name: 'Personal Protective Equipment', slug: 'personal-protective', sortOrder: 5 },
        }),
        prisma.category.upsert({
            where: { slug: 'lab-supplies' },
            update: {},
            create: { name: 'Lab Supplies', slug: 'lab-supplies', sortOrder: 6 },
        }),
    ]);
    console.log(`✅ ${categories.length} categories created`);

    // ── Create Brands ─────────────────────────────────────
    const brands = await Promise.all([
        prisma.brand.upsert({
            where: { slug: 'medigrip' },
            update: {},
            create: { name: 'MEDIGRIP', slug: 'medigrip', description: 'Premium surgical supplies' },
        }),
        prisma.brand.upsert({
            where: { slug: 'surgicare' },
            update: {},
            create: { name: 'SurgiCare', slug: 'surgicare', description: 'Professional surgical instruments' },
        }),
        prisma.brand.upsert({
            where: { slug: 'medline' },
            update: {},
            create: { name: 'Medline', slug: 'medline', description: 'Trusted medical products' },
        }),
    ]);
    console.log(`✅ ${brands.length} brands created`);

    // ── Create Sample Products ────────────────────────────
    const products = [
        {
            name: 'Sterile Surgical Gloves (Box of 100)',
            slug: 'sterile-surgical-gloves-100',
            sku: 'MED-SG-001',
            description: 'Premium powder-free sterile surgical gloves, latex, smooth texture.',
            price: 45.00,
            salePrice: 38.50,
            stock: 250,
            categoryId: categories[0].id,
            brandId: brands[0].id,
            medicalDetails: {
                material: 'Latex',
                sterile: true,
                latex_free: false,
                certifications: ['CE', 'ISO 13485'],
                pack_size: '100 pairs',
                storage_instructions: 'Store below 25°C, away from direct sunlight',
            },
        },
        {
            name: 'Disposable Syringes 5ml (Pack of 100)',
            slug: 'disposable-syringes-5ml-100',
            sku: 'MED-SY-002',
            description: 'Single-use sterile syringes with luer lock, 5ml capacity.',
            price: 12.50,
            stock: 500,
            categoryId: categories[1].id,
            brandId: brands[2].id,
            medicalDetails: {
                material: 'Polypropylene',
                sterile: true,
                latex_free: true,
                capacity: '5ml',
                certifications: ['CE', 'FDA'],
                pack_size: '100 units',
            },
        },
        {
            name: 'Digital Blood Pressure Monitor',
            slug: 'digital-bp-monitor',
            sku: 'MED-BP-003',
            description: 'Professional-grade automatic digital blood pressure monitor with memory function.',
            price: 89.99,
            salePrice: 74.99,
            stock: 45,
            categoryId: categories[2].id,
            brandId: brands[1].id,
            medicalDetails: {
                measurement_range: '0-299 mmHg',
                accuracy: '±3 mmHg',
                memory: '120 readings',
                power: 'AA batteries / USB',
                certifications: ['CE', 'FDA', 'ISO 13485'],
            },
        },
        {
            name: 'Sterile Wound Dressing 10x10cm (Pack of 50)',
            slug: 'sterile-wound-dressing-10x10-50',
            sku: 'MED-WD-004',
            description: 'Adhesive sterile wound dressing, hypoallergenic, breathable.',
            price: 28.00,
            stock: 180,
            categoryId: categories[3].id,
            brandId: brands[2].id,
            medicalDetails: {
                size: '10cm x 10cm',
                material: 'Non-woven',
                sterile: true,
                latex_free: true,
                hypoallergenic: true,
                pack_size: '50 units',
            },
        },
        {
            name: 'N95 Respirator Masks (Box of 20)',
            slug: 'n95-respirator-masks-20',
            sku: 'MED-PP-005',
            description: 'NIOSH-approved N95 particulate respirator masks for medical professionals.',
            price: 35.00,
            stock: 8,
            lowStockThreshold: 10,
            categoryId: categories[4].id,
            brandId: brands[0].id,
            medicalDetails: {
                filtration: '≥95% of airborne particles',
                certifications: ['NIOSH N95', 'CE'],
                fit_test: 'Required',
                pack_size: '20 masks',
                latex_free: true,
            },
        },
    ];

    for (const product of products) {
        await prisma.product.upsert({
            where: { sku: product.sku },
            update: {},
            create: product,
        });
    }
    console.log(`✅ ${products.length} products created`);

    // ── Create Sample Doctor ──────────────────────────────
    const doctorPassword = await bcrypt.hash('doctor123456', 12);
    const doctor = await prisma.doctor.upsert({
        where: { email: 'dr.ahmad@clinic.com' },
        update: {},
        create: {
            fullName: 'Dr. Ahmad Khalil',
            email: 'dr.ahmad@clinic.com',
            phone: '+970599000001',
            passwordHash: doctorPassword,
            clinicName: 'Al-Shifa Medical Center',
            specialty: 'General Surgery',
            city: 'Ramallah',
            clinicAddress: 'Al-Irsal Street, Building 15, 2nd Floor',
            licenseUrl: 'licenses/dr-ahmad-license.jpg',
            status: 'approved',
            approvedAt: new Date(),
            approvedBy: admin.id,
        },
    });
    console.log(`✅ Doctor created: ${doctor.email}`);

    // ── Create Sample Discount ────────────────────────────
    const discount = await prisma.discount.upsert({
        where: { code: 'WELCOME20' },
        update: {},
        create: {
            code: 'WELCOME20',
            description: '20% off your first order',
            type: 'percentage',
            value: 20,
            minOrderAmount: 50,
            maxDiscount: 100,
            usageLimit: 1000,
            perUserLimit: 1,
            startsAt: new Date(),
            endsAt: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000), // 90 days
        },
    });
    console.log(`✅ Discount created: ${discount.code}`);

    // ── Create Banners ───────────────────────────────────
    const bannerData = [
        {
            title: 'Summer Sale — Up to 40% Off',
            subtitle: 'Huge discounts on surgical supplies',
            imageUrl: '/banners/summer-sale.jpg',
            position: 'home_slider' as const,
            sortOrder: 1,
            startsAt: new Date(),
            endsAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        },
        {
            title: 'New Arrivals: Diagnostic Equipment',
            imageUrl: '/banners/diagnostic-new.jpg',
            position: 'home_slider' as const,
            sortOrder: 2,
        },
        {
            title: 'Free Delivery on Orders Over $100',
            subtitle: 'Limited time offer',
            imageUrl: '/banners/free-delivery.jpg',
            position: 'category_banner' as const,
            sortOrder: 1,
        },
    ];

    for (const banner of bannerData) {
        await prisma.banner.create({ data: banner });
    }
    console.log(`✅ ${bannerData.length} banners created`);

    // ── Create Sample Notification ────────────────────────
    await prisma.notification.create({
        data: {
            doctorId: doctor.id,
            type: 'system',
            title: 'Welcome to MedOrder!',
            body: 'Your account has been approved. Start browsing our medical supplies catalog.',
            data: { action: 'navigate', target: '/products' },
        },
    });
    console.log('✅ Sample notification created');

    // ── Ensure Cart for Doctor ───────────────────────────
    await prisma.cart.upsert({
        where: { doctorId: doctor.id },
        update: {},
        create: { doctorId: doctor.id },
    });
    console.log('✅ Cart ensured for doctor');

    console.log('\n🎉 Seeding completed successfully!');
}

main()
    .catch((e) => {
        console.error('❌ Seed failed:', e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
