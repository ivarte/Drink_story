# Copilot instructions for this repo

## Big picture

- This is a Flutter application with the main project under `/drink_story`.
- Root-level `docs/` and `web/` contain the built web version that is published via GitHub Pages.
- The app focuses on interactive "stories" with a web-first experience. Some flows work differently on web vs. mobile (see `kIsWeb` branches).

When making structural changes, first skim `README.md` and `docs/03_architecture.md`.

## Key files and flows

- Entry point: `drink_story/lib/main.dart`  
  - Sets up the app, routing and configuration from `--dart-define` values.
- Network layer: look for `api_client.dart`  
  - Uses a configured HTTP client (Dio) with a base URL from `API_BASE`.  
  - Reuse this client; do not create ad-hoc Dio instances.
- Persistence: `storage.dart`  
  - Centralised helpers for local storage. Use these instead of raw `SharedPreferences` or file I/O.
- Activation/onboarding: `activation_screen.dart` and related widgets.
- QR / web content: `qr_web_page.dart` handles loading and displaying web-based story content.

When adding new features, follow the patterns used in these files instead of inventing new structures.

## Environment and running

Do NOT hardcode environment values; use `--dart-define` consistently:

- `API_BASE` – backend base URL.
- `ROUTE_ID` – route / tenant identifier.
- `DEMO_PACKAGE_URL` – URL of the demo story package.
- `DEMO_PACKAGE_SHA256` – checksum for the demo package.

Typical commands (run from `/drink_story`):

- Dev web in Codespaces:  
  `flutter run -d web-server --web-port=8080`  
  Then use the forwarded port in the Ports panel.
- Chrome dev run:  
  `flutter run -d chrome --dart-define=API_BASE=...`
- Web build for GitHub Pages:  
  `flutter build web` (artifacts are placed under `docs/`).

Use `flutter test` for unit/widget tests; place new tests under `drink_story/test/` mirroring the lib structure.

## Project-specific conventions

- Prefer existing `kIsWeb` branches and platform checks instead of adding new ad-hoc conditions.
- For new screens / flows:
  - Follow the structure of existing screens (state, widgets, services) and reuse existing navigation patterns.
  - Use `api_client.dart` for HTTP and `storage.dart` for persistence so logging, headers and storage stay consistent.
- Keep business logic in services/controllers; keep widgets mostly declarative and focused on UI.

## How to collaborate with AI

- Before implementing a change, reference the relevant sections in `docs/03_architecture.md` and the existing screens you are extending.
- When asking the AI to make changes, always specify:
  - which user flow is affected,
  - which files to touch, and
  - expected behaviour in terms of stories / activation / web vs. mobile.
