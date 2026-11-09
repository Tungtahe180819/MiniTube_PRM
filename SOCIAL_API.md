# Server comments, history and channels

API mode now connects comments, watch history and channel edits to MySQL.

- Comments: public reading, authenticated posting, author-only confirmed deletion, errors preserve drafts.
- History: recorded only once actual playback starts; upsert prevents duplicate user/video entries; fetch 20/page; per-item deletion and confirmed Clear all; no underlying video deletion.
- Channels: fetch/edit own channel with name, description and optional HTTPS avatar URL; public channel loads current server information and videos.

Run the existing Chrome command in RUN_API.md, then hot restart. Try posting/deleting a comment, play a video then open History, and save My channel before reopening it. Avatar URL is stored; visible channel avatar rendering is not part of this stage.

Validation: MySQL/API integration tested using two disposable accounts: channel persistence, public channel retrieval, comment authorship denial, history upsert, cross-account history isolation, and Clear all. Existing upload/range/deletion tests also pass. Flutter regression: 11 passed; live HTTP adapter test passed. Manual playback/UI verification remains required.

Remaining: replacing a server video file, upload percentage/cancel, server profile avatar persistence. Current comments/channel-video endpoints return all records rather than paginating; History is paginated. Existing mock mode is preserved for offline frontend work.
