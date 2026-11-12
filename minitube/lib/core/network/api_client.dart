import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../errors/app_exception.dart';

class ApiClient {
  static final shared = ApiClient();
  String? token;
  Uri uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${ApiConstants.baseUrl}$path').replace(queryParameters: query);
  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
  Future<dynamic> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    final req = http.Request(method, uri(path, query))..headers.addAll(headers);
    if (body != null) req.body = jsonEncode(body);
    final response = await http.Response.fromStream(
      await req.send().timeout(ApiConstants.timeout),
    );
    return decode(response);
  }

  dynamic decode(http.Response response) {
    final dynamic json = response.body.isEmpty
        ? null
        : jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw AppException(
        json?['error']?['message'] ?? 'Unable to complete request.',
        retryAfter: int.tryParse(
          '${json?['error']?['retryAfter'] ?? response.headers['retry-after'] ?? ''}',
        ),
      );
    }
    return json;
  }
}
