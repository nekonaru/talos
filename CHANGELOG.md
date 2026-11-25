# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Newest version on top.

## v0.27.0

A large update adding explicit queue controls and coverage for desktop engine asset selection.

### New features

- **Pause and resume queue.** New downloads can be held without stopping the task already running. The paused state persists across restarts, and resuming starts the queue immediately.
- **Clear pending downloads.** A confirmation action cancels every task that has not started, leaving the active download untouched.

### Improvements

- **90 tests passing**, including pause/resume and desktop asset selection coverage.
- **Distinct icons.** Clear finished and clear pending now use different icons to avoid ambiguity.

### Download / Install

Download the file for your platform from Assets below. Android: `app-release.apk`. Windows: `Talos-v0.27.0-windows-x64.zip`. Linux: `Talos-v0.27.0-linux-x64.tar.gz`. A macOS build is not published yet; build from source instead. Requires Android 7.0 (API 24), Windows 10, or a recent GTK3 Linux build.

## v0.26.0

A large update adding custom HTTP headers, plus a native merge ordering fix.

### New features

- **Custom headers.** Settings accepts newline-separated `Name: value` headers. Each line is passed to yt-dlp with `--add-headers`, so sites requiring a specific Referer work without a cookies file.

### Bug fixes

- **Merge stream order.** The Android merger now puts the larger part first, so FFmpeg picks the video stream when yt-dlp lists the audio part first.

### Improvements

- **88 tests passing**, including a custom header argument test.
- **Header persistence.** Custom headers are saved with settings and carried through queued and restored downloads.

### Download / Install

Download the file for your platform from Assets below. Android: `app-release.apk`. Windows: `Talos-v0.26.0-windows-x64.zip`. Linux: `Talos-v0.26.0-linux-x64.tar.gz`. A macOS build is not published yet; build from source instead. Requires Android 7.0 (API 24), Windows 10, or a recent GTK3 Linux build.

## v0.25.0

A large update adding a WiFi-only download gate on Android, backed by a native connectivity check.

### New features

- **WiFi only.** When enabled on Android, queued downloads pause and resume automatically when an active WiFi connection is detected. Tasks keep their position and settings while waiting. Turning the setting off restarts the queue immediately.

### Bug fixes

- **Network permission.** ACCESS_NETWORK_STATE is now declared explicitly as a normal permission for the connectivity check. No runtime prompt is added.

### Improvements

- **87 tests passing**, including a WiFi gating regression with an injectable probe.
- **Queue feedback.** Waiting tasks show a distinct stage instead of looking stalled.

### Download / Install

Download the file for your platform from Assets below. Android: `app-release.apk`. Windows: `Talos-v0.25.0-windows-x64.zip`. Linux: `Talos-v0.25.0-linux-x64.tar.gz`. A macOS build is not published yet; build from source instead. Requires Android 7.0 (API 24), Windows 10, or a recent GTK3 Linux build.

## v0.24.0

A large update adding a runtime license inventory and automatic history retention, plus engine memory and version alignment fixes.

### New features

- **Runtime licenses.** About now links to an explicit inventory of the licenses of yt-dlp, Chaquopy, FFmpegKit, the desktop engine binaries, managed FFmpeg and the Dart packages.
- **History retention.** Old history rows can be dropped automatically on startup after 7, 30 or 90 days. Files on disk are never deleted by this setting.

### Bug fixes

- **FFmpeg extraction memory.** The managed Windows FFmpeg binaries are streamed to disk instead of decompressed fully in memory.
- **Engine version drift.** The Android yt-dlp pin now matches the desktop managed version.
- **Author label.** The About screen uses the localized GitHub label instead of hardcoded English.

### Improvements

- **86 tests passing**, including history retention coverage.
- **License transparency.** The open GPL and LGPL component question is now documented in the app itself.

### Download / Install

Download the file for your platform from Assets below. Android: `app-release.apk`. Windows: `Talos-v0.24.0-windows-x64.zip`. Linux: `Talos-v0.24.0-linux-x64.tar.gz`. A macOS build is not published yet; build from source instead. Requires Android 7.0 (API 24), Windows 10, or a recent GTK3 Linux build.

## v0.23.0

A large update adding queue persistence, plus smaller polish fixes from the ongoing deep audit.

### New features

- **Queue persistence.** Pending downloads are saved atomically and resumed after an app restart with their full request and retry count. A task killed mid-run returns to the queue instead of being lost.
- **Queue in backup.** Portable backups now include the pending queue alongside settings, history, saved links, presets and commands.

### Bug fixes

- **Localized weekdays.** Insight activity labels follow the active locale instead of hardcoded English initials.
- **Favorite tooltips.** The star button now says Add to favorites or Remove from favorites instead of a generic label.

