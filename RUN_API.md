# Run Flutter with the real API

## Backend

```powershell
cd D:\FALL26\PRM393\minitube\server
npm.cmd start
```

MySQL must be running and server/.env configured. Local database initialization and backend transport tests were completed. Do not commit .env or storage.

## Chrome

Use a fixed frontend port matching server CORS_ORIGIN:

```powershell
cd D:\FALL26\PRM393\minitube
flutter pub get
flutter run -d chrome --web-port=5000 --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

Register a new account in API mode. Mock demo accounts do not exist in MySQL. Registration/login returns Home. Open Profile > Manage videos > Add; choose MP4, enter metadata and submit. The server receives and stores the file; its stream is used for playback. Refreshing/restarting the frontend requires logging in again, but server videos/accounts persist.

API mode connected in this stage: registration, login/logout, Home/Search/category feed, owned video list, new-file upload, metadata editing, deletion, playback from internal stream, and profile display-name update. Profile avatar is not persisted by the current backend. Do not use it as a saved avatar feature in API mode.

Still pending: percentage upload progress and cancellation, replacement of an existing server video file, profile avatar persistence, channel editing, comments/history endpoints and their frontend adapters. History/comments/channel editing show explicit not-connected notices in API mode, rather than silently using mock state.

Without USE_MOCK=false, the application intentionally retains its previous local mock behavior for regression tests and offline UI work. Thumbnail URLs are not part of the upload payload. New server uploads are limited to MP4 up to the backend's configured size limit (100 MB by default).

## Verification

- flutter analyze: clean.
- Existing mock regression tests: 8 passed.
- flutter test test/remote_api_test.dart --dart-define=RUN_API_TESTS=true: passed against local MySQL/API. Creates a disposable integration account; uploads then removes its synthetic test video and logs out. The test account remains for inspection.
- API web build compiled successfully; final source build repeated after adapter fixes.

The adapter test uses a synthetic MP4 container to verify transport; it does not prove codec playback. Real file selection and playback still need manual Chrome/Android testing. Android emulator uses 10.0.2.2 in API_BASE_URL, but cleartext/debug and local host binding must be configured before Android connection; current verified API setup is Chrome on the same PC.
