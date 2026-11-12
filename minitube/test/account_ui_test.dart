import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minitube/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:minitube/features/auth/data/services/google_identity.dart';
import 'package:minitube/features/auth/presentation/auth_controller.dart';
import 'package:minitube/features/auth/presentation/pages/password_page.dart';
import 'package:minitube/core/errors/app_exception.dart';

class DemoRecovery extends MockAuthRepository {
  List<String>? reset;
  @override
  Future<Map<String, dynamic>> requestPhoneCode(
    String phone, {
    bool reset = false,
  }) async => {
    'challengeId': 'demo-challenge',
    'developmentCode': '123456',
    'retryAfter': 60,
  };
  @override
  Future<void> resetPassword(
    String challenge,
    String code,
    String password,
  ) async {
    reset = [challenge, code, password];
  }
}

class CooldownRecovery extends DemoRecovery {
  @override
  Future<Map<String, dynamic>> requestPhoneCode(
    String phone, {
    bool reset = false,
  }) async {
    throw const AppException(
      'Wait 2 seconds before requesting another code.',
      retryAfter: 2,
    );
  }
}

void main() {
  testWidgets(
    'Server cooldown disables request then unlocks after remaining seconds',
    (tester) async {
      final auth = AuthController(CooldownRecovery());
      await tester.pumpWidget(
        AuthScope(
          controller: auth,
          child: const MaterialApp(home: PasswordPage(reset: true)),
        ),
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Phone number'),
        '+84901234567',
      );
      await tester.tap(find.text('Request code'));
      await tester.pump();
      expect(find.text('Resend in 2s'), findsOneWidget);
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Resend in 2s'),
            )
            .onPressed,
        isNull,
      );
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Request code'), findsOneWidget);
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Request code'),
            )
            .onPressed,
        isNotNull,
      );
      await tester.pumpWidget(const SizedBox());
      auth.dispose();
    },
  );
  test('Missing Firebase config reports an explicit error without fake Google login', () async {
    await expectLater(GoogleIdentity.token(), throwsA(isA<AppException>()));
  });
  testWidgets(
    'Recovery shows development-only OTP and validates password confirmation',
    (tester) async {
      final repository = DemoRecovery();
      final auth = AuthController(repository);
      await tester.pumpWidget(
        AuthScope(
          controller: auth,
          child: const MaterialApp(home: PasswordPage(reset: true)),
        ),
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Phone number'),
        '+84901234567',
      );
      await tester.tap(find.text('Request code'));
      await tester.pump();
      expect(find.textContaining('No SMS sent.'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Verification code'),
        '123456',
      );
      await tester.ensureVisible(
        find.widgetWithText(TextFormField, 'New password'),
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'New password'),
        'Password123',
      );
      await tester.ensureVisible(
        find.widgetWithText(TextFormField, 'Confirm new password'),
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm new password'),
        'Different123',
      );
      await tester.ensureVisible(find.text('Save new password'));
      await tester.tap(find.text('Save new password'));
      await tester.pump();
      expect(repository.reset, isNull);
      await tester.ensureVisible(
        find.widgetWithText(TextFormField, 'Confirm new password'),
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm new password'),
        'Password123',
      );
      await tester.ensureVisible(find.text('Save new password'));
      await tester.tap(find.text('Save new password'));
      await tester.pump();
      expect(repository.reset, ['demo-challenge', '123456', 'Password123']);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      auth.dispose();
    },
  );
}