### Improvements

- **85 tests passing**, including full request serialization and queue restore coverage.
- **Explicit intl dependency.** The date formatter now declares the package it imports.

### Download / Install

Download the file for your platform from Assets below. Android: `app-release.apk`. Windows: `Talos-v0.23.0-windows-x64.zip`. Linux: `Talos-v0.23.0-linux-x64.tar.gz`. A macOS build is not published yet; build from source instead. Requires Android 7.0 (API 24), Windows 10, or a recent GTK3 Linux build.

## v0.22.0

A large update adding automatic retries, plus a second deep audit pass on navigation, error messages, native startup and UI performance.

### New features

- **Auto retry.** Failed downloads can be retried automatically up to three times with a short linear backoff. Storage permission and cancellation errors are never retried.

### Bug fixes

- **Format selector.** Reopening the format picker no longer clears a stored custom selector such as `bv*[height<=720]+ba`.
- **Localized errors.** Settings, Downloads and Home now share one resolver, so engine errors are translated instead of leaking English text in the Indonesian UI.
- **Command templates.** A failed load shows a retry button instead of an endless spinner.
- **Clear finished.** The confirmation now explains that only the list is cleared and files on disk remain.
- **Insights cleanup.** A partial cleanup reports how many files could not be deleted instead of claiming full success.
- **Cookie generator.** An explicit Close button leaves the screen without walking the whole WebView history.
- **Tab rebuilds.** Switching tabs no longer rebuilds the list on duplicate TabController notifications.
- **Hardcoded strings.** Engine channel names and the GitHub author label are now localized.
- **aria2c.** Enabling aria2 without the binary installed fails with a clear message instead of failing every download cryptically.
- **Python startup.** A process-wide lock prevents two Flutter engines from starting Chaquopy's Python runtime at the same time.
- **FileProvider.** External storage sharing is limited to the app's Download/Talos directory.
- **Gradle memory.** The daemon heap was lowered to reduce native out-of-memory failures on Chaquopy builds.
- **Symbols.** Obfuscated release builds now upload their symbol files with the APK artifact.

### Improvements

- **Async filename resolution.** Directory scans no longer block the UI isolate when a download is enqueued.
- **83 tests passing**, including a transient-failure retry test.
- **Dead code removed.** An unused Activity field no longer retains an Activity reference.

### Download / Install

Download the file for your platform from Assets below. Android: `app-release.apk`. Windows: `Talos-v0.22.0-windows-x64.zip`. Linux: `Talos-v0.22.0-linux-x64.tar.gz`. A macOS build is not published yet; build from source instead. Requires Android 7.0 (API 24), Windows 10, or a recent GTK3 Linux build.

## v0.21.0

A large update adding portable backup and restore, plus deep audit fixes for cancellation, Android storage, playlist merges and engine bootstrap.

### New features

- **Backup and restore.** Settings, history, saved links, presets and command templates can be exported as portable JSON and restored on the same device or a new one. Downloaded files are left untouched.

### Bug fixes

- **Cancel during post-processing.** A cancel arriving after the engine finished no longer writes a history row or leaves a copied file behind.
- **Playlist outputs.** Android playlist merges now report every output, so all items are saved and added to history instead of only the last one.
- **Failed merges.** A failed FFmpeg merge is reported as an error instead of saving a raw partial stream as the finished file.
- **Probe JSON.** yt-dlp diagnostics on stderr no longer corrupt the JSON payload returned by the Android probe.
- **MediaStore delete.** Files saved through MediaStore are deleted with ContentResolver, so the delete action works on API 29 and later.
- **Delete failure.** A failed file delete keeps its history row and shows a message instead of silently orphaning the file.
- **Engine status failure.** Configure shows a retry action instead of leaving Download disabled forever with no explanation.
- **Windows paths.** Custom commands keep backslashes in paths such as `C:\Users\me\cookies.txt`.
- **URL option injection.** An end-of-options marker now precedes URLs so a saved link starting with a dash cannot inject yt-dlp flags.
- **Desktop engine bootstrap.** Linux selects standalone glibc or musl builds, and armv7 extracts the binary from its zip asset. FFmpeg setup requires both ffmpeg.exe and ffprobe.exe.
- **Engine deadlocks.** Process startup and stream decode failures always complete the session outcome, so the sequential queue cannot hang.
- **Unique filenames.** After many collisions Talos uses a time-based suffix instead of falling back to an occupied name.
- **MIME types.** `.3gp`, `.3g2` and `.mov` are indexed with the correct MediaStore MIME type.
- **Folder unlink.** Clearing a SAF folder now releases the persisted URI permission.
- **Release signing.** A release build fails clearly when the signing key is missing instead of silently using the debug key.
- **Localization.** The Indonesian UI now uses the translated tagline on Home, Intro and About.
- **Fetch feedback.** Text without a valid URL now shows a localized hint instead of doing nothing.

