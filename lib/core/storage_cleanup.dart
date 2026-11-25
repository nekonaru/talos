import 'dart:io';

/// Removes stale partial files produced by crashed downloads or interrupted
/// atomic writes. Recent files are kept because an active task may still own
/// them; only files older than [olderThan] are candidates.
Future<int> cleanTemporaryFiles(
  Directory directory, {
  Duration olderThan = const Duration(hours: 1),
}) async {
  const suffixes = ['.tmp', '.part', '.ytdl', '.download'];
  final cutoff = DateTime.now().subtract(olderThan).millisecondsSinceEpoch;
  var removed = 0;
  try {
    if (!await directory.exists()) return 0;
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.isNotEmpty
          ? entity.uri.pathSegments.last
          : entity.path.split(Platform.pathSeparator).last;
      if (!suffixes.any(name.endsWith)) continue;
      try {
        final stat = await entity.stat();
        if (stat.modified.millisecondsSinceEpoch > cutoff) continue;
        await entity.delete();
        removed++;
      } catch (_) {
        // A locked or already removed file is not an error for cleanup.
      }
    }
  } catch (_) {
    // Missing or unreadable directory: nothing to clean.
  }
  return removed;
}
