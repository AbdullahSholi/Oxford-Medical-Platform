export interface PaginationMeta {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
    hasNext: boolean;
    hasPrev: boolean;
}

export interface PaginatedResult<T> {
    data: T[];
    meta: PaginationMeta;
}

export interface TokenPair {
    accessToken: string;
    refreshToken: string;
}

export interface JwtPayload {
    sub: string;
    role: string;
    jti: string;
    iat: number;
    exp: number;
}
