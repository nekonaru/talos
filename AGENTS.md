# Talos

Open-source video and audio downloader for Android, iOS, Windows, macOS and Linux.
The download engine is yt-dlp, running in-process on Android through Chaquopy and as
a managed or system binary on desktop.

# Project

- PROJECT_NAME: Talos
- REPO: nekonaru/talos
- AUTHOR_NAME: Nicolas Dwi Dharma
- AUTHOR_GITHUB: nekonaru
- PROJECT_KIND: app
- STACK: Flutter (Dart)
- PLATFORMS: Android, iOS, Windows, macOS, Linux
- MIN_OS: Android 7.0 (API 24), Windows 10, macOS 10.15, Linux (Debian-like)
- DEFAULT_BRANCH: main
- LICENSE: MIT
- UI_LANGUAGES: English, Bahasa Indonesia
- VERIFICATION: local-and-ci

# Working on this repository

- English is the source language. Bahasa Indonesia is a translation, kept in sync.
- No em dash, no en dash, no emoji in docs, README, changelog, release notes or UI strings.
- UI strings live in `lib/l10n/app_en.arb` (English) and `lib/l10n/app_id.arb` (Indonesian).
  Run `flutter gen-l10n` after editing them. Files in `lib/gen/` are generated and are not committed.
- Verify before every push: `flutter gen-l10n`, `flutter analyze`, `flutter test`.
- The app icon and logo are generated from `assets/` only. The working files used while
  designing the logo are local-only and are never committed.
- The Android APK bundles a Python runtime and yt-dlp. The download engine must stay
  GPL-free: only MIT, BSD, Apache-2.0 or similarly permissive components may be linked.
  yt-dlp itself is Unlicense and Chaquopy is MIT.
