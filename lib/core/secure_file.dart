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
