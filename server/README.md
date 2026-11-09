# MiniTube backend

Node.js/Express + MySQL API for device-file upload and internal media streaming. This stage is not yet connected to the Flutter UI; Flutter still uses its mock/local-file repository.

## 1. Create a database

Open MySQL Workbench and connect using your existing local administrator account. Run the following after replacing `YOUR_STRONG_PASSWORD` with a password that you choose locally:

```sql
CREATE DATABASE minitube CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'minitube'@'localhost' IDENTIFIED BY 'YOUR_STRONG_PASSWORD';
GRANT ALL PRIVILEGES ON minitube.* TO 'minitube'@'localhost';
```

Do not use these CREATE statements against an existing account without checking its current configuration. No existing database is dropped by the initialization script. `schema.sql` creates missing tables; it is not a migration for incompatible pre-existing tables.

## 2. Configure locally

From the server directory:

```powershell
Copy-Item .env.example .env
```

Edit `.env` locally. Set DB_PASSWORD to the chosen password and verify DB_HOST/DB_PORT. Never commit `.env`. No password needs to be sent through chat.

## 3. Install and start

Requires Node.js 20 or newer and MySQL 8.

```powershell
npm.cmd install
npm.cmd run db:init
npm.cmd start
```

Check `http://127.0.0.1:3000/health`. HTTP 200 means database access works; HTTP 503 means the database is unavailable/unconfigured. The server binds localhost only for this stage. Android physical-device/LAN configuration will be handled when connecting Flutter.

## API

| Method | Path | Access / purpose |
| --- | --- | --- |
| POST | /api/v1/auth/register | displayName, email, password; create user, channel and 24h session |
| POST | /api/v1/auth/login | email/password; return user and bearer token |
| POST | /api/v1/auth/logout | Bearer token; revoke current session |
| GET | /api/v1/me | Bearer token; current account |
| GET | /api/v1/categories | Public categories |
| GET | /api/v1/videos | Public list; q, categoryId, page; 20 items/page |
| GET | /api/v1/videos/:id | Public details with internal relative stream path |
| GET | /api/v1/videos/:id/stream | Public MP4; HTTP range requests for seeking |
| POST | /api/v1/videos | Bearer token; multipart file field video, title, description, categoryId |
| PUT | /api/v1/videos/:id | Owner; JSON metadata only: title, description, categoryId |
| DELETE | /api/v1/videos/:id | Owner; delete record/dependents and remove media |

Example upload in PowerShell (use an actual token from registration/login):

```powershell
curl.exe -X POST http://127.0.0.1:3000/api/v1/videos -H "Authorization: Bearer YOUR_TOKEN" -F "video=@C:\Videos\sample.mp4" -F "title=My video" -F "description=Local upload" -F "categoryId=1"
```

No video URL field is accepted. The default limit is 100 MB. Extension and basic MP4 container signature are checked; this is not transcoding, malware scanning or complete codec validation. Use a browser/Android compatible MP4 codec. Internal file names are generated UUIDs, not user-supplied paths.

Files are kept in storage/videos, temporary uploads in storage/tmp. The directories are ignored by Git. MySQL stores metadata/file references only. Registration and video creation use transactions; failed upload writes remove the temporary/replacement file. Dependent comments/history use foreign-key cascades. File cleanup failure is logged; a durable retry/garbage-collection job is still pending. Avoid process termination during uploads; interrupted temporary files may need cleanup.

## Verification and remaining work

```powershell
npm.cmd test
node --check src/app.js
```

The media validation test checks text disguised as MP4, empty files and a valid container header. Server startup and unconfigured database health response were checked. MySQL registration/upload/streaming integration has not been run because the database/user/password still need local setup.

Still to implement in the next stage: wire Flutter to these endpoints, upload progress/cancel, file replacement endpoint, profile/channel updates, comments/history API routes, and integration tests using a configured database. The schema includes comments/history tables, but their CRUD endpoints are not implemented in this stage.
