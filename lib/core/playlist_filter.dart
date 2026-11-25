import 'engine/models.dart';

/// Selects playlist entries by duration range and title text.
///
/// A null duration never satisfies a duration constraint, because the user
/// asked for a bounded length and an unknown length cannot be trusted. An
/// empty query matches every title.
List<PlaylistEntry> filterPlaylistEntries(
  Iterable<PlaylistEntry> entries, {
  int? minSeconds,
  int? maxSeconds,
  String query = '',
}) {
  final needle = query.trim().toLowerCase();
  return entries.where((entry) {
    if (needle.isNotEmpty && !entry.title.toLowerCase().contains(needle)) {
      return false;
    }
    final duration = entry.duration?.inSeconds;
    if (minSeconds != null) {
      if (duration == null || duration < minSeconds) return false;
    }
    if (maxSeconds != null) {
      if (duration == null || duration > maxSeconds) return false;
    }
    return true;
  }).toList();
}