### Improvements

- **82 tests passing**, including backup round trip and command builder regressions.
- **CI gating.** Build jobs now wait for the verify job so artifacts are not produced from failing code.
- **Engine detection.** The managed engine is identified by its real path instead of a path substring, so system installs are reported correctly.
- **Process timeouts.** Version and probe processes are killed on timeout instead of being left running.

### Download / Install

Download the file for your platform from Assets below. Android: `app-release.apk`. Windows: `Talos-v0.21.0-windows-x64.zip`. Linux: `Talos-v0.21.0-linux-x64.tar.gz`. A macOS build is not published yet; build from source instead. Requires Android 7.0 (API 24), Windows 10, or a recent GTK3 Linux build.

## v0.20.0

A large update adding a redownload action for finished entries, plus correctness fixes for Android folders, playlist merging and bulk saved links found in a fresh deep audit.

### New features

- **Download again.** Every finished entry now has a "Download again" action in its menu. It probes the stored URL and opens Configure with fresh media info so settings can be changed before downloading again.

### Bug fixes

- **Android per-type folders.** A user-chosen video or audio folder is now authoritative on API 29+; files are no longer silently relocated into Downloads/Talos and the chosen folder emptied.
- **Android playlists.** Video/audio parts are now grouped by base name and merged per item, so a playlist no longer finishes with one broken fragment and orphaned streams.
- **Download all saved links.** All URLs are now flattened through the same detector used by the input field, so multi-link saves keep every URL and a single saved link downloads correctly instead of doing nothing.
- **Android success detection.** A transient `ERROR:` line no longer marks a successful download as failed; the native status is authoritative.
- **Error-line parsing.** yt-dlp errors with a `[site] ERROR:` prefix are now detected, while unrelated words are not.
- **FFmpeg setup memory.** The essentials archive is decoded as a stream instead of fully buffered in memory.
- **Filename helpers.** Uniqueness loops are bounded and directory scans are less likely to stall the UI.
- **MediaStore MIME.** `.m4a` files are indexed as `audio/mp4` instead of video.
- **SAF copies.** Empty documents are no longer left behind when a copy fails.
- **Localization.** Added the missing `@appTitle` metadata to the Indonesian ARB.

### Improvements

- **78 tests passing**, with stable expectations for the new async filename resolution.

### Download / Install

Download the file for your platform from Assets below. Android: `app-release.apk` (universal, for 64-bit Android devices). Windows: `Talos-v0.20.0-windows-x64.zip`. Linux: `Talos-v0.20.0-linux-x64.tar.gz`. A macOS build is not published yet; build from source instead. Requires Android 7.0 (API 24) or newer, Windows 10, or a recent GTK3 Linux build.

## v0.19.0

A large update led by bulk download for saved links, plus concurrency and reliability fixes found in a fresh deep audit.

### New features

- **Download all saved links.** The Saved links section has a "Download all" action that opens the same video/audio batch dialog as pasted links. Every saved link is queued with the current settings, and the input field is left untouched.

### Bug fixes

- **Android engine concurrency.** A module-level lock now serializes Python entry points, so starting a probe while a download runs can no longer swap the process-wide stdout/stderr out from under the active task and corrupt progress or probe results.
- **Desktop cancel.** Cancelling just after a download starts now kills the spawned yt-dlp process instead of letting it write a file with no history row.
- **Concurrent JSON saves.** Each atomic write now uses a unique temp file, so overlapping settings, history, saved-link or preset mutations cannot truncate each other.
- **Template deletion.** Seed command templates are now inserted only on a fresh install; deleting all templates stays deleted.
- **Text scaling.** The upper scale clamp was raised from 1.3 to 2.0, so OS accessibility text sizes are respected.
- **Playlist filenames.** A typed name is now folded into the indexed playlist template instead of being ignored.
- **Cookie export.** Cookies are read from the URL actually loaded in the WebView, not from a different URL the user typed without navigating.
- **Insights performance.** The summary is cached by history revision instead of re-sorting the whole library on every progress rebuild.
- **Localization.** Added Indonesian placeholder metadata for the playlist-count and cookies-saved messages; the parity test now checks metadata in both languages.

### Improvements

- **78 tests passing**, including a two-language ARB metadata parity check.

### Download / Install

Download the file for your platform from Assets below. Android: `app-release.apk` (universal, for 64-bit Android devices). Windows: `Talos-v0.19.0-windows-x64.zip`. Linux: `Talos-v0.19.0-linux-x64.tar.gz`. A macOS build is not published yet; build from source instead. Requires Android 7.0 (API 24) or newer, Windows 10, or a recent GTK3 Linux build.

