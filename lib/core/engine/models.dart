/// Data models exchanged between the UI and the download engine.
library;

class YtdlpFormat {
  YtdlpFormat({
    required this.id,
    required this.note,
    required this.ext,
    this.resolution,
    this.filesize,
    this.vcodec,
    this.acodec,
    this.abr,
    this.vbr,
    this.height,
    this.fps,
  });

  final String id;
  final String note;
  final String ext;
  final String? resolution;
  final int? filesize;
  final String? vcodec;
  final String? acodec;
  final double? abr;
  final double? vbr;
  final int? height;
  final double? fps;
}

class PlaylistEntry {
  PlaylistEntry({
    required this.index,
    required this.id,
    required this.title,
    this.url,
    this.duration,
  });

  final int index;
  final String id;
  final String title;
  final String? url;
  final Duration? duration;
}

class MediaProbe {
  MediaProbe({
    required this.title,
    required this.webpageUrl,
    required this.isPlaylist,
    this.uploader,
    this.thumbnail,
    this.duration,
    this.entries = const [],
    this.formats = const [],
  });

  final String title;
  final String webpageUrl;
  final bool isPlaylist;
  final String? uploader;
  final String? thumbnail;
  final Duration? duration;
  final List<PlaylistEntry> entries;
  final List<YtdlpFormat> formats;
}

class DownloadRequest {
  DownloadRequest({
    required this.url,
    required this.videoMode,
    required this.outputDir,
    this.maxHeight,
    this.audioFormat = 'mp3',
    this.audioBitrate = '192',
    this.embedSubtitles = true,
    this.embedMetadata = true,
    this.filenameTemplate = '%(title)s.%(ext)s',
    this.proxy = '',
    this.rateLimit = '',
    this.useAria2 = false,
    this.concurrentFragments = 4,
    this.playlistItems,
    this.includePlaylist = true,
    this.ffmpegPath = '',
    this.sponsorBlockCategories = '',
    this.cookiesPath = '',
    this.subtitleLanguage = '',
    this.formatSelector = '',
    this.restrictFilenames = false,
    this.downloadArchive = '',
    this.cropArtwork = false,
    this.subtitleFormat = '',
    this.clipStartSeconds,
    this.clipEndSeconds,
    this.forceIpv4 = false,
    this.remuxContainer = '',
    this.maxFilesize = '',
    this.userAgent = '',
    this.formatSort = '',
    this.downloadSubtitles = true,
    this.autoSubtitle = false,
    this.keepSubtitles = false,
  });

  final String url;
  final bool videoMode;
  final String outputDir;

  /// Null or 0 means "best available".
  final int? maxHeight;
  final String audioFormat;
  final String audioBitrate;
  final bool embedSubtitles;
  final bool embedMetadata;
  final String filenameTemplate;
  final String proxy;
  final String rateLimit;
  final bool useAria2;
  final int concurrentFragments;

  /// yt-dlp --playlist-items style selection, for example "1-3,7".
  /// Null means "everything in the playlist".
  final String? playlistItems;
  final bool includePlaylist;

  /// Empty means "detect ffmpeg from PATH".
  final String ffmpegPath;

  /// Comma-separated SponsorBlock categories to strip, for example "sponsor,selfpromo". Empty disables.
  final String sponsorBlockCategories;

  /// Path to a Netscape-format cookies file. Empty disables.
  final String cookiesPath;

  /// Subtitle language code such as en or id. Empty means default.
  final String subtitleLanguage;

  /// A yt-dlp format selector such as `137+140` or `bestaudio`. Empty means default.
  final String formatSelector;

  /// Restrict filenames to ASCII and basic safety.
  final bool restrictFilenames;

  /// Uses a yt-dlp archive file to avoid re-downloading already-fetched items.
  final String downloadArchive;

  /// Crops square artwork for audio cover embed.
  final bool cropArtwork;

  /// Subtitle conversion target format code, for example `srt` or `ass`. Empty keeps source.
  final String subtitleFormat;

  /// Download only the section between two times, in seconds. Both null means the whole video.
  final int? clipStartSeconds;
  final int? clipEndSeconds;

  /// Force IPv4 instead of letting the OS pick.
  final bool forceIpv4;

  /// Remux output container, for example `mp4`, `mkv` or `webm`. Empty means no remux.
  final String remuxContainer;

  /// Maximum file size, for example `50M`. Empty or `0` disables.
  final String maxFilesize;

  /// Custom HTTP User-Agent. Empty means default.
  final String userAgent;

  /// yt-dlp format sort string, for example `ext,res`. Empty means default order.
  final String formatSort;

  /// Whether to download and embed subtitles.
  final bool downloadSubtitles;

  /// Also fetch auto-generated subtitles when no official sub exists.
  final bool autoSubtitle;

  /// Keep subtitle sidecar files on disk after embedding.
  final bool keepSubtitles;
}

enum TaskStatus { queued, running, completed, failed, cancelled }

class EngineProgress {
  EngineProgress({
    this.fraction,
    this.stage,
    this.downloadedBytes,
    this.totalBytes,
    this.speedBytesPerSecond,
    this.etaSeconds,
    this.outputPath,
    this.error,
    this.playlistIndex,
    this.playlistCount,
  });

  final double? fraction;
  final String? stage;
  final int? downloadedBytes;
  final int? totalBytes;
  final double? speedBytesPerSecond;
  final double? etaSeconds;
  final String? outputPath;
  final String? error;
  final int? playlistIndex;
  final int? playlistCount;
}

class EngineStatus {
  EngineStatus({
    required this.ready,
    required this.version,
    required this.ffmpegPath,
    required this.managed,
  });

  final bool ready;
  final String? version;
  final String? ffmpegPath;

  /// True when the app downloaded its own copy of yt-dlp.
  final bool managed;
}
