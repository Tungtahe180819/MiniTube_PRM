class AppException implements Exception {
  const AppException(this.message, {this.code, this.fields = const {}});
  final String message;
  final String? code;
  final Map<String, String> fields;
  @override
  String toString() => message;
}
