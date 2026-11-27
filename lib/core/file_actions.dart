import 'dart:io';

/// Local file operations used by history entries. Content URIs are left to the
/// native SAF bridge and are never treated as plain filesystem paths.
abstract final class DownloadFileActions {
  static bool isPlainPath(String path) =>
      !path.startsWith('content://') && path.isNotEmpty;

  static List<File> subtitleSidecars(String path) {
    if (!isPlainPath(path)) return const [];
    final source = File(path);
    final parent = source.parent.path;
    const suffixes = ['.srt', '.vtt', '.ass', '.ssa', '.sub'];
    final base = source.uri.pathSegments.isNotEmpty
        ? source.uri.pathSegments.last.replaceAll(RegExp(r'\.[^.]+$'), '')
        : '';
    try {
      return Directory(parent)
          .listSync(followLinks: false)
          .whereType<File>()
          .where((file) {
        final name = file.uri.pathSegments.isNotEmpty
            ? file.uri.pathSegments.last
            : file.path.split(Platform.pathSeparator).last;
        if (!suffixes.any(name.toLowerCase().endsWith)) return false;
        return name.startsWith(base);
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<String?> rename(String path, String newName) async {
    if (!isPlainPath(path)) return null;
    final source = File(path);
    if (!await source.exists()) return null;
    final clean = newName.trim();
    if (clean.isEmpty) return null;
    final parent = source.parent.path;
    final target = File('$parent${Platform.pathSeparator}$clean');
    if (await target.exists()) return null;
    try {
      await source.rename(target.path);
      return target.path;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> move(String path, String destinationDir) async {
    if (!isPlainPath(path)) return null;
    final source = File(path);
    if (!await source.exists()) return null;
    final dir = Directory(destinationDir.trim());
    try {
      if (!await dir.exists()) await dir.create(recursive: true);
      final name = source.uri.pathSegments.isNotEmpty
          ? source.uri.pathSegments.last
          : source.path.split(Platform.pathSeparator).last;
      final target = File('${dir.path}${Platform.pathSeparator}$name');
      if (await target.exists()) return null;
      await source.copy(target.path);
      await source.delete();
      return target.path;
    } catch (_) {
      return null;
    }
  }
}
