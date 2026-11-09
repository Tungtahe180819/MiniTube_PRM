import '../../../../core/domain/models.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/repositories/auth_repository.dart';

class RemoteAuthRepository implements AuthRepository {
  final api = ApiClient.shared;
  Future<User> authenticate(String path, Map<String, dynamic> body) async {
    final result = await api.request('POST', path, body: body);
    api.token = result['data']['token'];
    return User.fromJson(result['data']['user']);
  }

  @override
  Future<User> login(String email, String password) => authenticate(
    '/auth/login',
    {'email': email.trim(), 'password': password},
  );
  @override
  Future<User> register(String name, String email, String password) =>
      authenticate('/auth/register', {
        'displayName': name.trim(),
        'email': email.trim(),
        'password': password,
      });
  @override
  Future<User> updateProfile(String name, String? avatarUrl) async =>
      User.fromJson(
        (await api.request(
          'PUT',
          '/me',
          body: {'displayName': name, 'avatarUrl': avatarUrl},
        ))['data'],
      );
  @override
  Future<void> logout() async {
    try {
      await api.request('POST', '/auth/logout');
    } finally {
      api.token = null;
    }
  }
}
