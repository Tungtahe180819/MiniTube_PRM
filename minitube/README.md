# MiniTube frontend

Flutter application for PRM393. English UI, with optional offline mock mode and a real Node.js/MySQL API.

## Separate frontend and backend

```text
D:\FALL26\PRM393\
|-- minitube/     Flutter frontend
|-- Server/       Node.js/Express backend
```

Open MiniTube.code-workspace to work with both folders in VS Code. The frontend communicates with the backend through HTTP; it does not import backend files. Backend .env, node_modules and uploaded media stay in Server.

## Run with the real API

Terminal 1:

```powershell
cd D:\FALL26\PRM393\PRJ_PRM\Server
npm.cmd start
```

Terminal 2:

```powershell
cd D:\FALL26\PRM393\PRJ_PRM\minitube
flutter pub get
flutter run -d chrome --web-port=5000 --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

For a fresh backend installation, follow ../Server/README.md to configure MySQL and install dependencies. Do not overwrite an existing .env. Moving the folders does not require database reinitialization. The API address remains unchanged.

## Offline demo

Run flutter run -d chrome without USE_MOCK=false. Mock demo accounts: demo@minitube.app / Demo1234 and studio@minitube.app / Studio1234. Mock accounts and media are session-only and separate from MySQL accounts.

## Features

- Login, registration, profile display-name editing and logout; login opens Home.
- Home/category feed, title search and pagination.
- Device-file-only MP4 upload up to 100 MB, progress/cancel and internal streaming.
- Owned-video metadata editing, file replacement and deletion.
- Comments, per-account watch history, channel editing and public channel viewing.
- Optional image thumbnail URLs with a display fallback; external video URLs are rejected.

See DOCUMENT_ALIGNMENT.md for remaining work and RUN_API.md for verification. Browser codec playback and Android still require manual verification. Profile avatar persistence and visible channel avatars remain pending.

## Frontend structure

- lib/app: application, routes and theme.
- lib/core: shared models, network, validation and media helpers.
- lib/features: authentication, Home/Search, videos, channels, profile and history.
- test: repository, widget and live API adapter checks.

## Checks

```powershell
flutter analyze
flutter test
flutter test test/remote_api_test.dart --dart-define=RUN_API_TESTS=true
```

The live adapter check requires the backend and MySQL. Transport checks use synthetic MP4 headers and do not establish playback compatibility.
