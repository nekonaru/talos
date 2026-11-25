import 'models.dart';

/// Builds yt-dlp argument lists. Pure Dart, no I/O, fully unit tested.
class CommandBuilder {
  const CommandBuilder._();

  static List<String> probeArgs(String url, {String? proxy}) {
    return [
      '--dump-single-json',
      '--flat-playlist',
      '--skip-download',
      '--no-warnings',
      if (proxy != null && proxy.isNotEmpty) ...['--proxy', proxy],
      '--',
      url,
    ];
  }

  static List<String> downloadArgs(
    DownloadRequest request, {
    required bool ffmpegAvailable,
  }) {
    final args = <String>['--newline', '--no-warnings'];

    if (request.includePlaylist) {
      args.add('--yes-playlist');
      if (request.playlistItems != null && request.playlistItems!.isNotEmpty) {
        args.addAll(['--playlist-items', request.playlistItems!]);
      }
    } else {
      args.add('--no-playlist');
    }

    if (request.videoMode) {
      final height = request.maxHeight;
      if (request.formatSelector.isNotEmpty) {
        args.addAll(['-f', request.formatSelector]);
      } else if (ffmpegAvailable) {
        if (height != null && height > 0) {
          args.addAll(['-f', 'bv*[height<=$height]+ba/b[height<=$height]/b']);
        } else {
          args.addAll(['-f', 'bv*+ba/b']);
        }
      } else {
        // Embedded Android has no ffmpeg binary on PATH; streams are merged
        // by the bundled FFmpegKit after download instead.
        if (height != null && height > 0) {
          args.addAll(['-f', 'bv*[height<=$height]+ba/b[height<=$height]/b']);
        } else {
          args.addAll(['-f', 'bv*+ba/b']);
        }
      }
      if (request.downloadSubtitles) {
        args.addAll(['--write-subs']);
        if (ffmpegAvailable && request.embedSubtitles) args.add('--embed-subs');
        if (request.autoSubtitle) args.add('--write-auto-subs');
        if (request.keepSubtitles) args.add('--keep-subs');
        if (request.subtitleLanguage.isNotEmpty) {
          args.addAll(['--sub-langs', request.subtitleLanguage]);
        }
        // Subtitle conversion needs ffmpeg, which is not spawnable on mobile.
        if (ffmpegAvailable && request.subtitleFormat.isNotEmpty) {
          args.addAll(['--convert-subs', request.subtitleFormat]);
        }
      }
    } else {
      if (request.formatSelector.isNotEmpty) {
        args.addAll(['-f', request.formatSelector]);
      } else if (ffmpegAvailable) {
        args.addAll(['-x', '--audio-format', request.audioFormat]);
        if (request.audioBitrate.isNotEmpty) {
          args.addAll(['--audio-quality', '${request.audioBitrate}K']);
        }
      } else {
        // Audio conversion needs ffmpeg; grab the best audio stream as-is.
        args.addAll(['-f', 'ba/bestaudio/b']);
      }
    }

    if (request.embedMetadata && ffmpegAvailable) {
      args.addAll(['--embed-metadata', '--embed-thumbnail']);
      if (request.cropArtwork) {
        args.addAll(['--ppa', "FFmpeg:-c:v mjpeg -vf crop='min(ih,iw)':'min(ih,iw)'"]);
      }
    }

    if (request.maxFilesize.isNotEmpty && request.maxFilesize != '0') {
      args.addAll(['--max-filesize', request.maxFilesize]);
    }
    if (request.userAgent.isNotEmpty) {
      args.addAll(['--user-agent', request.userAgent]);
    }
    if (request.formatSort.isNotEmpty) {
      args.addAll(['-S', request.formatSort]);
    }
    if (request.restrictFilenames) args.add('--restrict-filenames');
    if (request.downloadArchive.isNotEmpty) args.addAll(['--download-archive', request.downloadArchive]);
    if (request.forceIpv4) args.add('-4');
    if (request.remuxContainer.isNotEmpty) args.addAll(['--remux-video', request.remuxContainer]);
    // yt-dlp requires the "*start-end" form. Missing bounds use 0 and inf so
    // a single-sided clip never produces an invalid selector. Needs ffmpeg.
    if (ffmpegAvailable && (request.clipStartSeconds != null || request.clipEndSeconds != null)) {
      final start = request.clipStartSeconds ?? 0;
      final end = request.clipEndSeconds;
      final section = end == null ? '*$start-inf' : '*$start-$end';
      args.addAll(['--download-sections', section]);
    }

    if (request.proxy.isNotEmpty) args.addAll(['--proxy', request.proxy]);
    if (request.rateLimit.isNotEmpty) args.addAll(['--limit-rate', request.rateLimit]);
    if (request.cookiesPath.isNotEmpty) args.addAll(['--cookies', request.cookiesPath]);
    // SponsorBlock chapter removal re-encodes with ffmpeg on some outputs.
    if (ffmpegAvailable && request.sponsorBlockCategories.isNotEmpty) {
      args.addAll(['--sponsorblock-remove', request.sponsorBlockCategories]);
    }
    if (request.concurrentFragments > 1) {
      args.addAll(['-N', '${request.concurrentFragments}']);
    }
    if (request.useAria2) args.addAll(['--downloader', 'aria2c']);

    args.addAll(['-P', request.outputDir]);
    final custom = request.outputFilename?.trim();
    args.addAll(['-o', custom != null && custom.isNotEmpty ? custom : request.filenameTemplate]);
    // Force the rest to be parsed as URLs, never as options. A saved or shared
    // link beginning with a dash must not inject yt-dlp flags.
    args.add('--');
    args.add(request.url);
    return args;
  }

  /// Splits a user command template into arguments, honoring single and
  /// double quotes. Backslash escapes the next character.
  static List<String> tokenizeArgs(String input) {
    final tokens = <String>[];
    final current = StringBuffer();
    String? quote;
    var hasContent = false;

    for (var i = 0; i < input.length; i++) {
      final ch = input[i];
      if (ch == '\\' && i + 1 < input.length) {
        final next = input[i + 1];
        // Only quote and whitespace characters need escaping. A backslash in a
        // Windows path such as C:\Users\me must stay literal, otherwise custom
        // commands silently lose their cookie or config file path.
        final needsEscape = quote != "'" &&
            (next == '"' || next == "'" || next == '\\' || next.trim().isEmpty);
        if (needsEscape) {
          current.write(next);
          hasContent = true;
          i++;
          continue;
        }
      }
      if (quote != null) {
        if (ch == quote) {
          quote = null;
        } else {
          current.write(ch);
        }
        continue;
      }
      if (ch == '"' || ch == "'") {
        quote = ch;
        hasContent = true;
        continue;
      }
      if (ch.trim().isEmpty) {
        if (hasContent || current.isNotEmpty) {
          tokens.add(current.toString());
          current.clear();
          hasContent = false;
        }
        continue;
      }
      current.write(ch);
      hasContent = true;
    }
    if (hasContent || current.isNotEmpty) tokens.add(current.toString());
    return tokens;
  }

  /// Substitutes the {url} token in a command template and tokenizes.
  /// Substitution happens inside each token, so URLs containing spaces
  /// never split into multiple arguments.
  static List<String> customCommandArgs(String template, String url) {
    return tokenizeArgs(template)
        .map((token) => token.replaceAll('{url}', url))
        .toList();
  }
}
