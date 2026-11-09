# Local backend verification

Database `minitube` and a dedicated `minitube_app` account are configured on local MySQL. The application uses its own generated password in ignored server/.env; root credentials are not stored in source.

Schema initialized successfully. Integration checks passed: health, transactional account/channel/session creation, login, rejecting video URL submission, multipart MP4 upload, byte-range streaming, ownership denial and deletion. Temporary test accounts and video were removed. The MP4 used in transport tests has a synthetic container header, so this check does not prove video codec playback on a real device.

Run with backend already running:

    node scripts/integration-local.mjs

This script creates disposable test records and removes only those records in its cleanup. Normal unit test command remains npm.cmd test. Start the backend with npm.cmd start if it is no longer running.

Next: connect Flutter auth/feed/upload/player to HTTP repositories. Current Flutter mock/local-file mode is unchanged by database setup. Never commit .env or storage; no credentials are included in this note.
