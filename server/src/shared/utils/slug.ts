// ═══════════════════════════════════════════════════════════
// MedOrder — URL-Safe Slug Generator
// ═══════════════════════════════════════════════════════════

export function generateSlug(text: string): string {
    return text
        .toLowerCase()
        .trim()
        .replace(/[^\w\s-]/g, '')    // Remove non-word chars except spaces and hyphens
        .replace(/[\s_]+/g, '-')      // Replace spaces and underscores with hyphens
        .replace(/-+/g, '-')          // Replace multiple hyphens with single
        .replace(/^-+|-+$/g, '');     // Trim leading/trailing hyphens
}

export function generateUniqueSlug(text: string, suffix?: string): string {
    const base = generateSlug(text);
    return suffix ? `${base}-${suffix}` : base;
}
