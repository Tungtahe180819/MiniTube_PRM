import '../../../../core/domain/models.dart';
import '../../../../core/errors/app_exception.dart';

abstract class AuthRepository {
  Future<User> login(String email, String password);
  Future<User> register(String name, String email, String password);
  Future<User> updateProfile(
    String name,
    String? avatarUrl, {
    String? phoneNumber,
    String? dateOfBirth,
    String? gender,
    String? bio,
  });
  Future<User> googleLogin() async => throw const AppException(
    'Google login requires API mode and Firebase configuration.',
  );
  Future<User> linkGoogle() async => throw const AppException(
    'Google linking requires API mode and Firebase configuration.',
  );
  Future<void> changePassword(String current, String next) async =>
      throw const AppException('Change password requires API mode.');
  Future<Map<String, dynamic>> requestPhoneCode(
    String phone, {
    bool reset = false,
  }) async => throw const AppException('Phone verification requires API mode.');
  Future<User> verifyPhone(String challenge, String code) async =>
      throw const AppException('Phone verification requires API mode.');
  Future<void> resetPassword(
    String challenge,
    String code,
    String password,
  ) async => throw const AppException('Password reset requires API mode.');
  Future<void> logout();
}
