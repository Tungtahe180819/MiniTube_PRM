# PRJ_PRM - MiniTube

- minitube/: Flutter frontend.
- Server/: Node.js/Express + MySQL backend.

Open PRJ_PRM.code-workspace in VS Code to work with both components.

## Backend

```powershell
cd D:\FALL26\PRM393\PRJ_PRM\Server
npm.cmd start
```

## Frontend

```powershell
cd D:\FALL26\PRM393\PRJ_PRM\minitube
flutter run -d chrome --web-port=5000 --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

Existing MySQL data and the API address remain unchanged. See minitube/README.md and Server/README.md for details. Never commit Server/.env, Server/node_modules or Server/storage.
