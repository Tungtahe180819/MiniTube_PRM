# MiniTube — Part 1

Implemented: English Material 3 theme, bottom navigation (Home/Search/History/Profile), named route previews, shared loading/error widgets, API environment constants, data models, repository contract and form validators.

Screens are explicitly marked as previews. Authentication, video feeds, playback and API/mock implementations belong to subsequent parts.

Run from this project directory:

    flutter pub get
    flutter run

Open Profile to preview the named routes. API settings are defined in lib/core/constants/api_constants.dart; no backend connection is made in Part 1.

Checks:

    flutter analyze
    flutter test
