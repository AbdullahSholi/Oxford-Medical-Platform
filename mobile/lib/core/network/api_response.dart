class ApiResponse<T> {
  final T? data;
  final String? message;
  final bool success;
  final ApiError? error;

  const ApiResponse._({
    this.data,
    this.message,
    required this.success,
    this.error,
  });

  factory ApiResponse.success(T data, {String? message}) {
    return ApiResponse._(data: data, success: true, message: message);
  }

  factory ApiResponse.error(ApiError error) {
    return ApiResponse._(success: false, error: error);
  }
}

class ApiError {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  const ApiError({
    required this.message,
    this.statusCode,
    this.errors,
  });
}

class PaginatedResponse<T> {
  final List<T> items;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;

  const PaginatedResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });
}
