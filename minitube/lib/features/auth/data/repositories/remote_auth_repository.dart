import '../../../../core/domain/models.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/repositories/auth_repository.dart';
import '../services/google_identity.dart';

class RemoteAuthRepository extends AuthRepository {
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
  Future<User> updateProfile(
    String name,
    String? avatarUrl, {
    String? phoneNumber,
    String? dateOfBirth,
    String? gender,
    String? bio,
  }) async => User.fromJson(
    (await api.request(
      'PUT',
      '/me',
      body: {
        'displayName': name,
        'avatarUrl': avatarUrl,
        'phoneNumber': ?phoneNumber,
        'dateOfBirth': ?dateOfBirth,
        'gender': ?gender,
        'bio': ?bio,
      },
    ))['data'],
  );
  @override
  Future<User> googleLogin() async =>
      authenticate('/auth/google', {'idToken': await GoogleIdentity.token()});
  @override
  Future<User> linkGoogle() async => User.fromJson(
    (await api.request(
      'POST',
      '/me/google',
      body: {'idToken': await GoogleIdentity.token()},
    ))['data'],
  );
  @override
  Future<void> changePassword(String current, String next) async {
    await api.request(
      'POST',
      '/auth/change-password',
      body: {'currentPassword': current, 'newPassword': next},
    );
    api.token = null;
  }

  @override
  Future<Map<String, dynamic>> requestPhoneCode(
    String phone, {
    bool reset = false,
  }) async => Map<String, dynamic>.from(
    (await api.request(
      'POST',
      reset ? '/auth/forgot-password' : '/me/phone/request',
      body: {'phoneNumber': phone},
    ))['data'],
  );
  @override
  Future<User> verifyPhone(String challenge, String code) async =>
      User.fromJson(
        (await api.request(
          'POST',
          '/me/phone/verify',
          body: {'challengeId': challenge, 'code': code},
        ))['data'],
      );
  @override
  Future<void> resetPassword(
    String challenge,
    String code,
    String password,
  ) async {
    await api.request(
      'POST',
      '/auth/reset-password',
      body: {'challengeId': challenge, 'code': code, 'newPassword': password},
    );
    api.token = null;
  }

  @override
  Future<void> logout() async {
    try {
      await api.request('POST', '/auth/logout');
    } finally {
      api.token = null;
    }
  }
}
