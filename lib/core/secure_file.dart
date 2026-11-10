import 'dart:io';

/// Best effort: restrict a file to owner read/write on unix-like systems by
/// shelling out to chmod. No-op on Windows and never throws.
Future<void> restrictFileToOwner(File file) async {
  if (Platform.isWindows) return;
  try {
    final result = await Process.run('chmod', ['600', file.path]);
    if (result.exitCode != 0) {
      // Not fatal: the file is in a user-owned app directory.
    }
  } catch (_) {
    // chmod may not exist; failing here must not break the app.
  }
}

/// Writes [contents] to [target] atomically: a temporary file in the same
/// directory is written and fsynced, then renamed over [target]. That way a
/// crash mid-write never leaves a half-written JSON file behind. Falls back
/// to a direct write if that fails, and never throws.
Future<void> writeFileAtomic(File target, String contents) async {
  final tmp = File('${target.path}.tmp');
  try {
    await tmp.writeAsString(contents, flush: true);
    await tmp.rename(target.path);
  } catch (_) {
    // Rename not available or not permitted; write directly as before.
    try {
      await target.writeAsString(contents);
    } catch (_) {}
    try {
      await tmp.delete();
    } catch (_) {}
  }
}
