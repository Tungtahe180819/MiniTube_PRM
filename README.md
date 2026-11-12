# MiniTube - PRJ_PRM

- minitube/: Flutter frontend.
- Server/: Node.js/Express + MySQL backend.

## First run after cloning

Requires Git, Flutter (Dart compatible with ^3.13.2), Node.js 20+ and MySQL 8.

```powershell
git clone https://github.com/Tungtahe180819/MiniTube_PRM.git PRJ_PRM
cd PRJ_PRM
cd Server
npm.cmd ci
if (!(Test-Path .env)) { Copy-Item .env.example .env }
```

1. Start your local MySQL service.
2. In MySQL Workbench, run Server/db/create-database.sql using an account allowed to create databases. This creates minitube without removing existing data.
3. Edit Server/.env with YOUR local database host, port, database name, username and password. The MySQL user must have access to this database. See Server/README.md for optional dedicated-user setup.
4. From the Server terminal:

```powershell
npm.cmd run db:setup
npm.cmd start
```

Health check: http://localhost:3000/health

In another terminal, from the cloned PRJ_PRM folder:

```powershell
cd minitube
flutter pub get
flutter run -d chrome --web-port=5000 --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

## Shared demo data

| API account | Password | Channel |
| --- | --- | --- |
| demo@minitube.test | Demo1234 | MiniTube Learning |
| studio@minitube.test | Studio1234 | MiniTube Studio |

The seed creates 2 accounts/channels, 3 videos across Learning/Creative/Nature, 3 comments and 2 example history entries. All videos use copies of the same generated 4-second H.264/AAC test pattern with a tone. No personal media, external video service or FFmpeg installation is required on teammates' machines.

These are public development credentials, not MySQL credentials. API demo accounts differ from offline mock accounts ending in @minitube.app. Try playback/fullscreen, comments, History, My Channel and Manage Videos. Use the second account to check ownership restrictions.

Run db:setup once to create missing tables and seed data. Run db:seed to restore missing examples. Repeating an unchanged seed does not create duplicates or reset existing data. Conflicting demo emails/passwords or media cause an error instead of being overwritten. Deleted/replaced demo content may be recreated when seeding again. Initial history entries are examples, not recorded playback events.

## Checks

From Server/ with MySQL configured:

```powershell
npm.cmd test
npm.cmd run db:verify
```

db:verify seeds the configured database twice, checks counts and media bytes. Use a development database; it adds the shared demo records.

From minitube/:

```powershell
flutter analyze
flutter test
```

See Server/README.md for database/API details and minitube/RUN_API.md for manual checks. Never commit .env, node_modules, private storage uploads or Flutter build output. The tracked clip in Server/db/fixtures is intentional demo content.

## Account features (Huy)
See [ACCOUNT_FEATURES.md](ACCOUNT_FEATURES.md) for extended profiles, change password, development phone OTP and Firebase Google setup. After updating, reinstall dependencies and run the account migration before starting the server. Google/SMS credentials are not bundled.
