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
/// directory is written and fsynced, then replaces [target]. That way a crash
/// mid-write never leaves a half-written JSON file behind. On Windows rename
/// cannot overwrite an existing file, so copy is used there. Falls back to a
/// direct write if the atomic path fails, and never throws.
Future<void> writeFileAtomic(File target, String contents) async {
  // A unique temp path per call prevents two overlapping persists from
  // truncating each other's file and replacing the target with partial JSON.
  final nonce = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final tmp = File('${target.path}.$nonce.tmp');
  try {
    await tmp.writeAsString(contents, flush: true);
    if (Platform.isWindows && await target.exists()) {
      await tmp.copy(target.path);
      await tmp.delete();
    } else {
      await tmp.rename(target.path);
    }
    return;
  } catch (_) {
    // Atomic replace not permitted; write directly as before.
  }
  try {
    await target.writeAsString(contents);
  } catch (_) {}
  try {
    if (await tmp.exists()) await tmp.delete();
  } catch (_) {}
}
