import 'package:flutter/material.dart';

import '../../../core/domain/models.dart';
import '../domain/repositories/auth_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController(this.repository);
  final AuthRepository repository;
  User? user;
  bool busy = false;
  Future<void> run(Future<User> Function() action) async {
    if (busy) return;
    busy = true;
    notifyListeners();
    try {
      user = await action();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    if (busy) return;
    busy = true;
    notifyListeners();
    try {
      await repository.logout();
    } finally {
      user = null;
      busy = false;
      notifyListeners();
    }
  }
}

class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    super.key,
    required AuthController controller,
    required super.child,
  }) : super(notifier: controller);
  static AuthController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthScope>()!.notifier!;
}
