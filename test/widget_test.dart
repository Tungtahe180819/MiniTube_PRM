import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minitube/app/app.dart';
import 'package:minitube/features/auth/data/repositories/auth_repository_impl.dart';

void main() {
  test(
    'Register normalizes email and rejects duplicates; logout clears session',
    () async {
      final repo = MockAuthRepository();
      final user = await repo.register(
        'New Creator',
        ' TEST@example.com ',
        'Password1',
      );
      expect(user.email, 'test@example.com');
      await expectLater(
        repo.register('Other', 'test@example.com', 'Password1'),
        throwsException,
      );
      await repo.logout();
      await expectLater(repo.updateProfile('Other', null), throwsException);
      final again = await repo.login('test@example.com', 'Password1');
      expect(again.displayName, 'New Creator');
    },
  );
  testWidgets('Login validates, authenticates, saves profile and logs out', (
    tester,
  ) async {
    await tester.pumpWidget(const MiniTubeApp());
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'demo@minitube.app',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'Demo1234');
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
    await tester.tap(find.byIcon(Icons.home));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Login'), findsNothing);
    await tester.tap(find.byTooltip('My profile'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Login'), findsNothing);
    expect(find.text('demo@minitube.app'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Updated Creator');
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();
    expect(find.text('Changes saved.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Log out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Login to manage your profile'), findsOneWidget);
    expect(find.text('demo@minitube.app'), findsNothing);
    expect(find.byTooltip('Login'), findsOneWidget);
  });
}


