class AppException implements Exception {
  const AppException(
    this.message, {
    this.code,
    this.fields = const {},
    this.retryAfter,
  });
  final String message;
  final String? code;
  final int? retryAfter;
  final Map<String, String> fields;
  @override
  String toString() => message;
}
