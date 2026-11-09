import '../../../../core/domain/models.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/repositories/auth_repository.dart';

/// In-memory demo adapter. Never use this credential store in production.
class MockAuthRepository implements AuthRepository {
  final Map<String, (User, String)> _accounts = {
    'studio@minitube.app': (
      const User(
        id: '2',
        email: 'studio@minitube.app',
        displayName: 'Everyday Studio',
      ),
      'Studio1234',
    ),
    'demo@minitube.app': (
      const User(
        id: '1',
        email: 'demo@minitube.app',
        displayName: 'Demo Creator',
      ),
      'Demo1234',
    ),
  };
  String? _email;
  Future<void> _wait() =>
      Future<void>.delayed(const Duration(milliseconds: 350));
  @override
  Future<User> login(String email, String password) async {
    await _wait();
    final key = email.trim().toLowerCase();
    final account = _accounts[key];
    if (account == null || account.$2 != password) {
      throw const AppException('The email or password is incorrect.');
    }
    _email = key;
    return account.$1;
  }

  @override
  Future<User> register(String name, String email, String password) async {
    await _wait();
    final key = email.trim().toLowerCase();
    if (_accounts.containsKey(key)) {
      throw const AppException('This email is already in use.');
    }
    final user = User(
      id: '${_accounts.length + 1}',
      email: key,
      displayName: name.trim(),
    );
    _accounts[key] = (user, password);
    _email = key;
    return user;
  }

  @override
  Future<User> updateProfile(String name, String? avatarUrl) async {
    await _wait();
    final old = _accounts[_email];
    if (old == null) throw const AppException('Your session has expired.');
    final url = avatarUrl?.trim();
    final user = User(
      id: old.$1.id,
      email: old.$1.email,
      displayName: name.trim(),
      avatarUrl: url == null || url.isEmpty ? null : url,
    );
    _accounts[_email!] = (user, old.$2);
    return user;
  }

  @override
  Future<void> logout() async {
    await _wait();
    _email = null;
  }
}
