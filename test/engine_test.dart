import 'package:flutter_test/flutter_test.dart';
import 'package:talos/core/engine/command_builder.dart';
import 'package:talos/core/engine/desktop_engine.dart';
import 'package:talos/core/engine/models.dart';
import 'package:talos/core/engine/progress_parser.dart';

void main() {
  group('parseYtdlpLine', () {
    test('parses a download progress line', () {
      final event = parseYtdlpLine(
        '[download]   4.2% of   12.34MiB at    1.20MiB/s ETA 00:12',
      );
      expect(event, isNotNull);
      expect(event!.stage, 'download');
      expect(event.fraction, closeTo(0.042, 1e-6));
      expect(event.totalBytes, (12.34 * 1024 * 1024).round());
      expect(event.speedBytesPerSecond, closeTo(1.20 * 1024 * 1024, 1e3));
      expect(event.etaSeconds, 12);
    });

    test('parses hours in ETA', () {
      final event = parseYtdlpLine(
        '[download]  10.0% of 100MiB at 512KiB/s ETA 01:00:00',
      );
      expect(event!.etaSeconds, 3600);
    });

    test('parses destination line', () {
      final event = parseYtdlpLine('[download] Destination: /tmp/file.mp4');
      expect(event!.stage, 'download');
      expect(event.outputPath, '/tmp/file.mp4');
    });

    test('parses extract audio destination', () {
      final event = parseYtdlpLine('[ExtractAudio] Destination: track.mp3');
      expect(event!.stage, 'extractAudio');
      expect(event.outputPath, 'track.mp3');
    });

    test('parses merger line', () {
      final event = parseYtdlpLine('[Merger] Merging formats into "video.mkv"');
      expect(event!.stage, 'merge');
      expect(event.outputPath, 'video.mkv');
    });

    test('parses playlist progress', () {
      final event = parseYtdlpLine('[download] Downloading item 3 of 10');
      expect(event!.stage, 'playlist');
      expect(event.playlistIndex, 3);
      expect(event.playlistCount, 10);
    });

    test('captures errors', () {
      final event = parseYtdlpLine('ERROR: Video unavailable');
      expect(event!.error, 'Video unavailable');
    });

    test('ignores noise', () {
      expect(parseYtdlpLine('[info] abc: Downloading webpage'), isNull);
      expect(parseYtdlpLine(''), isNull);
    });
  });

  group('parseProbeJson', () {
    test('parses a single video', () {
      final probe = parseProbeJson('''
{
  "id": "abc123",
  "title": "Test video",
  "webpage_url": "https://example.invalid/watch?v=abc123",
  "uploader": "someone",
  "duration": 125.4,
  "thumbnail": "https://example.invalid/thumb.jpg"
}
''');
      expect(probe.title, 'Test video');
      expect(probe.isPlaylist, isFalse);
      expect(probe.uploader, 'someone');
      expect(probe.duration, const Duration(seconds: 125));
      expect(probe.thumbnail, 'https://example.invalid/thumb.jpg');
    });

    test('parses a playlist with entries', () {
      final probe = parseProbeJson('''
{
  "_type": "playlist",
  "title": "My list",
  "entries": [
    {"id": "1", "title": "First", "url": "https://example.invalid/1", "duration": 60},
    {"id": "2", "title": "Second", "url": "https://example.invalid/2"}
  ]
}
''');
      expect(probe.isPlaylist, isTrue);
      expect(probe.entries, hasLength(2));
      expect(probe.entries.first.title, 'First');
      expect(probe.entries.first.duration, const Duration(seconds: 60));
      expect(probe.entries[1].duration, isNull);
    });

    test('rejects garbage', () {
      expect(() => parseProbeJson('not json'), throwsFormatException);
      expect(() => parseProbeJson('[]'), throwsFormatException);
    });
  });

  group('downloadArgs', () {
    DownloadRequest request({bool video = true, int? maxHeight, String? items}) => DownloadRequest(
          url: 'https://example.invalid/watch?v=x',
          videoMode: video,
          outputDir: '/downloads',
          maxHeight: maxHeight,
          playlistItems: items,
        );

    test('video with height cap', () {
      final args = CommandBuilder.downloadArgs(request(maxHeight: 720), ffmpegAvailable: true);
      expect(args, containsAllInOrder(['-f', 'bv*[height<=720]+ba/b[height<=720]/b']));
      expect(args, contains('--write-subs'));
      expect(args.last, 'https://example.invalid/watch?v=x');
    });

    test('audio mode', () {
      final args = CommandBuilder.downloadArgs(request(video: false), ffmpegAvailable: true);
      expect(args, containsAllInOrder(['-x', '--audio-format', 'mp3']));
      expect(args, contains('--embed-thumbnail'));
    });

    test('subtitles without ffmpeg still write, no embed', () {
      final args = CommandBuilder.downloadArgs(request(maxHeight: 1080), ffmpegAvailable: false);
      expect(args, contains('--write-subs'));
      expect(args, isNot(contains('--embed-subs')));
      expect(args, containsAllInOrder(['-f', 'bv*[height<=1080]+ba/b[height<=1080]/b']));
    });

    test('audio without ffmpeg keeps original stream', () {
      final args = CommandBuilder.downloadArgs(request(video: false), ffmpegAvailable: false);
      expect(args, isNot(contains('-x')));
      expect(args, isNot(contains('--embed-metadata')));
      expect(args, containsAllInOrder(['-f', 'ba/bestaudio/b']));
    });

    test('embedded video mode picks DASH streams for in-app merge', () {
      final args = CommandBuilder.downloadArgs(request(maxHeight: 720), ffmpegAvailable: false);
      expect(args, isNot(contains('--extractor-args')));
      expect(args, containsAllInOrder(['-f', 'bv*[height<=720]+ba/b[height<=720]/b']));
    });

    test('embedded audio mode keeps the default client', () {
      final args = CommandBuilder.downloadArgs(request(video: false), ffmpegAvailable: false);
      expect(args, isNot(contains('--extractor-args')));
    });

    test('ffmpeg video mode keeps the default client', () {
      final args = CommandBuilder.downloadArgs(request(maxHeight: 720), ffmpegAvailable: true);
      expect(args, isNot(contains('--extractor-args')));
    });

    test('playlist selection', () {
      final args = CommandBuilder.downloadArgs(request(items: '1-3,7'), ffmpegAvailable: false);
      expect(args, containsAllInOrder(['--playlist-items', '1-3,7']));
    });

    test('subtitles carry the configured language', () {
      final args = CommandBuilder.downloadArgs(
        DownloadRequest(
          url: 'https://example.invalid/watch?v=x',
          videoMode: true,
          outputDir: '/downloads',
          subtitleLanguage: 'id',
        ),
        ffmpegAvailable: true,
      );
      expect(args, allOf(contains('--write-subs'), containsAllInOrder(['--sub-langs', 'id'])));
    });

    test('sponsorblock and cookies are passed through', () {
      final args = CommandBuilder.downloadArgs(
        DownloadRequest(
          url: 'https://example.invalid/watch?v=x',
          videoMode: false,
          outputDir: '/downloads',
          sponsorBlockCategories: 'sponsor,selfpromo',
          cookiesPath: '/tmp/cookies.txt',
        ),
        ffmpegAvailable: true,
      );
      expect(args, containsAllInOrder(['--sponsorblock-remove', 'sponsor,selfpromo']));
      expect(args, containsAllInOrder(['--cookies', '/tmp/cookies.txt']));
    });

    test('new flags are emitted when set', () {
      final args = CommandBuilder.downloadArgs(
        DownloadRequest(
          url: 'https://example.invalid/watch?v=x',
          videoMode: true,
          outputDir: '/downloads',
          formatSelector: '137+140',
          restrictFilenames: true,
          downloadArchive: '/tmp/archive.txt',
          cropArtwork: true,
          subtitleFormat: 'ass',
          clipStartSeconds: 10,
          clipEndSeconds: 20,
          forceIpv4: true,
          remuxContainer: 'mp4',
        ),
        ffmpegAvailable: true,
      );
      expect(args, allOf([
        containsAllInOrder(['-f', '137+140']),
        contains('--restrict-filenames'),
        containsAllInOrder(['--download-archive', '/tmp/archive.txt']),
        containsAllInOrder(['--ppa', "FFmpeg:-c:v mjpeg -vf crop='min(ih,iw)':'min(ih,iw)'"]),
        containsAllInOrder(['--convert-subs', 'ass']),
        containsAllInOrder(['--download-sections', '*10-20']),
        contains('-4'),
        containsAllInOrder(['--remux-video', 'mp4']),
      ]));
    });
  });

  group('expectedHashFor', () {
    const sample = '''
e51e69e89489f199530f13d32a4342da3ddb2cf34842f364603a066db05afbf3  yt-dlp
f5389d3698ecde4ef06f4e6b1ce0294fe9ac1396228c8990b8d3416d6d177a7d  yt-dlp.exe
0f922c15ccc0b83eefa1c8bc9104e434318c4bf16e408e1ee93b7745a6efe0aa  yt-dlp_macos
''';

    test('finds the right hash per asset', () {
      expect(DesktopEngine.expectedHashFor(sample, 'yt-dlp'), 'e51e69e89489f199530f13d32a4342da3ddb2cf34842f364603a066db05afbf3');
      expect(DesktopEngine.expectedHashFor(sample, 'yt-dlp.exe'), 'f5389d3698ecde4ef06f4e6b1ce0294fe9ac1396228c8990b8d3416d6d177a7d');
      expect(DesktopEngine.expectedHashFor(sample, 'yt-dlp_macos'), '0f922c15ccc0b83eefa1c8bc9104e434318c4bf16e408e1ee93b7745a6efe0aa');
    });

    test('returns null for unknown assets', () {
      expect(DesktopEngine.expectedHashFor(sample, 'nope'), isNull);
    });
  });

  group('tokenizeArgs', () {
    test('splits plain arguments', () {
      expect(CommandBuilder.tokenizeArgs('-x --audio-format mp3 {url}'),
          ['-x', '--audio-format', 'mp3', '{url}']);
    });

    test('respects quotes', () {
      expect(CommandBuilder.tokenizeArgs('-f "bv*[height<=720]+ba/b[height<=720]" {url}'),
          ['-f', 'bv*[height<=720]+ba/b[height<=720]', '{url}']);
    });

    test('single quotes and escapes', () {
      expect(CommandBuilder.tokenizeArgs("--proxy 'a b' -N 4"), ['--proxy', 'a b', '-N', '4']);
      expect(CommandBuilder.tokenizeArgs('a\\ b'), ['a b']);
    });

    test('url substitution', () {
      final args = CommandBuilder.customCommandArgs('-x {url} --no-mtime', 'https://example.invalid/a b');
      expect(args.first, '-x');
      expect(args[1], 'https://example.invalid/a b');
      expect(args.last, '--no-mtime');
    });
  });
}
