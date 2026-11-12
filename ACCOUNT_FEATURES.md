# Huy - account features (development stage)

## Available now

- Edit Profile: display name, read-only email, phone number, birthday, gender, bio and HTTPS avatar image URL with fallback.
- Change password: current password required; 8-64 characters with letters and numbers; new password must differ. All MiniTube sessions and outstanding OTPs are revoked after success.
- Phone verification: save a phone in My Profile, then choose Verify saved phone.
- Forgot password: request OTP for a previously verified phone; set/confirm a new password; log in again.
- Google login/linking UI, Firebase client flow and server ID-token verification are implemented. Real Google sign-in is NOT enabled until a Firebase project is configured. There is no fake successful Google login.

Avatar currently uses an image URL, not a file-upload endpoint. Email is not editable because it is a login identifier. Phone changes clear verification; the new number must be verified again.

## Upgrade an existing checkout

Backend (from Server/):

```powershell
npm.cmd ci
npm.cmd run db:init
```

The migration adds user profile/Google fields, unique phone/Google identities and account_otps. It preserves existing users/media. The MySQL account running migrations needs ALTER/INDEX/CREATE privileges. If the runtime account has restricted privileges, have your local database administrator run the migration with appropriate credentials; do not permanently switch the backend to root.

For a fresh database, follow the root README, then npm run db:setup. The schema now includes the account fields.

## Local phone/OTP demo

In Server/.env set:

```dotenv
AUTH_DEV_MODE=true
```

Restart the backend. The application shows a clearly labelled DEVELOPMENT ONLY code. No SMS is sent and no SMS provider is configured. This feature is automatically blocked when NODE_ENV=production, even if AUTH_DEV_MODE=true.

1. Sign in, open My Profile, save your phone (Vietnamese 0901234567 normalizes to +84901234567).
2. Choose Verify saved phone, request a code, enter the displayed development code and confirm.
3. Log out. In Login choose Forgot password, enter the same verified number, request a NEW code, then set/confirm a new password.
4. Sign in using the new password.

OTP: 5 minutes, single-use, at most 5 incorrect attempts, 60-second resend cooldown. A newly requested code invalidates earlier codes for that purpose. Account endpoints are rate-limited. OTP hashes are stored in MySQL, not plaintext codes. Request responses for unregistered/unverified recovery numbers do not reveal whether the account exists; such challenges cannot reset an account.

Development OTP delivery is intentionally not suitable for real password recovery. Real SMS delivery needs a provider and a separate integration before deploying this feature outside local development.

## Configure real Google login later

Follow official Firebase guidance:

- https://firebase.google.com/docs/auth/flutter/federated-auth
- https://firebase.google.com/docs/auth/admin/verify-id-tokens

1. Create a Firebase project and enable Authentication > Google.
2. Register your web app and add localhost to authorized domains. For Android also register the matching application ID (currently com.example.minitube), SHA-1/SHA-256 signing fingerprints and obtain a Web OAuth client ID. Register other platforms separately if needed.
3. Backend .env: set FIREBASE_PROJECT_ID to the project ID. Restart the backend. The backend verifies Firebase token signature, project/audience, expiry, verified email and google.com provider; arbitrary email/client-supplied user IDs are never accepted as Google identity.
4. Copy minitube/firebase-config.example.json to firebase-config.local.json and fill in your Firebase CLIENT settings for the target platform. These are not service-account credentials.
5. From minitube/ run:

```powershell
flutter pub get
flutter run -d chrome --web-port=5000 --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=http://localhost:3000/api/v1 --dart-define-from-file=firebase-config.local.json
```

For Android choose the emulator device, use API_BASE_URL=http://10.0.2.2:3000/api/v1 and supply Android Firebase options plus GOOGLE_WEB_CLIENT_ID. Native Google login uses the official google_sign_in plugin; web uses the Firebase popup flow. Real Google login remains untested until valid project configuration is supplied.

A new Google identity creates a user/channel. If an existing password account has the same email, automatic merging is rejected: sign in with the password and choose Link Google account in My Profile. Only a verified Google identity with the same email can link. Google-only accounts can establish a local password via their verified-phone recovery flow.

Never commit service-account keys, private credentials or .env. firebase-config.local.json is ignored.

## APIs

| Method | Path under /api/v1 | Purpose |
| --- | --- | --- |
| GET | /auth/config | Development OTP and Google configuration status |
| POST | /auth/google | Firebase Google token -> MiniTube session |
| POST | /me/google | Link matching Google identity to current account |
| PUT | /me | Save extended profile; email remains unchanged |
| POST | /auth/change-password | Current/new password; revoke all sessions |
| POST | /me/phone/request | Request phone-verification challenge |
| POST | /me/phone/verify | Confirm saved phone |
| POST | /auth/forgot-password | Request password-reset challenge |
| POST | /auth/reset-password | OTP + new password; revoke all sessions |

## Checks

```powershell
# Server/, with MySQL/API and AUTH_DEV_MODE=true
npm.cmd test
node scripts/integration-account.mjs
# minitube/
flutter analyze
flutter test
```

The integration script creates a temporary account/phone and removes them afterward. It tests wrong/replayed/expired/locked OTPs, cooldown, persistence and session revocation. Do not run it repeatedly within one rate-limit window on the same API instance; use a separate local test server/TEST_API_URL when needed. The script does not send real SMS or use real Google credentials.