## v0.18.0

A reliability and performance release. It addresses the reported Android install failure with CI-level artifact verification, and makes the app lighter and smoother without adding new feature families.

### Bug fixes

- **Android merge.** A user-entered ffmpeg path no longer disables stream merging on Android. FFmpegKit is always used, so downloads cannot end with two orphan stream files. The ffmpeg path field is now desktop-only.
- **Foreground service.** Removed a 1-second repeating callback that woke the Dart isolate throughout every download without doing any work.
- **Native Back handling.** The cookie WebView now uses Back for browser history, and device Back exits Finished multi-selection mode before popping the screen.
- **Accessibility text.** System text scaling is clamped so dense rows do not overflow at very large font sizes.

### Improvements

- **Install reliability.** CI now verifies every release APK with `apksigner` (v2 signature and Talos certificate), checks that no x86_64 libraries leaked into the arm64 artifact, validates 16 KB alignment, and records a SHA-256 checksum. The README explains the common causes of "the package appears to be invalid" and how to verify a download.
- **Smaller APK.** Enabled R8 minification and resource shrinking with keep rules for the Flutter, Chaquopy and FFmpegKit bridges, plus Dart obfuscation and split debug info. Release size dropped from about 66.8 MB to 62.7 MB.
- **Faster startup.** Settings, history, saved links, presets, Android SDK level and SAF state now load concurrently instead of one after another.
- **Smoother downloads.** The Finished list caches its sorted/filtered result by history revision, so progress ticks no longer re-sort up to 300 entries. The shell builds its pages once instead of on every rebuild.
- **Leaner bundle.** Removed the unused `cupertino_icons` dependency and stopped packaging license text files as app assets.

### Download / Install

Download the file for your platform from Assets below. Android: `app-release.apk` (universal, for 64-bit Android devices). Windows: `Talos-v0.18.0-windows-x64.zip`. Linux: `Talos-v0.18.0-linux-x64.tar.gz`. A macOS build is not published yet; build from source instead. Requires Android 7.0 (API 24) or newer, Windows 10, or a recent GTK3 Linux build.

## v0.17.0

A large update adding reusable download presets and fixing data-loss, correctness and performance issues found in a fresh deep audit.

### New features

- **Download presets.** Save the current Configure choices (video/audio mode, quality, format, bitrate, subtitle and metadata options, format selector) as a named preset. Presets persist locally, can be applied with one tap, renamed by saving again, and deleted. Global settings such as folder, proxy and archive are intentionally not overridden.

### Bug fixes

- **Playlist filename safety.** A typed output filename is no longer applied to playlists, which previously wrote every entry to the same path and left only the last file. Playlists with a typed name now use an indexed title template.
- **Clip setting honesty.** The clip-range control is hidden on Android and iOS, where no ffmpeg executable is available and the setting was silently ignored. On desktop, the range dialog now rejects non-numeric, negative and reversed ranges instead of saving invalid values.
- **Clip units localized.** The seconds label in the clip summary is now a translation key.
- **Reset completeness.** "Reset all data" now also clears saved links and presets, matching its confirmation text.
- **Progress performance.** Download progress notifications are coalesced to at most 10 per second, avoiding full-tree rebuilds of all tabs on every yt-dlp line.
- **Saved links and presets are shared.** Both stores live on the app manager, so adding, removing or resetting them updates every screen immediately.
- **Large-list performance.** Saved links and playlist entries now use lazy list builders instead of allocating every row on each rebuild.
- **Insights cleanup.** A stale messenger reference after file deletion no longer throws if the screen is closed.
- **Oxblood contrast.** The dark-theme oxblood accent was lightened to meet text contrast requirements.
- **Saved-link safety.** The bookmark button now requires an actual URL, and opening a saved link no longer throws on invalid text.
- **Paste reliability.** Clipboard failures no longer produce an unhandled async error.
- **Bar accessibility.** Activity bars now announce a full date and count instead of ambiguous single letters.

### Improvements

- **77 tests passing**, including new coverage for preset persistence and reset wiring.

### Download / Install

Download the file for your platform from Assets below. Android: `app-release.apk` (universal, for 64-bit Android devices). Windows: `Talos-v0.17.0-windows-x64.zip`. Linux: `Talos-v0.17.0-linux-x64.tar.gz`. A macOS build is not published yet; build from source instead. Requires Android 7.0 (API 24) or newer, Windows 10, or a recent GTK3 Linux build.

## v0.16.0

A large update adding saved links and fixing download-command correctness, platform targets and data-accuracy issues found in a fresh deep audit.

### New features

