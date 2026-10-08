# Picklog

A Flutter application for managing your personal games collection, discovering new games, and tracking your gaming journey.

## Overview

Picklog is a cross-platform mobile application built with Flutter that allows users to:

- Discover upcoming and anticipated games via IGDB integration
- Track games in a personal library with status, scores, and playtime
- Mark games as favorites
- Search and browse detailed game information
- Manage personal preferences and settings

## Features

### 🎮 Game Discovery

- Browse most anticipated upcoming games
- Search games with real-time results
- View detailed game information including:
  - Cover art and screenshots
  - Trailers and videos
  - Genres, platforms, and release dates
  - Involved companies (developers/publishers)
  - Similar games recommendations

### 📚 Game Library

- Add games to your personal library
- Track game status: Planned, Playing, Finished, Dropped, On Hold
- Record scores (0-100), playtime, and difficulty
- Mark games as favorites
- Filter library by status or favorites
- Platform-specific tracking

### 🔐 User Authentication

- Secure user registration and login
- JWT-based authentication
- Persistent session management

### ⚙️ Settings & Preferences

- Toggle between light and dark themes
- Multi-language support (English/Portuguese)
- User-friendly settings interface

## Architecture

### State Management

- **Flutter BLoC**: Predictable state management with events and states
- **Cubit**: Simplified BLoC for simpler state scenarios
- **Equatable**: Value equality for state comparisons

### Dependency Injection

- **GetIt**: Service locator pattern for dependency management
- **Interface Segregation**: Abstract interfaces for testability

### Navigation

- **GoRouter**: Declarative routing with authentication guards
- **StatefulShellRoute**: Bottom navigation with state preservation
- **Route Protection**: Automatic redirection based on auth state

### Data Layer

- **Dio**: HTTP client for API communication
- **Repository Pattern**: Clean separation of data sources
- **SharedPreferences**: Local storage for preferences

### Internationalization

- **Flutter Localizations**: Built-in i18n support
- **ARB Files**: Localized strings for English and Portuguese

## Project Structure

```
lib/
├── main.dart                    # Application entry point
├── core/                        # Shared/core functionality
│   ├── data/                    # HTTP client, API configuration
│   ├── domain/                  # Shared models and interfaces
│   └── utils/                   # Extensions, router, environment
├── features/                    # Feature modules
│   ├── auth/                    # Authentication
│   │   ├── data/               # Auth repository implementation
│   │   ├── domain/             # User model, auth interfaces
│   │   └── presentation/       # BLoC, screens, widgets
│   ├── games/                   # Game discovery & details
│   │   ├── data/               # Games repository, IGDB integration
│   │   ├── domain/             # Game models
│   │   └── presentation/       # Search, details screens
│   ├── home/                    # Home dashboard
│   ├── library/                 # User's game library
│   │   ├── data/               # Library repository
│   │   ├── domain/             # Library entry models
│   │   └── presentation/       # Library BLoC, widgets
│   ├── profile/                 # User profile
│   ├── settings/                # App settings
│   └── splash/                  # Initial loading
└── l10n/                        # Localization files
    ├── app_en.arb              # English strings
    └── app_pt.arb              # Portuguese strings

test/                            # Test suite
├── core/                        # Core tests
├── features/                    # Feature tests
│   ├── auth/                   # Auth BLoC and repository tests
│   ├── library/                # Library BLoC and repository tests
│   └── ...
└── mocks/                       # Test utilities and mocks
```

## Technologies Used

### Core Framework

- **Flutter 3.8+**: Multi-platform UI toolkit
- **Dart 3.8+**: Programming language

### State Management

- **flutter_bloc**: BLoC pattern implementation
- **bloc**: Core BLoC library
- **equatable**: Value equality

### Networking

- **Dio**: HTTP client with interceptors

### Navigation

- **GoRouter**: Declarative routing

### Storage

- **SharedPreferences**: Local data persistence

### UI Components

- **cached_network_image**: Efficient image loading with caching
- **carousel_slider**: Image carousels
- **flutter_rating_bar**: Rating display
- **youtube_player_iframe**: Video playback

### Utilities

- **share_plus**: Native sharing functionality
- **url_launcher**: External URL handling
- **validatorless**: Form validation

### Development Tools

- **flutter_lints**: Dart linting rules
- **bloc_test**: BLoC testing utilities
- **mocktail**: Mocking framework

## Getting Started

### Prerequisites

- **FVM (Flutter Version Manager)** - Required for managing Flutter SDK versions
- Flutter SDK 3.8+ (managed via FVM)
- Dart SDK 3.8+ (comes with Flutter)
- Android Studio / VS Code with Flutter extensions
- Android SDK for Android development
- Xcode for iOS development (macOS only)

### FVM Setup (Required)

This project uses FVM to ensure consistent Flutter versions across all developers.

```bash
# Verify FVM installation
fvm --version
fvm doctor
```

### Installation

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd MyGamesList/app
   ```

2. **Set up Flutter SDK version**

   ```bash
   # Install and use the project's Flutter version
   fvm install
   fvm use
   ```

3. **Install dependencies**

   ```bash
   fvm flutter pub get
   ```

4. **Generate localization files**

   ```bash
   fvm flutter gen-l10n
   ```

5. **Run the application**
   ```bash
   fvm flutter run
   ```

### Environment Configuration

Create a `.env` file in the app root:

```
API_BASE_URL=http://localhost:8080/api/v1
WEB_BASE_URL=https://picklog.app
```

## Development

### Running Tests

```bash
# Run all tests
fvm flutter test

# Run specific test file
fvm flutter test test/features/library/bloc/library_bloc_test.dart

# Run with coverage
fvm flutter test --coverage

# Generate coverage report (requires lcov)
genhtml coverage/lcov.info -o coverage/html
```

### Code Generation

```bash
# Generate localization files
fvm flutter gen-l10n

# Or use Makefile
make l10n
```

### Code Analysis

```bash
fvm flutter analyze
```

### Project Conventions

- **Commits**: Conventional Commits (`feat:`, `fix:`, `docs:`, `test:`, etc.)
- **Naming**: PascalCase for classes, snake_case for files, camelCase for variables
- **Testing**: Mandatory for all BLoC events and repository methods
- **Localization**: Always use `context.l10n.stringKey` for user-facing text

## Building for Production

### Android

```bash
fvm flutter build apk --release
# or
fvm flutter build appbundle --release
```

### iOS

```bash
fvm flutter build ios --release
```

### Web

```bash
fvm flutter build web --release
```

## API Integration

This app connects to a Go backend API that integrates with IGDB (Internet Game Database) for game information.

### Key Endpoints

- `/auth/*` - Authentication (signup, signin, logout)
- `/games/*` - Game discovery and search
- `/library/*` - User's game library management
- `/users/:id/library` - Public library viewing

For API documentation, see the [API README](../api/README.md).

## Contributing

### Code Style

- Follow Dart/Flutter conventions
- Use `fvm flutter analyze` to check code quality
- Maintain test coverage for new features
- Always use localized strings for UI text

### Development Workflow

1. Create feature branch from `main`
2. Implement changes with tests
3. Run `fvm flutter analyze` and `fvm flutter test`
4. Submit pull request

### Adding New Features

1. Create feature directory under `lib/features/<feature_name>/`
2. Add `CLAUDE.md` documentation file
3. Implement Clean Architecture layers (data, domain, presentation)
4. Write comprehensive tests
5. Update localization files if needed

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

Built with ❤️ using Flutter and BLoC
