import { PrismaClient, BannerPosition } from '@prisma/client';
import { CreateBannerInput } from './banner.schema';

export class BannerRepository {
    constructor(private prisma: PrismaClient) { }

    async findActive() {
        const now = new Date();
        return this.prisma.banner.findMany({
            where: {
                isActive: true,
                OR: [
                    { startsAt: null },
                    { startsAt: { lte: now } },
                ],
                AND: [
                    {
                        OR: [
                            { endsAt: null },
                            { endsAt: { gte: now } },
                        ],
                    },
                ],
            },
            orderBy: { sortOrder: 'asc' },
        });
    }

    async findAll() {
        return this.prisma.banner.findMany({
            orderBy: [{ sortOrder: 'asc' }, { createdAt: 'desc' }],
        });
    }

    async findById(id: string) {
        return this.prisma.banner.findUnique({ where: { id } });
    }

    async create(data: CreateBannerInput) {
        return this.prisma.banner.create({
            data: {
                title: data.title,
                subtitle: data.subtitle,
                imageUrl: data.imageUrl,
                linkType: data.linkType,
                linkTarget: data.linkTarget,
                position: data.position as BannerPosition,
                sortOrder: data.sortOrder,
                startsAt: data.startsAt,
                endsAt: data.endsAt,
            },
        });
    }

    async update(id: string, data: Record<string, unknown>) {
        return this.prisma.banner.update({
            where: { id },
            data,
        });
    }

    async delete(id: string) {
        return this.prisma.banner.delete({ where: { id } });
    }
}
