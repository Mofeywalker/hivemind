<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/logo/hivemind_logo_dark.svg">
    <source media="(prefers-color-scheme: light)" srcset="assets/logo/hivemind_logo_light.svg">
    <img alt="Hivemind Logo" src="assets/logo/hivemind_logo_light.svg" width="380">
  </picture>
</p>

<p align="center">
  <strong>Collaborative, real-time shared spaces and smart reminder synchronization.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x%20(Stable)-02569B?logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/State_Management-Riverpod-34495E" alt="Riverpod">
  <img src="https://img.shields.io/badge/Backend-Firebase-FFCA28?logo=firebase&logoColor=black" alt="Firebase">
  <img src="https://img.shields.io/badge/Platforms-Android%20%7C%20iOS-brightgreen" alt="Platforms">
  <img src="https://img.shields.io/badge/CI%2FCD-GitHub_Actions-2088FF?logo=githubactions&logoColor=white" alt="GitHub Actions">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-PolyForm_Noncommercial_1.0.0-orange.svg" alt="License: PolyForm Noncommercial 1.0.0"></a>
</p>

---

## 📌 Table of Contents

- [About Hivemind](#-about-hivemind)
- [Key Features](#-key-features)
- [Architecture & Tech Stack](#-architecture--tech-stack)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
  - [Prerequisites](#prerequisites)
  - [Setup & Firebase Configuration](#setup--firebase-configuration)
  - [Running the App](#running-the-app)
- [Testing & Code Quality](#-testing--code-quality)
- [Building the Application](#-building-the-application)
- [CI/CD Pipeline](#-cicd-pipeline)
  - [GitHub Actions Workflow](#github-actions-workflow)
  - [Configuring CI Secrets](#configuring-ci-secrets)
- [Localization (i18n)](#-localization-i18n)
- [License](#-license)

---

## 🐝 About Hivemind

**Hivemind** is a modern Flutter application designed for shared spaces ("Hiveminds") and collaborative task management. Whether for households, couples, or teams, Hivemind keeps everyone in sync with real-time Firestore updates, rich recurrence schedules, push notifications, and seamless QR-code/deep-link invitations.

---

## 🚀 Key Features

- **Shared Spaces ("Hiveminds"):** Create or join collaborative spaces to share reminders and coordinate tasks with members.
- **Smart Reminders & Recurrence:**
  - Full support for RFC-5545 recurrence rules (`rrule`): daily, weekly, custom weekdays, intervals, and exceptions.
  - Due dates, time-of-day pickers, and member assignments.
- **Real-Time Synchronization:** Instant updates across all active clients powered by Cloud Firestore.
- **Notifications & Timezones:**
  - Local push notifications with sound and custom scheduling (`flutter_local_notifications`).
  - Robust timezone translation (`timezone`, `flutter_timezone`).
  - Remote push notifications via Firebase Cloud Messaging (FCM).
- **Instant Invitations & Onboarding:**
  - Shareable deep links via Universal Links / App Links (`app_links`).
  - Built-in QR Code Generator (`qr_flutter`) and integrated Camera Scanner (`mobile_scanner`).
- **Dynamic Theming & Localization:**
  - Polished Light and Dark modes with custom honey/amber branding (`HivemindAppTheme`).
  - English (`en`) and German (`de`) localization out of the box.

---

## 🛠 Architecture & Tech Stack

| Layer | Technology |
| :--- | :--- |
| **Framework** | [Flutter](https://flutter.dev) (Channel: `stable`) |
| **Language** | [Dart](https://dart.dev) (SDK: `^3.11.5`) |
| **State Management** | [Riverpod](https://riverpod.dev) (`flutter_riverpod`) |
| **Navigation** | [GoRouter](https://pub.dev/packages/go_router) with declarative route guards and deep links |
| **Backend & Auth** | [Firebase](https://firebase.google.com) (Authentication, Cloud Firestore, Cloud Messaging, Cloud Functions) |
| **Notifications** | `flutter_local_notifications` + `firebase_messaging` + `timezone` |
| **Tooling & Versioning** | [FVM](https://fvm.app/) (Flutter Version Management) |

---

## 📂 Project Structure

```text
hivemind/
├── .github/
│   └── workflows/
│       └── ci.yml               # GitHub Actions CI/CD pipeline (SHA pinned)
├── android/                     # Android native project (Kotlin, Gradle 8, Java 17)
├── assets/
│   └── logo/                    # Vector branding & app icons (SVG)
├── functions/                   # Firebase Cloud Functions (TypeScript)
├── ios/                         # iOS native project
├── lib/
│   ├── app.dart                 # Application lifecycle, deep-link & theme container
│   ├── main.dart                # Startup orchestration and service initialization
│   ├── core/                    # Core infrastructure:
│   │   ├── providers/           # Theme and locale state providers
│   │   ├── routing/             # GoRouter routes and redirect logic
│   │   ├── services/            # Firebase, FCM, Notifications, Timezone services
│   │   ├── theme/               # Light/Dark theme tokens & design system
│   │   └── widgets/             # Reusable core widgets (logos, buttons, dialogs)
│   ├── features/                # Domain features:
│   │   ├── auth/                # Sign-in, registration, session guards
│   │   ├── hiveminds/           # Space creation, member management, QR scanning
│   │   └── reminders/           # Reminders CRUD, recurrence picker, time pickers
│   ├── l10n/                    # Localization files (.arb) & generated delegates
│   └── shared/                  # Shared models, utilities, and components
├── test/                        # Comprehensive unit and widget test suites
├── pubspec.yaml                 # Dependencies and asset declarations
└── README.md
```

---

## 🏁 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (or [FVM](https://fvm.app/))
- [Java 17 JDK](https://adoptium.net/) (for Android builds)
- [Android Studio](https://developer.android.com/studio) / Xcode (for iOS)
- [Firebase CLI](https://firebase.google.com/docs/cli) (optional, for cloud configurations)

### Setup & Firebase Configuration

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd hivemind
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase:**
   The Android configuration file `android/app/google-services.json` is gitignored.
   To configure your own Firebase project:
   ```bash
   flutterfire configure
   ```
   *(Alternatively, for local test compilations without Firebase access, place a valid mock `google-services.json` with package `de.mf1337.hivemind` into `android/app/`)*.

### Running the App

```bash
# Run on an attached device or emulator
flutter run

# Run with a specific target platform
flutter run -d android
flutter run -d ios
```

---

## 🧪 Testing & Code Quality

Run static analysis and the test suite:

```bash
# 1. Format check
dart format --output=none --set-exit-if-changed .

# 2. Static analysis
flutter analyze

# 3. Unit and Widget tests
flutter test
```

---

## 📦 Building the Application

### Android

```bash
# Build Debug APK
flutter build apk --debug

# Build Release APK
flutter build apk --release

# Build Android App Bundle (for Google Play Console)
flutter build appbundle --release
```

Output files will be located in:
- APKs: `build/app/outputs/flutter-apk/`
- App Bundle: `build/app/outputs/bundle/release/`

---

## 🔄 CI/CD Pipeline

The project includes an enterprise-ready continuous integration and delivery pipeline defined in [`.github/workflows/ci.yml`](.github/workflows/ci.yml).

### GitHub Actions Workflow

- **Trigger:** Runs on every `push` and `pull_request` to `main`/`master`, or manually via `workflow_dispatch`.
- **Pinned Actions:** Every action is pinned using an immutable 40-character commit SHA:
  - `actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1` (`v7.0.1`)
  - `actions/setup-java@de7274f081f381c8f8158605e0321c36c376e2e6` (`v6.0.1`, Temurin JDK 17)
  - `subosito/flutter-action@1a449444c387b1966244ae4d4f8c696479add0b2` (`v2.23.0`, stable + cache)
  - `actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a` (`v7.0.1`)
- **Automated Quality Checks:** Formats, analyzes, and tests Dart code.
- **Automated Builds:** Compiles the **Release APK** with an incrementing build number and publishes uniquely tagged releases to GitHub Releases.

### Configuring CI Secrets

To enable builds with your production Firebase configuration in GitHub Actions:

1. Navigate to **Settings > Secrets and variables > Actions** in your GitHub repository.
2. Add a new repository secret:
   - **Name:** `GOOGLE_SERVICES_JSON`
   - **Value:** Paste the content of your `android/app/google-services.json` (as raw JSON or Base64 encoded).

> **Note:** If `GOOGLE_SERVICES_JSON` is not provided (e.g. pull requests from external forks), the CI automatically injects a placeholder manifest to ensure that compilation tests still pass without failing.

---

## 🌍 Localization (i18n)

Localization is configured via [`l10n.yaml`](l10n.yaml) with translation catalogs located in `lib/l10n/`:
- `app_en.arb` (English, default template)
- `app_de.arb` (German)

After editing `.arb` files, rebuild the localization classes:
```bash
flutter gen-l10n
```

---

## 📄 License

This project is licensed under the **PolyForm Noncommercial License 1.0.0**.

- ✅ **Permitted:** Noncommercial personal use, educational purposes, experimentation, private testing, and research.
- 🚫 **Restricted:** Any commercial use, monetized distribution, or deployment in commercial products/services by third parties is **strictly prohibited**.
- 💼 **Commercial Inquiries:** Commercial exploitation rights are reserved exclusively by the author. For commercial licensing, contact the repository owner.

See the full terms in the [LICENSE](LICENSE) file.
