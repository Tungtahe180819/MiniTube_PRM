# Part 4 — Video details and comments

Implemented video ID routing, metadata/details, HTTPS MP4 player using video_player, play/pause, scrubbing, position/duration, 15-second initialization timeout, retry and player disposal. Playback pauses when app leaves foreground.

Comments: guest read access, login prompt, member posting (trimmed 1–500 characters), newest first, author-only deletion with confirmation. Comments are in memory and reset when app restarts. Login from video follows the requested behavior and returns Home.

Demo videos currently share the official Flutter bee.mp4 sample; titles/artwork are illustrative. Real playback requires network access. Test Android or Chrome; video_player does not include Windows desktop playback support. Channel details and history recording belong to later stages.

Run flutter pub get then flutter run -d chrome, or select an Android emulator/device. Open any Home/Search card. Login first to post comments.

Verification: flutter analyze clean; 5 tests pass including video lookup, comment validation and ownership. Live device playback has not been manually verified.
