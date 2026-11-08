import 'dart:convert';

import 'models.dart';

final RegExp _percent = RegExp(r'(\d{1,3}(?:\.\d+)?)%');
final RegExp _speed = RegExp(r'at\s+([\d.]+)\s*([KMGT]?i?B)/s');
final RegExp _eta = RegExp(r'ETA\s+(\d{1,2}:\d{2}(?::\d{2})?)');
final RegExp _destination = RegExp(r'Destination:\s*(.+)$', caseSensitive: false);
final RegExp _merging = RegExp(r'Merging formats into\s+"(.+)"');
final RegExp _playlistItem = RegExp(r'Downloading (?:item|video)\s+(\d+)\s+of\s+(\d+)', caseSensitive: false);
final RegExp _totalSize = RegExp(r'of\s+(?:~\s*)?([\d.]+)\s*([KMGT]?i?B)');

int _unitToBytes(String unit) {
  switch (unit.toUpperCase()) {
    case 'B':
      return 1;
    case 'KB':
      return 1000;
    case 'KIB':
      return 1024;
    case 'MB':
      return 1000 * 1000;
    case 'MIB':
      return 1024 * 1024;
    case 'GB':
      return 1000 * 1000 * 1000;
    case 'GIB':
      return 1024 * 1024 * 1024;
    default:
      return 1024;
  }
}

double? _parseEta(String raw) {
  final parts = raw.split(':').map((p) => int.tryParse(p) ?? 0).toList();
  if (parts.length == 2) return parts[0] * 60 + parts[1].toDouble();
  if (parts.length == 3) return parts[0] * 3600 + parts[1] * 60 + parts[2].toDouble();
  return null;
}

/// Parses one line of yt-dlp stdout into an [EngineProgress] event.
/// Returns null when the line carries no usable signal.
EngineProgress? parseYtdlpLine(String line) {
  final trimmed = line.trim();
  if (trimmed.isEmpty) return null;

  if (trimmed.startsWith('ERROR')) {
    return EngineProgress(error: trimmed.replaceFirst(RegExp(r'^ERROR:\s*'), ''));
  }

  final playlist = _playlistItem.firstMatch(trimmed);
  if (playlist != null) {
    return EngineProgress(
      stage: 'playlist',
      playlistIndex: int.tryParse(playlist.group(1)!),
      playlistCount: int.tryParse(playlist.group(2)!),
    );
  }

  final destination = _destination.firstMatch(trimmed);
  if (destination != null) {
    return EngineProgress(
      stage: trimmed.contains('[ExtractAudio]')
          ? 'extractAudio'
          : trimmed.contains('[Merger]') || trimmed.contains('[ffmpeg]')
              ? 'merge'
              : 'download',
      outputPath: destination.group(1)!.trim(),
    );
  }

  final merging = _merging.firstMatch(trimmed);
  if (merging != null) {
    return EngineProgress(stage: 'merge', outputPath: merging.group(1));
  }

  if (trimmed.contains('[download]') && trimmed.contains('%')) {
    final percent = _percent.firstMatch(trimmed);
    final size = _totalSize.firstMatch(trimmed);
    final speed = _speed.firstMatch(trimmed);
    final eta = _eta.firstMatch(trimmed);
    int? totalBytes;
    if (size != null) {
      totalBytes = (double.tryParse(size.group(1)!)! * _unitToBytes(size.group(2)!)).round();
    }
    final fraction = percent != null ? double.tryParse(percent.group(1)!)! / 100.0 : null;
    double? speedBytes;
    if (speed != null) {
      speedBytes = double.tryParse(speed.group(1)!)! * _unitToBytes(speed.group(2)!);
    }
    return EngineProgress(
      stage: 'download',
      fraction: fraction,
      totalBytes: totalBytes,
      downloadedBytes: (fraction != null && totalBytes != null) ? (fraction * totalBytes).round() : null,
      speedBytesPerSecond: speedBytes,
      etaSeconds: eta != null ? _parseEta(eta.group(1)!) : null,
    );
  }

  if (trimmed.contains('[download]') && trimmed.toLowerCase().contains('destination')) {
    return EngineProgress(stage: 'download');
  }

  return null;
}

/// Parses yt-dlp's `--dump-single-json` output into a [MediaProbe].
/// Throws [FormatException] when the payload is not usable.
MediaProbe parseProbeJson(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('yt-dlp returned a non-object payload');
  }

  final isPlaylist = decoded['_type'] == 'playlist' || decoded['entries'] is List;

  final entries = <PlaylistEntry>[];
  final rawEntries = decoded['entries'];
  if (rawEntries is List) {
    for (var i = 0; i < rawEntries.length; i++) {
      final e = rawEntries[i];
      if (e is! Map<String, dynamic>) continue;
      final duration = e['duration'];
      entries.add(PlaylistEntry(
        index: i + 1,
        id: (e['id'] ?? e['url'] ?? '${i + 1}').toString(),
        title: (e['title'] ?? 'Untitled').toString(),
        url: e['url']?.toString() ?? e['webpage_url']?.toString(),
        duration: duration is num ? Duration(seconds: duration.round()) : null,
      ));
    }
  }

  final duration = decoded['duration'];
  final thumb = decoded['thumbnail'];
  final thumbnails = decoded['thumbnails'];
  String? thumbnail = thumb is String ? thumb : null;
  if (thumbnail == null && thumbnails is List && thumbnails.isNotEmpty) {
    final last = thumbnails.last;
    if (last is Map<String, dynamic> && last['url'] is String) {
      thumbnail = last['url'] as String;
    }
  }

  return MediaProbe(
    title: (decoded['title'] ?? decoded['playlist'] ?? 'Untitled').toString(),
    webpageUrl: (decoded['webpage_url'] ?? decoded['original_url'] ?? '').toString(),
    isPlaylist: isPlaylist,
    uploader: decoded['uploader']?.toString() ?? decoded['channel']?.toString(),
    thumbnail: thumbnail,
    duration: duration is num ? Duration(seconds: duration.round()) : null,
    entries: entries,
  );
}
