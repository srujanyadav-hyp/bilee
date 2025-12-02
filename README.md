# BILEE — SOCHI 1

A Flutter-based mobile application for real-time billing and payment management, enabling seamless interactions between merchants and customers through QR code technology. The app supports live bill tracking, receipt management, and secure payment flows with Firebase backend integration.

## Phase 0 Goals

Phase 0 establishes the foundational project structure and safe placeholder implementations:

- ✅ Project setup with Flutter stable channel (3.30.1)
- ✅ Core dependencies installed (Firebase, state management, QR, etc.)
- ✅ Folder structure scaffolded with feature-based architecture
- ✅ Placeholder screens for onboarding, auth, merchant, and customer flows
- ✅ Router and navigation setup with named routes
- ✅ Firebase placeholder configuration (no real credentials)
- ✅ Safe Firebase service stubs for Crashlytics and Analytics
- ✅ GitHub Actions CI workflow for automated testing
- ✅ Theme system with placeholder colors and typography

## Quick Start

### Prerequisites

- **Flutter**: Stable channel (tested with Flutter 3.30.1, Dart 3.10.1)
- **Development Tools**: Git, VS Code (or Android Studio)
- **Firebase CLI** (optional for real Firebase setup): `dart pub global activate flutterfire_cli`

### Firebase Configuration

This project uses placeholder Firebase configuration by default. To connect to a real Firebase project:

1. **Current State**: The app uses `lib/firebase_options_dev.dart` with placeholder values
2. **For Real Firebase**:
   ```bash
   flutterfire configure
   ```
   This generates `lib/firebase_options.dart` with your real Firebase project credentials
3. **Update Imports**: Replace imports of `firebase_options_dev.dart` with `firebase_options.dart`
4. **Note**: Real `firebase_options.dart` is in `.gitignore` and should never be committed

### Running the App

```bash
# Install dependencies
flutter pub get

# Run on connected device or emulator
flutter run

# Run tests
flutter test

# Analyze code
flutter analyze

# Build APK (debug)
flutter build apk --debug
```

## Project Structure

```
lib/
├── core/               # Core utilities, theme, constants, services
│   ├── constants/      # App-wide constants (colors, typography)
│   ├── theme/          # Theme configuration
│   ├── utils/          # Helper functions
│   └── services/       # Firebase and other service integrations
├── data/               # Data layer (models, repositories, sources)
├── features/           # Feature-based modules
│   ├── onboarding/     # Welcome slides
│   ├── auth/           # Authentication (login, register, role selection)
│   ├── merchant/       # Merchant flows (billing, QR, summaries)
│   ├── customer/       # Customer flows (scan, live bill, receipts)
│   └── settings/       # App settings
├── widgets/            # Shared/reusable widgets
└── main.dart           # App entry point
```

## Branching Policy

- **`main`**: Production-ready code (protected branch)
- **`phase0/setup`**: Phase 0 development branch
- **`dev`**: Development branch for ongoing features
- **Feature branches**: `feature/feature-name` → merge to `dev` → merge to `main`

## Continuous Integration

GitHub Actions workflow is configured at `.github/workflows/flutter_ci.yml`:

- Triggers on push to `phase0/setup` and PRs to `main`
- Runs: pub get, analyze, test, build APK
- No secrets or credentials required
- Uses `subosito/flutter-action@v2` for Flutter setup

## Assets

Project assets are located in `assets/`:

- **Icons**: `assets/icon/icon_app_primary.png`
- **Logos**: `assets/logos/` (logo_full_glow.png, logo_symbol_glow.png, logo_symbol_white.png)

**⚠️ Important**: Do not modify or replace existing asset files without updating `pubspec.yaml` accordingly.

## Development Notes

### Phase 0 - Safe Placeholders

- All Firebase services use safe stubs that won't crash if Firebase isn't configured
- Placeholder screens are minimal `StatelessWidget` implementations
- No real authentication or backend calls are made
- Firebase initialization is wrapped in try-catch to ensure app runs without credentials

### Next Steps (Phase 1+)

- Replace Firebase placeholders with real implementation
- Implement authentication logic (email/password, anonymous)
- Connect to Firestore for data persistence
- Implement real-time billing features
- Add QR code generation and scanning functionality
- Implement state management (BLoC/Provider)

## License

Copyright © 2025 Bilee Project. All rights reserved.

## Contributors

- Project initialized on December 2, 2025
- Phase 0 completed: Project scaffold, Firebase placeholders, CI setup
