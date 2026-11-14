# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Newest version on top.

## v0.6.0

Reliability and polish release: renaming a download no longer risks an unusable file, and the whole UI got a consistency pass.

### New features

- **Rename before download.** The Configure screen now has a File name field. Type the output file name with its extension (for example `My Video.mp4`) to rename a download. Empty keeps the automatic title-based name.
- **Automatic duplicate handling.** If the file name you typed already exists in the output folder, Talos writes `name (1).ext` instead of overwriting or failing. The same deduplication is applied when the app merges video and audio streams in-process, so repeated downloads with the same name never end up as broken files.

### Improvements

- **UI consistency audit.** All section headings use one shared widget, the spacing scale was normalized, and empty states were unified. The Downloads screen shows a Go to Home button when it is empty, Fetch stays disabled until a link is entered, and the accent color dots render correctly in light and dark mode.
- **Changelog housekeeping.** Removed a duplicated line in the v0.5.0 section.

### Download / Install

Download the file for your platform from Assets below. Android: `app-release.apk` (universal, for 64-bit Android devices). Windows: `Talos-v0.6.0-windows-x64.zip`. Linux: `Talos-v0.6.0-linux-x64.tar.gz`. A macOS build is not published yet; build from source instead. Requires Android 7.0 (API 24) or newer, Windows 10, or a recent GTK3 Linux build.

## v0.5.0

Feature plus audit release: you can now check for the latest version right inside the app, and several audit findings were fixed.

### New features

- **Check for updates.** About page now includes a "Check for updates" entry that queries GitHub Releases. If a newer version is available, it links straight to the download. If you are up to date, it tells you so.

### Bug fixes

- **Picker cancels never resolved the pending outcome.** If the system folder picker was cancelled, the app would wait forever for a result that never arrived, blocking the Settings UI. Now it returns immediately and the picker button can be used again.
- **Downloads silently fell back to private storage when the SAF folder was set but the grant was gone.** The task is now marked Failed with a clear message asking the user to re-pick or clear the storage folder in Settings instead.
- **File and folder open intents silently failed on Android 10+.** App no longer gates intents with `canLaunchUrl` (which almost always returns false on Android 10+); it tries to launch and shows a snackbar with an error message if it fails.

### Improvements

- **Translation audit.** A test now guarantees app_en.arb and app_id.arb have matching user-facing keys.
- **Look back.** ARB translation metadata is also validated to ensure placeholders are correctly registered.

### Download / Install

Download the file for your platform from Assets below. Android: `app-release.apk` (universal, for 64-bit Android devices). Windows: `Talos-v0.5.0-windows-x64.zip`. Linux: `Talos-v0.5.0-linux-x64.tar.gz`. A macOS build is not published yet; build from source instead. Requires Android 7.0 (API 24) or newer, Windows 10, or a recent GTK3 Linux build.

## v0.4.0

Quality-of-life release: you control where files land, the Finished tab shows the actual path and opens downloads in the default app, and formats are recommended based on the source.

### New features

- **Storage folder picker on Android (SAF).** Settings > Downloads > Pick folder opens the system folder picker. Pick any writable folder (for example Download > Talos) and every future download lands in <picked folder><path separator>Talos. Clear to fall back to app private storage.
- **Recommended format badge.** In the format picker, the platform's recommended video (highest-resolution, MP4/H.264 preferred) and recommended audio (highest bitrate, M4A/AAC preferred) are marked with a star prefix. Highest-res video formats are listed first.
- **Sponsor page.** The About page lists author GitHub and the Sponsor links: GitHub Sponsors, Saweria, SociaBuzz and BagiBagi.
- **Finished tab surfaces the file path.** Each entry shows the path, opens the file with the default app on tap, lets you copy the folder path on Android, and keeps the open/share/remove/delete actions.
- **Delete file directly.** A long-press menu deletes both the history entry and the downloaded file in one tap. Previously "clear finished" only cleared the list; now there is a visible "Delete file" button per entry.

### Improvements

- **History rebuilds immediately.** Clearing finished, removing entries and deleting files now refresh the Finished tab instantly; previously a delay was possible until another event triggered a rebuild.
- **Pick folders use SAF.** SAF persisted grant is validated at app start; stale grants are discarded instead of failing downloads silently into private storage.

## v0.3.0

Engine upgrade: YouTube downloads on Android now reach much higher quality tiers via in-app merging, plus cold-start, stability and licensing improvements.

### New features

- **Bundled FFmpeg on Android.** Talos now merges the separate video-only and audio-only streams yt-dlp puts out, instead of being stuck with muxed formats under ~360p. Streams up to 720p60+ are served over DASH with direct URLs and muxed in-app.
- **Best codec auto-pick.** With the merge path in place, Android picks the same best direct DASH streams desktop does, so the cap is gone for good.