- **Saved links.** Bookmark the current URL from the Home field with the new bookmark button. Saved links persist locally, show in a "Saved links" section, and can be opened in a browser, fetched directly, or removed. Whole pasted batches are saved, not just the first URL, and duplicates are ignored.

### Bug fixes

- **Clip download sections.** A start-only or end-only clip now produces a valid yt-dlp `*start-end` section instead of a malformed selector that always failed. The flag is only emitted when ffmpeg is available, so mobile downloads are not failed by unsupported post-processing.
- **ffmpeg gating.** Subtitle conversion and SponsorBlock chapter removal are now gated by ffmpeg availability, matching the existing embed-subtitle and metadata guards.
- **Player time labels.** Durations over one hour no longer show values such as `1:62:05`.
- **Insights type bar.** The audio proportion is now computed from actual audio bytes instead of `1 - video share`, so libraries with no size data no longer show a full audio bar.
- **Activity dates.** Day bucketing uses UTC-normalized calendar days, so daylight-saving transitions cannot shift a download into the wrong bar.
- **macOS minimum.** Deployment target restored to the documented macOS 10.15.
- **ARM Linux.** Downloads now use the correct yt-dlp binary for arm64 and armv7 Linux instead of the x86_64 one.
- **Format selection.** Muxed formats are no longer offered as video-only streams, and an unknown initial format id is no longer forced into an invalid selector.
- **Cookie generator.** Saving cookies now validates the URL the same way as reloading, instead of silently falling back to a default site.
- **Android merge.** Recognizes yt-dlp format ids containing letters, so streams from more sites merge correctly.
- **Saved-links UI.** Adding or removing a link now rebuilds the Home screen immediately.

### Improvements

- **76 tests passing**, including new coverage for clip sections, saved-link persistence and zero-size Insights shares.

### Download / Install

Download the file for your platform from Assets below. Android: `app-release.apk` (universal, for 64-bit Android devices). Windows: `Talos-v0.16.0-windows-x64.zip`. Linux: `Talos-v0.16.0-linux-x64.tar.gz`. A macOS build is not published yet; build from source instead. Requires Android 7.0 (API 24) or newer, Windows 10, or a recent GTK3 Linux build.

## v0.15.0

A large update led by a new Insights tab, backed by the widest platform and concurrency audit yet. Fixes span native macOS, Android lifecycle, the sequential queue and cross-platform file handling.

### New features

- **Insights tab.** A fourth tab summarizes the finished library: total downloads, total size and last-30-days count, a seven-day activity chart, a video/audio breakdown with favorites, the five largest downloads, and a guarded cleanup action that deletes downloads older than 30 days after confirmation. All metrics come from a pure, tested helper.

### Bug fixes

- **macOS networking and storage.** The sandbox now declares network-client and Downloads read-write entitlements, so engine setup, update checks and media downloads work in signed macOS builds.
- **Engine install errors.** The Home engine banner now catches setup failures and shows one friendly message instead of an unhandled async error. iOS shows a clear "not available yet" message with no impossible Install button.
- **Cancellation windows.** Cancel now stops a download after the engine finishes but before file copying and history writing. A cancel during post-processing writes no history row, and the foreground service stops when the last queued task is cancelled.
- **Stale session clobber.** A finished run can no longer clear the session reference of a newer download after a reset and re-enqueue.
- **Custom command cancel.** Cancelling a custom command now kills the underlying OS process and reports non-zero exit codes, instead of leaving yt-dlp running.
- **Chaquopy startup race.** Python runtime initialization is synchronized, so concurrent method handlers cannot both start it.
- **Terminal engine events.** Android buffers events emitted between Dart subscriptions and replays them, so a fast download cannot hang the queue.
- **SAF setting resilience.** A transient native error no longer wipes the user's chosen download folder.
- **Windows atomic writes.** Settings and history saves now replace existing files atomically on Windows instead of silently falling back to a plain write.
- **Reset completeness.** Reset all data now restores the default download directory.
- **Intent subscription.** A disposed Home screen no longer leaks a share-intent subscription, and live shares keep working if the initial-link lookup fails.
- **Legacy Android paths.** API 24-28 downloads now return a plain absolute path, so files can be opened, shared and deleted through the UI.
- **SAF file extension.** Copied files keep their full name instead of risking a missing extension.
- **Folder picker.** A repeated pick no longer leaves the first request unresolved.
- **Permission prompt.** The "already prompted" flag is now persisted only after the request is posted.
- **Update check timeout.** A stalled release-body read can no longer hang the update check.
- **Localization.** Added the iOS engine message and updated remaining Indonesian strings.

### Improvements

- **73 tests passing**, including new coverage for insights aggregation.
- **Reusable deletion helper** shared between Finished batch delete and Insights cleanup.

### Download / Install

