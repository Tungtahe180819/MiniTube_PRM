abstract final class ApiConstants {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api/v1',
  );
  static const useMock = bool.fromEnvironment('USE_MOCK', defaultValue: true);
  static const timeout = Duration(seconds: 15);
  static const pageSize = 20;
}
