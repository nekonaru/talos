# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Newest version on top.

## v0.1.1

Better out-of-the-box behavior: auto engine setup, managed FFmpeg on Windows, clearer errors, and a smaller APK (45 MB, arm64-v8a).

### New features

- **Automatic engine setup.** Pressing Fetch with no engine installs yt-dlp (and FFmpeg on Windows), then fetches.
- **Managed FFmpeg on Windows.** FFmpeg is downloaded automatically with SHA-256 verification, so embedding metadata, thumbnails and subtitles works without manual setup.
- **Open from notification.** A persistent notification is shown while a download is running; it disappears when the queue is empty.

### Improvements

- **Smaller APK.** The release build ships arm64-v8a only, shrinking the APK from roughly 80 MB to 45 MB.

### Bug fixes

- **Downloads no longer fail silently.** Common engine errors (403, bot check, private video, live streams, missing FFmpeg) surface as readable messages instead of raw Python output.
- **Android file actions.** Opening a finished file uses the share sheet on Android; desktop keeps Open and Show in folder.
- **Failed tasks show more error text** (up to three lines) and tapping the error copies it to the clipboard for support.
- **Managed runner path.** Embedded FFmpeg on Windows is preferred over system PATH, so the app uses the verified managed binary.

## v0.1.0

The first release of Talos, a video and audio downloader for Android, iOS, Windows, macOS and Linux.

### New features

- **Video and audio downloads.** Download from yt-dlp supported sites, as video up to 2160p or audio as MP3, M4A, Opus, FLAC or the source format.
- **Playlist support.** Per-entry selection with select all or none, and per-item progress during download.
- **Embedded metadata and thumbnails.** Embed title, artist, album art and other metadata into downloaded files on desktop with FFmpeg, including cover art in audio files.
- **Embedded subtitles.** Embed subtitles into downloaded videos with a selectable language.
- **SponsorBlock.** Remove sponsor, self-promo and other segments by category.
- **Cookies file.** Download from sites that require a login with a cookies.txt file.
- **Proxy, rate limit, concurrent fragments and aria2c.** Options for heavy downloads and fragile networks.
- **Custom commands.** Run yt-dlp with your own argument templates, managed inside the app.
- **Downloads screen.** Sequential queue with cancel and retry, speed and ETA, and a finished-downloads history with size and date.
- **Private mode.** Optionally skip history entirely.
- **Android engine.** yt-dlp runs in-process through Chaquopy, with a foreground service that keeps downloads alive and share-to-Talos from other apps.
- **Desktop engine.** yt-dlp is downloaded once and managed by the app, or uses the system yt-dlp, with automatic FFmpeg detection.
- **Warm dark design.** A warm dark theme with a bronze accent, light and system modes, five accent hues, bilingual UI (English and Bahasa Indonesia).
- **Talos brand.** Original mark, stacked and horizontal lockups, app icons for Android, iOS, Windows and macOS, and a dark splash screen.
- **Continuous integration.** Analyze, test and build on every push and pull request.