Download the file for your platform from Assets below. Android: `app-release.apk` (universal, for 64-bit Android devices). Windows: `Talos-v0.15.0-windows-x64.zip`. Linux: `Talos-v0.15.0-linux-x64.tar.gz`. A macOS build is not published yet; build from source instead. Requires Android 7.0 (API 24) or newer, Windows 10, or a recent GTK3 Linux build.

## v0.14.0

A large update led by a smooth animated intro, backed by another deep audit that closed defects across the download flow, settings and player.

### New features

- **Animated intro.** A short brand reveal plays on launch: the helmet scales and fades in with a soft halo, the wordmark rises, a bronze progress line draws, then the whole scene fades into the app. Tap anywhere to skip. Reduced-motion users see a static, instant version. Timing uses shared motion tokens.
- **Theme-aware native splash.** The Android launch background now matches the active system theme, so light-theme users no longer see a dark flash before the app opens. The same shield mark is used across the native splash and the intro.

### Bug fixes

- **Embed subtitles switch.** The Configure toggle now actually controls `--embed-subs`; subtitles are no longer always embedded on desktop or never embedded on Android.
- **Cancel during startup.** Tapping Cancel while permissions or ffmpeg probing are still running now stops the download instead of being ignored. Reset also stops an in-flight task before it can write history.
- **Custom command folder.** The configured output folder is now passed to custom commands as their working directory.
- **Single-link fetch.** Pasting a link with surrounding text or trailing punctuation now uses the extracted URL, matching batch mode.
- **Clearer errors.** Engine setup failures show one friendly message instead of a raw error plus a duplicate. Storage-save failures are now localized instead of hardcoded English.
- **Clip range display.** A clip range with only an end time no longer shows "null sec".
- **Audio format filter.** Muxed video+audio formats are no longer listed as audio-only, which previously produced invalid download selectors.
- **Selection safety.** Changing search or filters now clears multi-selection, so batch delete cannot touch entries that are no longer visible.
- **Settings resilience.** Stale or hand-edited dropdown values are normalized on load, preventing a crash on the Settings screen.
- **Link fallbacks.** The update Download button now copies the URL and shows a message when no browser is available.
- **Player cleanup.** Failed initialize/play now disposes the controller, and the controls no longer rebuild twice per position update.
- **Share-intent race.** A link shared during cold start is buffered natively and replayed once Dart subscribes, so it is never dropped.

### Improvements

- **Untranslated strings.** Remaining English phrases in Bahasa Indonesia were translated, and the About screen now marks aria2 as an optional external tool.
- **Consistent chrome.** Navigation rail (wide layout) now uses theme colors; accent swatch check marks adapt to each accent's brightness.
- **72 tests passing**, including new coverage for subtitle embedding and settings normalization.

### Download / Install

Download the file for your platform from Assets below. Android: `app-release.apk` (universal, for 64-bit Android devices). Windows: `Talos-v0.14.0-windows-x64.zip`. Linux: `Talos-v0.14.0-linux-x64.tar.gz`. A macOS build is not published yet; build from source instead. Requires Android 7.0 (API 24) or newer, Windows 10, or a recent GTK3 Linux build.

## v0.13.0

A stability and design pass over the features already in Talos. No new feature families: this release fixes defects found in a deep audit and makes the existing screens calmer and easier to use.

### Bug fixes

- **Custom commands.** Running a template no longer restarts the command forever when it finishes. A Cancel action is available while it runs, and dialog text controllers are disposed.
- **Queue order.** Downloads now start in the order shown in the Active tab, so drag-to-reorder has a real effect.
- **Clearing settings.** Video folder, audio folder, custom command folder and clip ranges can now be cleared and stay cleared.
- **Reset all data.** Reset now cancels active downloads, removes queued and failed tasks, and stops an in-flight download from writing a new history row.
- **Batch downloads.** Archive and clip-range settings now apply in batch mode, matching a single download.
- **Link feedback.** Tapping a link with no external handler now copies the URL and shows a message instead of doing nothing.
- **Dark theme labels.** Format-segment labels inherit the app theme again instead of rendering black.
- **Localization.** Removed hardcoded English strings from Format selection, Player, About and Settings, and corrected the Android FFmpeg error text.

### Improvements

- **Navigation emphasis.** The active tab now uses the accent color for its icon and label in both themes.
- **Finished tab layout.** Search has its own full-width row with the complete hint visible; Favorites, type filter and sort sit on a compact second row.
- **Theme picker.** The theme selector is full width so all three options fit on small screens.
- **Touch targets.** Accent swatches and the drag handle now have 48dp hit areas with accessible labels.
- **Consistent controls.** Buttons, dialogs, progress indicators and switches now share one theme. Crop artwork uses a full-row switch.
- **70 tests passing.** Added coverage for queue order and clearing settings.

