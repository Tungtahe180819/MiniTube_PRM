# MiniTube backend

Node.js/Express + MySQL API. Server and Flutter frontend minitube are sibling folders.

## Database setup after cloning

Requires Node.js 20+ and MySQL 8. Start MySQL, then run db/create-database.sql in MySQL Workbench with an account allowed to create databases. It creates minitube with utf8mb4 and does not remove existing data.

Use an existing local MySQL account with access to minitube, or create a dedicated account as an administrator (replace the placeholder locally):

```sql
CREATE USER 'minitube'@'localhost' IDENTIFIED BY 'YOUR_LOCAL_PASSWORD';
GRANT ALL PRIVILEGES ON minitube.* TO 'minitube'@'localhost';
```

Do not recreate a user that already exists. Every teammate uses their own MySQL credentials.

From Server/:

```powershell
npm.cmd ci
if (!(Test-Path .env)) { Copy-Item .env.example .env }
```

Edit .env locally: DB_HOST, DB_PORT, DB_NAME, DB_USER and DB_PASSWORD must match YOUR MySQL installation. The example uses DB_USER=minitube. Keep PORT=3000 and CORS_ORIGIN=http://localhost:5000 for the documented Chrome setup. Never overwrite an existing .env just to install the demo.

```powershell
npm.cmd run db:setup
npm.cmd start
```

GET http://localhost:3000/health returns 200 when MySQL is accessible, or 503 otherwise. A listening message alone does not prove database access. If Flutter loaded before the API was ready, press Retry on Home.

## Tables and fields

| Table | Fields |
| --- | --- |
| users | id, email, display_name, password_hash, created_at |
| channels | id, owner_id, name, description, avatar_url |
| categories | id, name |
| videos | id, channel_id, category_id, title, description, file_name, original_name, thumbnail_url, size_bytes, created_at, updated_at |
| auth_sessions | id, user_id, token_hash, expires_at |
| comments | id, user_id, video_id, content, created_at |
| watch_history | user_id + video_id primary key, last_watched_at |

Schema: db/schema.sql. Commands:

```powershell
npm.cmd run db:init    # Create missing tables/categories and thumbnail column
npm.cmd run db:seed    # Add shared demo records and internal media copies
npm.cmd run db:setup   # Run init and seed in order
npm.cmd run db:verify  # Seed twice; check counts and sample media bytes
```

Demo accounts: demo@minitube.test / Demo1234 and studio@minitube.test / Studio1234. Passwords use the same salted scrypt format as registration. No personal records or active sessions are exported.

Sample content: 2 accounts/channels, 3 videos, 3 comments and 2 initial history examples. All videos copy the same generated 4-second test pattern with an audio tone from db/fixtures/demo.mp4 to ignored storage/videos. No FFmpeg or external download is needed. Initial history is seeded example data, not measured playback.

The seed is additive and repeatable without duplicates on an unchanged database. It preserves edited records/passwords; conflicting reserved demo emails or media cause an error. Database writes are transactional; newly copied files are cleaned up on failure. Missing sample content may be recreated after deletion/replacement. There is no reset/drop command.

db:init does not create the database or MySQL user. It is not a general migration for incompatible old schemas; use a separate new development database in that case, grant your user access and set DB_NAME accordingly.

## API

Protected endpoints use Authorization: Bearer <token>. Identity is derived from the session, not a user ID submitted by FE.

| Method | Path under /api/v1 | Purpose |
| --- | --- | --- |
| POST | /auth/register, /auth/login, /auth/logout | Account/session creation, login, logout |
| GET / PUT | /me | Read account / update display name |
| GET | /categories, /videos | Public categories and filtered/paged videos |
| GET | /videos/:id, /videos/:id/stream | Metadata and MP4 range streaming |
| GET | /me/videos | Owned videos |
| POST | /videos | Authenticated multipart upload |
| PUT | /videos/:id | Owner metadata edit |
| PUT | /videos/:id/file | Owner file replacement |
| DELETE | /videos/:id | Owner deletion |
| GET / POST | /videos/:id/comments | Public read / authenticated comment |
| DELETE | /comments/:id | Author-only deletion |
| GET / DELETE | /me/history | List 20/page / clear history |
| PUT / DELETE | /me/history/:id | Record watch / remove history entry |
| GET / PUT | /me/channel | Read / edit own channel |
| GET | /channels/:id, /channels/:id/videos | Public channel and videos |

Device-file MP4 upload only, up to 100 MB by default. Metadata stays in MySQL; media stays in storage/videos. Video URLs cannot be submitted. Optional image URLs must be HTTPS. Basic MP4 signature validation does not guarantee codec compatibility; the bundled fixture is H.264/yuv420p with AAC.

Video deletion cascades to comments/history. Failed physical cleanup is logged; a durable retry task is not implemented. Cancellation near commit may have an uncertain result; refresh Manage Videos before retrying.

The API binds 127.0.0.1. Chrome uses localhost:3000. Android Emulator uses 10.0.2.2:3000 with suitable Android debug networking configuration; physical-device/LAN access requires additional setup.

## Verification

```powershell
npm.cmd test
npm.cmd run db:verify
node scripts/integration-local.mjs
```

The integration script additionally requires a running API. It tests transport/authorization using synthetic MP4 headers. The seed check verifies repeatability and fixture bytes; real UI/browser/Android playback still needs manual checking.

Do not commit .env, node_modules, storage, logs or personal SQL dumps. Only schema, public demo scripts/data and the generated fixture belong in Git.
