<div align="center">
  <img src="assets/talos-mark.svg" alt="Talos logo" width="120" />
  <h1>Talos: Video and Audio Downloader</h1>
  <p><b>Download videos and audio from the web, with playlists, subtitles,<br/>
  embedded metadata and a name worth guarding.</b></p>

  <a href="https://github.com/nekonaru/talos/releases"><img src="https://img.shields.io/github/v/release/nekonaru/talos?style=flat-square&color=blue" alt="Release" /></a>
  <a href="https://github.com/nekonaru/talos/actions/workflows/ci.yml"><img src="https://github.com/nekonaru/talos/actions/workflows/ci.yml/badge.svg" alt="CI" /></a>
  <img src="https://img.shields.io/badge/Flutter-3.47-02569B?style=flat-square&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Desktop-3DDC84?style=flat-square&logo=android&logoColor=white" alt="Platform" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="License" />
  <img src="https://img.shields.io/badge/Status-Active-brightgreen?style=flat-square" alt="Status" />
</div>

<br />

**English** | [Bahasa Indonesia](README.id.md)

> [!NOTE]
> On Android, downloaded files are stored in the app's private storage, and you open them with the share action. On desktop, files go to your downloads folder by default.

---

## Table of Contents

- [About](#about)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Display Language](#display-language)
- [Data Sources](#data-sources)
- [Project Structure](#project-structure)
- [Development](#development)
- [Testing](#testing)
- [Continuous Integration](#continuous-integration)
- [FAQ](#faq)
- [Author](#author)
- [Disclaimer](#disclaimer)
- [License](#license)

---

## About

**Talos** is a free, open-source video and audio downloader for Android, iOS, Windows, macOS and Linux. Point it at a link from a supported site, pick a format, and Talos fetches and saves the file locally. The download engine is yt-dlp, running in-process on Android through Chaquopy and as a managed or system binary on desktop.

> _"A bronze sentinel for the videos and songs you want to keep."_

---

## Features

### Downloads

| Feature | Description |
|---------|-------------|
| **Video and audio** | Download from thousands of sites supported by yt-dlp, as video or audio |
| **Format selection** | Video up to 2160p, or audio as MP3, M4A, Opus, FLAC, or the source format |
| **Progress view** | Percent, speed, ETA, and playlist position, with cancel and retry |
| **Sequential queue** | One download at a time, so sites are not hammered with parallel requests |
| **Cancel and retry** | Cancel any task, retry failed or cancelled ones with the same options |

### Playlists

| Feature | Description |
|---------|-------------|
| **Full playlist support** | Fetch a playlist URL, see every entry with durations, pick all or a subset |
| **Per-item progress** | See which playlist item is downloading and how many remain |

### File Output

| Feature | Description |
|---------|-------------|
| **Metadata embedding** | Embed title, artist, album art and other metadata into audio and video files |
| **Audio thumbnails** | Embed the cover art into audio files (desktop with FFmpeg) |
| **Subtitle embedding** | Embed subtitles into video files, with a selectable language |
| **Filename template** | Control output names with yt-dlp output templates |

### Network and Filters

| Feature | Description |
|---------|-------------|
| **Proxy support** | Route downloads through an HTTP or SOCKS proxy |
| **Rate limiting** | Cap download speed, for example 5M or 512K |
| **Concurrent fragments** | Speed up fragmented downloads with parallel fragments |
| **aria2c** | Use aria2c as the external downloader on desktop when it is installed |
| **SponsorBlock** | Remove sponsor, self-promo and other segments from videos by category |
| **Cookies file** | Download from sites that require a login with a cookies.txt file |

### Android

| Feature | Description |
|---------|-------------|
| **Embedded engine** | yt-dlp runs in-process through Chaquopy, no external tools required |
| **Foreground service** | Downloads continue while the app is in the background |
| **Share to Talos** | Share a link from any app straight into Talos |
| **Private storage** | Files stay inside the app; share them out with any file manager or app |

### Desktop

| Feature | Description |
|---------|-------------|
| **Managed engine** | yt-dlp is downloaded once into the app and kept up to date automatically |
| **System engine** | Or use yt-dlp from your PATH if one is installed |
| **FFmpeg detection** | Automatically finds FFmpeg on your PATH, or set a custom path |
| **Auto updates** | Check and update the managed yt-dlp from Settings |

### Appearance and Language

| Feature | Description |
|---------|-------------|
| **Warm dark design** | A warm dark theme with a bronze accent, plus light and system modes |
| **Accent colors** | Five accent hues: bronze, laurel, aegean, oxblood, marble |
| **Bilingual UI** | English (default) and Bahasa Indonesia |

### Other

| Feature | Description |
|---------|-------------|
| **Custom commands** | Run yt-dlp with your own argument templates, manage them in the app |
| **History** | A searchable list of finished downloads with file path, size and date |
| **Private mode** | Optionally skip history entirely |

---

## Requirements

| Dependency | Minimum Version | Notes |
|------------|-----------------|-------|
| **Flutter** | 3.47 (Dart 3.13) | Required only to build from source |
| **JDK** | 17 | Required only to build from source |
| **Android SDK** | API 24 | Required only to build from source |
| **Android device or emulator** | Android 7.0 (API 24) | Required to run on Android |
| **FFmpeg** | Any recent build | Desktop only, required for metadata, thumbnail and subtitle embedding |
| **aria2c** | Any recent build | Desktop only, optional external downloader |

> [!TIP]
> If you only want to use the app, you do not need Flutter, the JDK or the Android SDK. Download the APK from the [Releases](https://github.com/nekonaru/talos/releases) page instead.

### Never used a terminal? Start here

<details>
<summary><b>How to open a terminal on Windows</b></summary>

1. Press the **Windows** key, type `PowerShell`, then press **Enter**
2. A blue window opens. That is where you type commands
3. Every `flutter ...` or `git ...` command in this guide is typed in that window, followed by **Enter**

</details>

---

## Installation

### Option A: Download a prebuilt release (easiest)

1. Open the [Releases](https://github.com/nekonaru/talos/releases) page
2. Download the file for your platform:
   - Android: `app-release.apk` (universal, for 64-bit Android devices)
   - Windows: `Talos-v0.7.0-windows-x64.zip`
   - Linux: `Talos-v0.7.0-linux-x64.tar.gz`
3. Android only: open the APK, allow installs from unknown sources if asked, grant notification permission

> [!NOTE]
> The Android engine bundles a Python 3.14 runtime, which requires a 64-bit ARM64 Android device and Android 7.0 or newer. A macOS build is not published yet; build it from source instead (Option B).

> [!IMPORTANT]
> Notification permission is required for the foreground download service on Android 13 and newer. Without it, downloads still run but the system hides the download notification.

### Option B: Build from source (for development / to read or change the code)

#### 1. Get the project code

<details>
<summary><b>I have Git installed</b></summary>

```bash
git clone https://github.com/nekonaru/talos.git
cd talos
```

</details>

<details>
<summary><b>I don't have Git</b></summary>

1. Open the repository page on GitHub
2. Click the green **`Code`** button, choose **`Download ZIP`**
3. Extract the ZIP to a folder of your choice
4. In the terminal, go into the extracted folder, for example:

```bash
cd Downloads/talos-main
```

</details>

#### 2. Install dependencies and verify

```bash
flutter pub get
flutter gen-l10n
flutter analyze
```

> [!IMPORTANT]
> `flutter analyze` must report **No issues found**.

#### 3. Build

```bash
# Android
flutter build apk --release

# Windows
flutter build windows --release

# Linux
flutter build linux --release

# macOS
flutter build macos --release
```

---

## Usage

### First launch

1. Open the app. The Home tab asks for a link
2. Paste a video or playlist URL and press **Fetch**
3. On the configure screen, pick video or audio, a quality, and press **Download**
4. Watch progress on the **Downloads** tab

> [!NOTE]
> Talos downloads files. It does not stream them. Legal use is your responsibility.

### Everyday use

- Watch progress on the **Downloads** tab, cancel or retry tasks there
- Browse finished downloads on the **Downloads** tab, Finished section
- Open a file with its context menu: **Open**, **Show in folder**, **Share**, **Remove**, or **Delete file**
- Manage downloads and options in **Settings**
- Run your own yt-dlp commands from **Settings > Custom commands**

---

## Display Language

The app UI is available in **English** (default) and **Bahasa Indonesia**.

1. Open **Settings**
2. Scroll to the appearance section
3. The UI language follows your system locale; change the system language to switch

---

## Data Sources

Talos only goes online to fetch the media you ask for and to send anonymous requests when you set them up. The sources it uses are:

| Purpose | Source |
|---------|--------|
| Site and format support | yt-dlp supported sites |
| SponsorBlock segments | SponsorBlock API, when you enable it in Settings |
| Metadata and thumbnails | The site you are downloading from |
| Cookies | Your own cookies.txt file, if configured |

> [!NOTE]
> Talos does not upload your downloads or data anywhere. Downloads go directly from the source site to your device.

---

## Project Structure

```
talos/
├── lib/
│   ├── main.dart                 # entry point, creates the download manager
│   ├── app.dart                  # MaterialApp, themes, locales
│   ├── app_scope.dart            # InheritedNotifier for shared state
│   ├── core/                     # engine, stores, queue, services
│   │   ├── engine/               # engine interface, desktop and Android (Chaquopy)
│   │   ├── download_manager.dart # sequential queue with cancel/retry
│   │   ├── settings_store.dart   # settings persisted as JSON
│   │   ├── history_store.dart    # finished downloads log
│   │   ├── command_template_store.dart
│   │   └── theme.dart            # palette, accent hues, typography
│   ├── screens/                  # home, configure, downloads, settings, commands, about
│   ├── l10n/                     # app_en.arb (English), app_id.arb (Indonesian)
│   └── gen/                      # generated localizations (do not edit by hand)
├── android/                      # Android build (Chaquopy, foreground service)
├── ios/, windows/, macos/, linux/# other platforms (Windows needs Visual Studio)
├── assets/                       # logo masters
├── test/                         # unit and widget tests
├── l10n.yaml                     # localization config
├── BRAND.md                      # brand guidelines
├── LICENSE                       # MIT License
├── README.md                     # documentation (English)
└── README.id.md                  # documentation (Bahasa Indonesia)
```

---

## Development

### Adding a new user-facing string

1. Add the key to `lib/l10n/app_en.arb` (English) and `lib/l10n/app_id.arb` (Bahasa Indonesia)
2. Run `flutter gen-l10n`
3. Use it via `AppLocalizations.of(context)!.yourKey`

> [!WARNING]
> Files inside `lib/gen/` are generated. Do not edit them by hand. Change the `.arb` files and run `flutter gen-l10n` instead.

### Adding a new screen

1. Create the screen in `lib/screens/`
2. Add it to `lib/screens/shell.dart` if it belongs in the navigation
3. Add the needed strings to both `.arb` files and run `flutter gen-l10n`

---

## Testing

Verification before every push, all must be clean:

```bash
flutter gen-l10n
flutter analyze
flutter test
```

| Check | Requirement |
|-------|-------------|
| `flutter gen-l10n` | Must run without errors |
| `flutter analyze` | Must report **No issues found** (zero errors, zero warnings) |
| `flutter test` | Must pass the full suite (unit and widget tests) |

Lints are enforced through `analysis_options.yaml` (flutter_lints).

---

## Continuous Integration

| Workflow | Purpose |
|----------|---------|
| `ci.yml` | Analyze, test and build on every push and pull request |

---

## FAQ

<details>
<summary><b>Downloads are stuck at 0%?</b></summary>

Pick a smaller or more common quality first. Some sites throttle or block requests without cookies. Enable a cookies.txt file in Settings if the site requires a login.

</details>

<details>
<summary><b>Open does nothing with the file?</b></summary>

On Android, Talos stores files in its private storage and the system cannot preview them directly. Use **Share** to open the file with another app.

</details>

<details>
<summary><b>Video and audio merger or subtitles do not work?</b></summary>

Install FFmpeg (or set its path in Settings) on desktop. Android uses single-file formats because FFmpeg is not bundled yet.

</details>

<details>
<summary><b>How do I change the language?</b></summary>

The UI follows the system language. Change the system language to switch between English and Bahasa Indonesia.

</details>

<details>
<summary><b>Why is the APK big?</b></summary>

The Android APK embeds a Python runtime and yt-dlp, which is the honest cost of an engine that works without external tools.

</details>

---

## Author

<div align="center">

| [![Nicolas Dwi Dharma](https://github.com/nekonaru.png?size=100)](https://github.com/nekonaru) |
|:---:|
| **Nicolas Dwi Dharma** |
| [github.com/nekonaru](https://github.com/nekonaru) |

</div>

---

## Disclaimer

Talos is an independent open-source project and is not affiliated with yt-dlp, FFmpeg, Chaquopy, SponsorBlock, or any website you download from. You are responsible for complying with the terms of the sites you use and with the laws that apply to you. Talos does not host, index or distribute any content.

---

## License

Distributed under the **MIT License**. See [`LICENSE`](LICENSE) for more information.
