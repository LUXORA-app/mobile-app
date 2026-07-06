class ApiResponse<T> {
  const ApiResponse({
    this.data,
    this.message,
    this.statusCode,
    this.errors,
  });

  final T? data;
  final String? message;
  final int? statusCode;
  final Map<String, List<String>>? errors;

  bool get isSuccess => statusCode != null && statusCode! >= 200 && statusCode! < 300;
  bool get hasValidationErrors => errors != null && errors!.isNotEmpty;

  factory ApiResponse.success({
    T? data,
    String? message,
    int? statusCode,
  }) {
    return ApiResponse<T>(
      data: data,
      message: message,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.failure({
    String? message,
    int? statusCode,
    Map<String, List<String>>? errors,
  }) {
    return ApiResponse<T>(
      message: message,
      statusCode: statusCode,
      errors: errors,
    );
  }
}