### Improvements

- **Cold start is less bursty.** Python warm-up now happens on a background thread at engine attach, not inside a forced status check. Status polling no longer triggers Python startup on the calling isolate.
- **android runtime package flows.** The debug build supports arm64-v8a and x86_64 for emulator verification; release builds cover arm64-v8a only.

### Licensing

- **FFmpegKit (LGPL-3.0, dynamic)** is needed to merge streams; Talos does not statically link FFmpeg or ship GPL encoders.

## v0.2.3

Stability and engine release: a format client fix that unblocks YouTube downloads on Android, plus a batch of robustness improvements.

### Bug fixes

- **YouTube video downloads on Android failed with "Requested format is not available".** YouTube returns no muxed formats on the default clients, and Android has no FFmpeg to merge streams, so nothing could be selected. Embedded builds now pin a client that still serves a muxed MP4 (up to 360p) for video mode; audio mode is unchanged.
- **Desktop engine could miss the last output lines.** stdout and stderr streams are drained before the session resolves, so output paths and progress lines are no longer dropped at exit.
- **Retry ignored separate video or audio folders.** A retry now targets the configured folder for the media type instead of the default directory.
- **Settings, history and command templates could be left half-written.** Writes are now atomic; a crash mid-write can no longer corrupt these files.
- **Cookie export file was world-readable on POSIX systems.** The cookies file is now owner-only, written atomically.

### Improvements

- **Bundled fonts.** Marcellus and Inter ship inside the app instead of being fetched over the network on first launch. Faster, offline-friendly start.
- **Lower memory on engine downloads.** The managed yt-dlp and FFmpeg downloads stream to disk instead of buffering tens of megabytes in memory.
- **i18n sweep.** All user-facing text now comes from the localization files; no hardcoded strings left.
- **iOS no longer crashes at startup.** The engine reports itself as not yet available until an iOS backend exists.

## v0.2.2

Bug fixes release. No new features.

### Bug fixes

- **Android downloads failed on every attempt.** The embedded engine no longer passes a Java object into Python; output lines are buffered and polled by the host, and engine errors carry the real yt-dlp message.
- **Settings UI updated with a delay.** Toggling or editing a setting now rebuilds the screen and the dependent UI instantly.
- **Wrong version reported.** The app reported 0.1.0 on every release; it now reports the actual version, and a test keeps pubspec.yaml and the About screen in sync.
- **iOS startup crash.** The app no longer crashes at launch on iOS; the engine reports itself as not yet available until an iOS backend exists.

## v0.2.1

Follow-up polish to the v0.2.0 feature set: a persistent notification toggle, richer subtitle handling, and channel choice for the managed engine.

### New features

- **Notification toggle.** Turn off the foreground notification during downloads without losing the download.
- **Subtitle controls.** Enable automatic subtitles, keep subtitle sidecar files, and convert them to another format.
- **Engine channel.** Choose stable or nightly yt-dlp releases for managed updates. Also available for auto update.
- **Custom command folder.** Dedicated directory for output produced by custom command templates.

## v0.2.0

This release closes the main feature gap with comparable apps: manual format selection, an in-app cookie generator, per-task engine logs, and shared-output folders.

### New features

- **Manual format selection.** Pick specific video and audio formats per download with full codec, bitrate, resolution and size details.
- **In-app cookie generator.** Sign in to a site in an embedded WebView and save the session cookies for yt-dlp. Works on Android and iOS.
- **Task log.** Every failed task keeps the last 500 lines of raw engine output, with a one-tap copy button for bug reports.
- **Download archive.** Skip already-downloaded items using a persistent archive file.
- **Crop square artwork.** Square cover art for audio files, a common request from Android Auto and music players.
- **Format sorting.** yt-dlp `-S` string to prefer extensions and resolutions, for example `ext,res`.
- **Remux to mp4, mkv or webm.** Choose the output container without re-encoding.
- **Clip video.** Download only a section with start and end times.
- **Max filesize.** Skip items larger than a configurable cap, for example `50M`.
- **Separate video and audio folders.** Dedicated download directories for each media type.
- **Auto engine update.** Weekly background check for a newer managed engine, opt-in in Settings.
- **Custom User-Agent.** Override the HTTP User-Agent header for sites that need it.

### Improvements

- **SponsorBlock and cookies tone refit.** Existing options now live in the right sections, with helper text.

### Bug fixes

- **Log button** on failed tasks now reveals engine output instead of a truncated one-liner.

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
- **Talos brand.** Original mark, app icons for Android, iOS, Windows and macOS, and a dark splash screen.
- **Continuous integration.** Analyze, test and build on every push and pull request.
