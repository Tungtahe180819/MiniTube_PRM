# Replacement upload and progress

API mode now supports replacing an owned video file with PUT /api/v1/videos/:id/file (multipart video + metadata). The record ID, comments and history references remain unchanged. Metadata-only edits continue to use PUT /api/v1/videos/:id.

The backend validates the replacement, locks the current record, commits the new media reference, then removes the old file. Invalid input or failed pre-commit work leaves the old active file intact. Failed physical cleanup is logged for retry; a durable cleanup worker is not implemented.

Flutter uses Dio for multipart progress and CancelToken cancellation. UI shows sent percentage, then a separate server-saving state; success is shown only after the API response. Cancel stops the client request. Cancellation near server commit can have an uncertain outcome, so the error instructs refreshing Manage Videos before retrying. The form and selected file remain available.

Verification: backend integration tested successful replacement, wrong-owner rejection, invalid replacement preserving original bytes and stable ID. Flutter live adapter test covers upload, metadata edit, replacement, send progress and cancellation before send. 11 mock regressions passed; analyze clean. Mid-transfer browser cancellation and real codec playback still need manual UI verification.

Local environment note: C: became full and blocked MySQL commit. Only a known failed Flutter-test temporary directory and generated workspace test build output were removed. Current tests use build/test_temp on D:. Keep adequate free space on the MySQL data drive.

Try: hot restart Flutter, Edit an owned video, Replace video file, choose another MP4, Save changes. Try Cancel upload during a larger upload and refresh Manage Videos before retrying.
