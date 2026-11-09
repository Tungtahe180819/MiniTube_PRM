# Part 2 — Accounts

Implemented English login/register forms, password visibility, confirmation and validation, duplicate-email errors, profile editing (display name and optional HTTPS avatar URL), read-only email, logout confirmation and session clearing.

Demo account: demo@minitube.app / Demo1234

Run: flutter run
Open Profile, then Login. Register creates an account and logs in automatically. Mock accounts and sessions live in memory and reset on app restart. Avatar URL is saved; the current profile avatar uses an initial placeholder. Backend/API authentication is not connected in this stage.

Architecture: AuthRepository contract, MockAuthRepository adapter, AuthController and AuthScope shared state. No external package was added. Passwords in the mock adapter are demonstration data only; production authentication belongs on the backend.

Validation: flutter analyze; flutter test. Tests cover duplicate registration, email normalization, invalid form input, successful login, profile save and logout/session clearing.
