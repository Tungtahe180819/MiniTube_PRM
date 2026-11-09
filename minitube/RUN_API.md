# Run MiniTube with the real API

## Backend

From D:\FALL26\PRM393\PRJ_PRM\Server, configure .env using .env.example, start MySQL, then run:

```powershell
npm.cmd install
npm.cmd run db:init
npm.cmd start
```

Do not commit .env or storage. Read ../Server/README.md before initializing an existing database.

## Chrome

```powershell
cd D:\FALL26\PRM393\PRJ_PRM\minitube
flutter pub get
flutter run -d chrome --web-port=5000 --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

Use frontend port 5000 to match the configured CORS origin. Register an API account; mock accounts are separate. Login opens Home. A frontend restart currently requires logging in again, while server data persists.

See DOCUMENT_ALIGNMENT.md for implemented features and remaining work.

## Manual acceptance checklist

Use a short, playable H.264 MP4 from your device (not the synthetic test container).

1. Register/login, upload the MP4 and confirm the new video appears on Home and Manage videos.
2. Play/pause and seek. Confirm History appears only after playback starts.
3. Post a comment, reopen the video and confirm it persists. A second account must not delete that comment or edit/delete the video.
4. Replace the file and verify the video ID, comments and history are retained. Invalid files must leave the original playable.
5. Upload a larger file and cancel during transfer. Refresh Manage videos before retrying to check whether the server already committed it.
6. Delete individual history entries, then Clear all. Confirm the other account's history is unchanged.
7. Delete the owned video and confirm it is removed from lists, comments/history and streaming.

Android is not yet verified. Emulator access normally needs 10.0.2.2 plus suitable backend binding and debug cleartext configuration; the current local setup is for Chrome on this PC.

## Automated checks

```powershell
flutter analyze
flutter test
flutter test test/remote_api_test.dart --dart-define=RUN_API_TESTS=true
cd ..\Server
npm.cmd test
node scripts/integration-local.mjs
```

Live API tests create disposable test accounts. The Node integration script cleans its accounts; the Flutter adapter test leaves its account for inspection. These tests use synthetic MP4 headers for transport and do not establish playback compatibility.
