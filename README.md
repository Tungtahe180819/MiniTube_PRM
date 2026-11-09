# MiniTube

Flutter frontend for PRM393, with English UI and in-memory mock repositories.

## Run

Requires Flutter with Dart compatible with `^3.13.2`, and Chrome or an Android device/emulator.

    flutter pub get
    flutter run -d chrome

For Android, run `flutter devices`, then `flutter run -d <device-id>`.

## Demo accounts

| Email | Password |
| --- | --- |
| demo@minitube.app | Demo1234 |
| studio@minitube.app | Studio1234 |

Login/registration success opens Home. The authenticated account button opens My Profile.

## Features

- Home/category filtering, title search, pagination and refresh.
- Login, registration, profile editing and logout.
- Video details and playback; author-only comment deletion.
- Personal video management and channel editing/public channel viewing.
- Per-account watch history, recorded after playback starts; remove one or clear all.

## File-only video input

UC07 accepts a video selected from the device, never a user-entered video URL.

1. Login and open Profile > Manage videos > Add.
2. Select Choose video from device. Pick a non-empty MP4 file up to 100 MB.
3. Enter title, description and category, then select Add video from file.
4. Open the created video to play the selected file.
5. Edit can replace the file or keep the current one. An illustrative seed video without a file must be assigned a local video before it can play.

The mock repository rejects HTTP/HTTPS/data video sources. Seed cards are illustrative and contain no externally hosted video clips. Avatar/thumbnail URL fields concern images only.

**Current limitation:** choosing a file is local import/preview, not server upload. Metadata, accounts and file references remain session-only. Android uses the selected local file; web uses a browser-local file reference. Restarting the app or revoking file access may require selecting the file again. Windows playback is not supported by this video_player setup.

## Target backend

The agreed next integration is multipart upload to MiniTube, internal file storage/streaming and MySQL metadata persistence. It is not implemented or connected in this revision. No remote-upload progress or server persistence is simulated. API constants alone do not activate a remote repository.

## Structure

- `lib/app`: app composition, theme and routes.
- `lib/core/domain`: shared data models and repository contracts.
- `lib/core/media`: conditional local playback for web/native.
- `lib/features/auth`: mock account adapter and shared authentication state.
- `lib/features/home`: Home/Search feed implementation.
- `lib/features/video`: mock data, details, cards and shared Add/Edit form.
- `lib/features/channel`, `profile`, `history`: their respective screens.
- `test`: repository and widget regression tests.

Some original scaffold files remain TODO; their functionality may be implemented in shared screens. The current implementation uses StatefulWidget, ChangeNotifier and ValueNotifier, not the full BLoC architecture proposed in the report.

## Checks

    flutter analyze
    flutter test
    flutter build web

Manual device file selection/playback still needs verification. If a local video cannot open, check its format/codec and choose it again. For Android SDK problems, use `flutter doctor -v` and configure machine-specific `android/local.properties`.

## Documentation

`PART_1.md` through `PART_5.md` are historical stage notes. This README and `DOCUMENT_ALIGNMENT.md` supersede their previous URL-media and missing-history descriptions.