### Download / Install

Download the file for your platform from Assets below. Android: `app-release.apk` (universal, for 64-bit Android devices). Windows: `Talos-v0.13.0-windows-x64.zip`. Linux: `Talos-v0.13.0-linux-x64.tar.gz`. A macOS build is not published yet; build from source instead. Requires Android 7.0 (API 24) or newer, Windows 10, or a recent GTK3 Linux build.

## v0.12.0

A control-focused update for the Finished library. Sort, filter and clean up finished downloads without leaving the tab.

### New features

- **Sort finished downloads.** Open the sort menu in the Finished tab to order entries by Newest, Oldest, Largest, Smallest or Title A-Z. Size sorting treats entries without a known size as zero.
- **Filter by media type.** The type menu switches the Finished list between All, Video and Audio. It combines with the Favorites chip and the search box.
- **Batch delete.** Long-press a finished entry to enter selection mode, tap more entries to add them, then use Select all or Delete selected. Deleting removes the files and their history rows after one confirmation.

### Improvements

- **68 tests passing.** Added coverage for every sort mode, batch history removal, corrupt history rows and malformed progress output.
- **Deep audit pass.** Fixed the anomalies found in engine setup, queue handling, settings and the Finished list.

### Bug fixes

- **Windows engine setup.** FFmpeg setup now reads the current checksum for the rolling latest build instead of a pinned hash that goes stale on each release, and Update Engine replaces the existing binary instead of failing on Windows.
- **History resilience.** One malformed saved row no longer discards the entire finished list on startup.
- **Batch downloads.** Batch mode now applies the configured proxy, cookies, quality and other transfer settings instead of silently dropping them.
- **Queue safety.** A failure to start the Android engine no longer deadlocks the queue, and cancelling an inactive task no longer kills the active download.
- **Progress parsing.** Malformed numbers in yt-dlp output no longer throw inside the progress listener.
- **Settings cleanup.** Removed a duplicated Subtitle language entry and disposed dialog text controllers.

### Download / Install

Download the file for your platform from Assets below. Android: `app-release.apk` (universal, for 64-bit Android devices). Windows: `Talos-v0.12.0-windows-x64.zip`. Linux: `Talos-v0.12.0-linux-x64.tar.gz`. A macOS build is not published yet; build from source instead. Requires Android 7.0 (API 24) or newer, Windows 10, or a recent GTK3 Linux build.

## v0.11.0

A fresh identity release led by the new Talos helmet mark, plus a small but useful upgrade to the Finished list.

### New features

- **New brand identity.** The project now uses a bronze helmet on a dark tile, replacing the previous eye-sigil. Logo, app icons, launch screens and README assets are all updated.
- **Favorite downloads.** In the Finished tab, every entry now has a star icon next to the menu. Tap it to mark or unmark favorites. A "Favorites" chip filters the list to only your starred entries.

### Improvements

- **Native file associations.** Android, iOS, macOS, Windows and Linux icons all render the new mark from the same source SVG data.

### Download / Install

Download the file for your platform from Assets below. Android: `app-release.apk` (universal, for 64-bit Android devices). Windows: `Talos-v0.11.0-windows-x64.zip`. Linux: `Talos-v0.11.0-linux-x64.tar.gz`. A macOS build is not published yet; build from source instead. Requires Android 7.0 (API 24) or newer, Windows 10, or a recent GTK3 Linux build.

## v0.10.0

This release makes Talos smarter about working with multiple links at once and recovering from stuck downloads.

### New features

- **Batch fetch.** Paste multiple links in the input field and tap Fetch all; Talos probes them one by one and enqueues them with your defaults. Choose Video 720p or Audio MP3 192k in the dialog. The input field label switches to "Fetch all" automatically.
- **Retry all failed tasks.** The Active tab now shows a "Retry all" button above the list when any task failed or was cancelled, so you can re-enqueue them in one tap.

### Improvements

- **Clipboard auto-fill handles multiple links.** When multiple URLs are in your clipboard, they are all pasted into the field, ready for batch fetch.
- **63 tests passing.**

### Download / Install

Download the file for your platform from Assets below. Android: `app-release.apk` (universal, for 64-bit Android devices). Windows: `Talos-v0.10.0-windows-x64.zip`. Linux: `Talos-v0.10.0-linux-x64.tar.gz`. A macOS build is not published yet; build from source instead. Requires Android 7.0 (API 24) or newer, Windows 10, or a recent GTK3 Linux build.

## v0.9.0

Reliability and power-user release: the download queue is now reorderable, merge failures surface as real errors, and a single tap wipes Talos data for a clean start.

### New features

