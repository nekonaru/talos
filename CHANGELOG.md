# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-11-09

### Added

- **Video and audio downloads** from yt-dlp supported sites, as video up to 2160p or audio as MP3, M4A, Opus, FLAC or the source format.
- **Playlist support** with per-entry selection, select all or none, and per-item progress during download.
- **Embedded metadata and thumbnails** into downloaded files on desktop with FFmpeg, including cover art in audio files.
- **Embedded subtitles** with a selectable language into downloaded videos.
- **SponsorBlock** support to strip sponsor, self-promo and other segments by category.
- **Cookies file** support for sites that require a login.
- **Proxy, rate limit, concurrent fragments and aria2c** options for network-hungry downloads and fragile networks.
- **Custom commands** to run yt-dlp with your own argument templates, managed inside the app.
- **Downloads screen** with a sequential queue, cancel and retry, speed and ETA display, and a finished-downloads history with size and date.
- **Private mode** to skip history entirely.
- **Android engine**: yt-dlp runs in-process through Chaquopy, with a foreground service that keeps downloads alive and share-to-Talos from other apps.
- **Desktop engine**: yt-dlp is downloaded once and managed by the app, or uses the system yt-dlp, with automatic FFmpeg detection.
- **Warm dark design** with bronze accent, light and system modes, five accent hues, bilingual UI (English and Bahasa Indonesia).
- **Talos brand**: original mark, stacked and horizontal lockups, app icons for Android, iOS, Windows and macOS, and a dark splash screen.
- **Continuous integration**: analyze, test and build on every push and pull request.

[Unreleased]: https://github.com/nekonaru/talos/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/nekonaru/talos/releases/tag/v0.1.0
