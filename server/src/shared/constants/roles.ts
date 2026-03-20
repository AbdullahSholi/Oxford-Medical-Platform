// ═══════════════════════════════════════════════════════════
// MedOrder — Doctor Status & Role Constants
// ═══════════════════════════════════════════════════════════

export const DoctorStatus = {
    PENDING: 'pending',
    APPROVED: 'approved',
    REJECTED: 'rejected',
    SUSPENDED: 'suspended',
} as const;

export type DoctorStatusType = (typeof DoctorStatus)[keyof typeof DoctorStatus];

export const Roles = {
    DOCTOR: 'doctor',
    ADMIN: 'admin',
} as const;

export type RoleType = (typeof Roles)[keyof typeof Roles];
