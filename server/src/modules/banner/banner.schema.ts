import { z } from 'zod';

export const createBannerSchema = z.object({
    title: z.string().min(1).max(200).optional(),
    subtitle: z.string().max(500).optional(),
    imageUrl: z.string().url(),
    linkType: z.string().max(50).optional(),
    linkTarget: z.string().max(500).optional(),
    position: z.enum(['home_slider', 'category_banner', 'flash_sale']).default('home_slider'),
    sortOrder: z.number().int().min(0).default(0),
    startsAt: z.coerce.date().optional(),
    endsAt: z.coerce.date().optional(),
});

export const updateBannerSchema = createBannerSchema.partial();

export type CreateBannerInput = z.infer<typeof createBannerSchema>;
export type UpdateBannerInput = z.infer<typeof updateBannerSchema>;
