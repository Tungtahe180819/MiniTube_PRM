# MiniTube

MiniTube is a Flutter video browsing and management application developed for PRM393. The current frontend uses English UI text and in-memory mock repositories, so it can be demonstrated without a backend or database.

## Current features

- **Accounts:** login, registration, input validation, profile name/avatar URL editing, and logout confirmation. Successful login or registration returns to Home. The account button opens My Profile when authenticated.
- **Discovery:** 45 sample videos across Learning, Nature, and Creative; newest-first Home feed; category filtering; title search; 20-item pagination; pull to refresh; loading, empty, and retry states.
- **Playback:** video details, HTTPS MP4 playback, play/pause, seeking, elapsed/total time, initialization timeout, retry, and controller cleanup. Playback pauses when the app goes into the background.
- **Comments:** public reading, member posting, validation, and author-only deletion with confirmation.
- **Video management:** list owned videos; add/edit metadata and media URLs; delete owned videos with confirmation; warn before discarding changes in the video editor.
- **Channels:** edit personal channel information and view a public channel from video details. Changes refresh related feeds.

## Implementation status and limits

This is a frontend prototype. **A running backend and MySQL database are not required.** Node.js/Express and MySQL are part of the report design and have not been connected to this application.

- Accounts, comments, video changes, and channel changes are stored in memory and reset after restarting the app.
- History is still a placeholder. Playback does not yet write watch history.
- Sample videos currently share the Flutter `bee.mp4` demonstration clip; their titles and category artwork are illustrative.
- Adding a video stores metadata and a direct HTTPS media URL. File upload, transcoding, livestreaming, and downloads are not implemented.
- Thumbnail and avatar URLs are stored; cards/profile currently use category artwork or initial placeholders.
- Remote data sources and several files from the original scaffold remain unfinished. Folder/file presence does not imply a completed feature.

## Requirements

- Flutter SDK with Dart **3.13.2 or a compatible 3.x version**, matching `pubspec.yaml`.
- Chrome for web development, or Android Studio/Android SDK with an emulator or connected Android device.
- Internet access to download dependencies and play the sample MP4.

Android and Chrome are the intended demo targets. The included Windows platform scaffold does not provide video playback support through the current `video_player` setup. iOS/macOS builds require a macOS development environment and have not been verified.

## Run locally

Open a terminal in the project directory:

```powershell
cd D:\FALL26\PRM393\minitube
flutter pub get
flutter devices
```

Run in Chrome:

```powershell
flutter run -d chrome
```

For Android, start an emulator or connect a device, then select its ID from `flutter devices`:

```powershell
flutter run -d <device-id>
```

Use hot restart after changes to app initialization or dependencies. Run `flutter pub get` again after editing `pubspec.yaml`.

## Demo accounts

| Email | Password | Seeded channel |
| --- | --- | --- |
| `demo@minitube.app` | `Demo1234` | Demo Creator |
| `studio@minitube.app` | `Studio1234` | Everyday Studio |

These credentials are for mock demonstrations only. Newly registered users start without owned videos. A channel is initialized when accessed or when creating the first video. The future backend design creates the channel atomically at registration.

## Suggested demo flow

1. Open Home, choose a category, or use Search to find `Flutter`.
2. Open a video, play/pause it, and select the channel to view its videos.
3. Open Profile and log in with a demo account; the app returns to Home.
4. Use the account button or Profile tab to open My Profile.
5. Open Manage videos to add or edit a video. For a playable sample URL, use:

   ```text
   https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4
   ```

6. Open a video while signed in, post a comment, then delete your own comment.
7. Open My channel, update the channel name, and save.
8. Log out, then use the second account to check that owned video lists remain separate.

## Project structure

```text
lib/
  main.dart                       Application entry point
  app/
    app.dart                      App composition and mock authentication
    router/app_router.dart        Routes, navigation shell, shared video repository
    theme/                        Material theme and colors
  core/
    constants/                    API configuration declarations
    domain/                       Shared models and combined repository contract
    errors/                       Shared exception type
    validation/                   Form validators
    widgets/                      Loading and error widgets
  features/
    auth/                         Auth repository, mock adapter, controller, forms
    home/                         Home and Search feed implementation
    video/                        Mock video repository, cards, details, editor, management
    channel/                      Personal and public channel screens
    profile/                      Profile editing and logout
    comment/                      Original scaffold; current comment UI is in video details
    search/                       Original scaffold; Search currently reuses HomePage
    history/                      Planned watch history feature

test/                             Repository and widget regression tests
PART_1.md ... PART_5.md            Implementation notes by stage
```

## State and data flow

The implementation currently uses Flutter `StatefulWidget`/`setState` for screen state. `AuthController` extends `ChangeNotifier`; `AuthScope` shares the current user. `MockVideoRepository` is shared through `AppRouter`, and its revision notifier refreshes Home/Search after content changes.

The report's proposed BLoC/Cubit, use-case layers, API adapter, and MySQL integration are not fully implemented. Current mock ownership checks demonstrate frontend behavior; a real backend must enforce authentication, authorization, validation, and password hashing independently.

`ApiConstants` declares `API_BASE_URL` and `USE_MOCK`, but the app currently constructs mock repositories directly. Changing these values alone **does not activate API mode**.

## Verify and build

```powershell
flutter analyze
flutter test
flutter build web
```

To create an Android APK once the local Android toolchain is configured:

```powershell
flutter build apk --debug
```

The last completed feature checks passed static analysis and six automated tests. Tests cover account/session behavior, login-to-Home navigation, discovery/filtering/pagination, comment ownership, video CRUD ownership, channel propagation, and dependent comment deletion. A web build passed after the playback stage; Android builds and manual device playback still need verification for the current revision.

## Troubleshooting

| Issue | Check |
| --- | --- |
| Video cannot play | Use Chrome/Android, check connectivity and the HTTPS MP4 URL, then select Retry. An HTTPS URL alone does not guarantee compatible media. |
| Android device is missing | Start an emulator or enable USB debugging, then run `flutter devices` and `flutter doctor -v`. |
| Android SDK path is incorrect | Update the machine-specific `android/local.properties` using your Flutter/Android SDK paths. Do not copy another machine's paths unchanged. |
| Changes disappear | Mock data is session-only. Restarting the app resets the demo data. |
| API settings have no effect | Remote repositories are not connected yet; the app still uses mock adapters. |

## Next stage

Implement watch history, finish consistency/error handling across screens, connect remote repositories to the planned REST API/MySQL backend, and verify the complete app on Android.
