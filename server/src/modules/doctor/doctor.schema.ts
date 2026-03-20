import { z } from 'zod';

export const updateProfileSchema = z.object({
    fullName: z.string().min(3).max(200).optional(),
    phone: z.string().regex(/^\+?[1-9]\d{7,14}$/).optional(),
    clinicName: z.string().min(2).max(300).optional(),
    specialty: z.string().min(2).max(100).optional(),
    city: z.string().min(2).max(100).optional(),
    clinicAddress: z.string().min(5).optional(),
    fcmToken: z.string().optional(),
});

export const createAddressSchema = z.object({
    label: z.string().min(1).max(50),
    recipientName: z.string().min(2).max(200),
    phone: z.string().regex(/^\+?[1-9]\d{7,14}$/),
    city: z.string().min(2).max(100),
    streetAddress: z.string().min(5),
    buildingInfo: z.string().optional(),
    landmark: z.string().optional(),
    latitude: z.number().min(-90).max(90).optional(),
    longitude: z.number().min(-180).max(180).optional(),
    isDefault: z.boolean().optional().default(false),
});

export const updateAddressSchema = createAddressSchema.partial();

export type UpdateProfileInput = z.infer<typeof updateProfileSchema>;
export type CreateAddressInput = z.infer<typeof createAddressSchema>;
export type UpdateAddressInput = z.infer<typeof updateAddressSchema>;
