/// Data models exchanged between the UI and the download engine.
library;

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
  });

  final String title;
  final String webpageUrl;
  final bool isPlaylist;
  final String? uploader;
  final String? thumbnail;
  final Duration? duration;
  final List<PlaylistEntry> entries;
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