- **Drag to reorder the Active queue.** Queued tasks can be moved up or down so the next download starts sooner.
- **Clipboard link detection.** When Talos opens and the link field is empty, a URL found in the clipboard is pasted automatically so you can fetch immediately.
- **Danger zone reset.** Settings > Danger zone > Reset all data wipes settings, finished downloads history, custom command templates and SAF folder shortcuts, leaving Talos in a clean state.

### Bug fixes

- **Android inline merge failures were reported as success.** The `[Merger] Merge failed` line is now parsed as an error, so a broken video+audio merge surfaces as a failed task with a readable message instead of a "completed" entry with an unusable file.

### Improvements

- **No deprecated APIs.** The Active list now uses the new `onReorderItem` callback.
- **63 tests passing.**

### Download / Install

Download the file for your platform from Assets below. Android: `app-release.apk` (universal, for 64-bit Android devices). Windows: `Talos-v0.9.0-windows-x64.zip`. Linux: `Talos-v0.9.0-linux-x64.tar.gz`. A macOS build is not published yet; build from source instead. Requires Android 7.0 (API 24) or newer, Windows 10, or a recent GTK3 Linux build.

## v0.8.0

Biggest feature release so far: Talos now plays your downloads inside the app, and the Finished tab is searchable with thumbnails.

### New features

- **Built-in player.** Finished downloads open in an in-app player: play/pause, a seek slider, a 10-second rewind button and a 30-second forward button. Works for both video and audio files. If a file cannot be played in-app, you can open it with the system player instead.
- **Search finished downloads.** The Finished tab has a search field that filters by video title, channel name or URL.
- **Thumbnails in Finished.** Entries recorded from now on show the video thumbnail.

### Bug fixes

- **Fresh installs could be flagged as "not responding" when the permission prompt appeared during cold start.** The prompt now waits until after the first frame renders, so the app never blocks input while the system dialog waits for your answer.
- **Finished entries with content URIs could not be opened.** Native Android handlers are used for content URIs, so opening and sharing works for files saved through MediaStore or a SAF folder.

### Improvements

- **History keeps the thumbnail** for new finished entries. Older entries keep the generic icon.

### Download / Install

Download the file for your platform from Assets below. Android: `app-release.apk` (universal, for 64-bit Android devices). Windows: `Talos-v0.8.0-windows-x64.zip`. Linux: `Talos-v0.8.0-linux-x64.tar.gz`. A macOS build is not published yet; build from source instead. Requires Android 7.0 (API 24) or newer, Windows 10, or a recent GTK3 Linux build.

## v0.7.0

Reliability release: downloads now land in your public Downloads/Talos folder by default, and the same video can be downloaded as many times as you like.

### New features

- **Public Downloads by default.** New downloads save to Downloads/Talos on your phone, visible to your file manager and to every media app. On Android 10 and newer, Talos writes there through MediaStore, so no storage permission is needed. On older Android, Talos asks once for legacy storage access on first launch.
- **Download the same video forever.** Talos no longer skips a download because the file already exists. Every repeat runs again and saves with a fresh suffix right after the title, for example `Big Buck Bunny(1).mkv` and `Big Buck Bunny(2).mkv`. The numbering is applied everywhere: the local name, inside a SAF folder, and inside the public Downloads folder. Nothing is ever overwritten.
- **Storage and notification prompt on first launch.** A fresh install asks right away for what it needs: notification access on Android 13 and newer, and legacy storage access on Android 9 and older.

### Bug fixes

- **Repeat downloads could silently finish with nothing new.** If the destination file already existed, yt-dlp skipped the download and the app still reported success. Talos now resolves a unique name before every download, so repeat downloads always produce a complete file.
- **Finished entries could not be opened or shared.** Files saved by earlier versions could end up with a private or unreachable path. Files now live in the public folder, and opening and sharing a finished entry uses the native Android handlers for content URIs instead of failing silently.
- **A SAF folder pick could overwrite a same-named file.** Talos now creates a unique `name(N).ext` instead of reusing the existing entry.
- **History entries recorded an unusable size.** Sizes are now measured before the file moves to its final folder.

### Improvements

- **Settings > Downloads is explicit.** The location tile now reads "Downloads (default)" with a full description, and a Change button picks a custom folder. Reset returns to the default at any time.
- **Verified end to end.** The fresh-install flow, unlimited repeat downloads and public-folder copies are covered by unit tests and verified on an emulator, including opening the finished file in the system player.

### Download / Install

Download the file for your platform from Assets below. Android: `app-release.apk` (universal, for 64-bit Android devices). Windows: `Talos-v0.7.0-windows-x64.zip`. Linux: `Talos-v0.7.0-linux-x64.tar.gz`. A macOS build is not published yet; build from source instead. Requires Android 7.0 (API 24) or newer, Windows 10, or a recent GTK3 Linux build.

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
