import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/errors/app_exception.dart';

abstract final class GoogleIdentity {
  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const senderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  static Future<void>? googleInitialization;
  static bool get configured =>
      [apiKey, appId, projectId, senderId].every((v) => v.isNotEmpty);
  static Future<String> token() async {
    if (!configured) {
      throw const AppException(
        'Google login is not configured yet. Configure Firebase to use a real Google account.',
      );
    }
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: apiKey,
          appId: appId,
          messagingSenderId: senderId,
          projectId: projectId,
          authDomain: '$projectId.firebaseapp.com',
        ),
      );
    }
    final auth = FirebaseAuth.instance;
    try {
      final provider = GoogleAuthProvider()
        ..setCustomParameters({'prompt': 'select_account'});
      UserCredential credential;
      if (kIsWeb) {
        credential = await auth.signInWithPopup(provider);
      } else {
        if (webClientId.isEmpty) {
          throw const AppException(
            'Android Google login also needs GOOGLE_WEB_CLIENT_ID and registered signing fingerprints.',
          );
        }
        googleInitialization ??= GoogleSignIn.instance.initialize(
          serverClientId: webClientId,
        );
        await googleInitialization;
        final account = await GoogleSignIn.instance.authenticate();
        credential = await auth.signInWithCredential(
          GoogleAuthProvider.credential(
            idToken: account.authentication.idToken,
          ),
        );
      }
      final token = await credential.user?.getIdToken(true);
      if (token == null) {
        throw const AppException('Google login did not return a credential.');
      }
      return token;
    } finally {
      await auth.signOut();
      if (!kIsWeb && googleInitialization != null) {
        await GoogleSignIn.instance.signOut();
      }
    }
  }
}
