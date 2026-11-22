import 'history_store.dart';

/// Pure, testable summary of the finished-download library. All sizes treat a
/// missing [HistoryEntry.sizeBytes] as zero, matching the Finished sort.
class InsightStats {
  const InsightStats({
    required this.totalCount,
    required this.videoCount,
    required this.audioCount,
    required this.favoriteCount,
    required this.totalBytes,
    required this.videoBytes,
    required this.audioBytes,
    required this.todayCount,
    required this.weekCount,
    required this.monthCount,
    required this.last7Days,
    required this.largest,
    required this.oldestDayMs,
  });

  final int totalCount;
  final int videoCount;
  final int audioCount;
  final int favoriteCount;
  final int totalBytes;
  final int videoBytes;
  final int audioBytes;
  final int todayCount;
  final int weekCount;
  final int monthCount;

  /// Download counts for the last seven local days, oldest first.
  final List<int> last7Days;

  /// Up to five largest entries, descending by size.
  final List<HistoryEntry> largest;

  /// Timestamp of the oldest dated entry, or null when none are dated.
  final int? oldestDayMs;

  double get videoShare => totalBytes > 0 ? videoBytes / totalBytes : 0;
  double get audioShare => totalBytes > 0 ? audioBytes / totalBytes : 0;
}

/// Builds [InsightStats] from [entries]. [now] is injectable for tests.
InsightStats buildInsights(List<HistoryEntry> entries, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  // Normalize to UTC calendar days so daylight-saving transitions (23/25 hour
  // local days) cannot shift a download into the wrong bucket.
  final todayUtc = DateTime.utc(reference.year, reference.month, reference.day);

  int videoCount = 0;
  int audioCount = 0;
  int favoriteCount = 0;
  int videoBytes = 0;
  int audioBytes = 0;
  int todayCount = 0;
  int weekCount = 0;
  int monthCount = 0;
  final dayBuckets = List<int>.filled(7, 0);
  int? oldestDayMs;

  for (final entry in entries) {
    final size = entry.sizeBytes ?? 0;
    if (entry.kind == HistoryKind.audio) {
      audioCount++;
      audioBytes += size;
    } else {
      videoCount++;
      videoBytes += size;
    }
    if (entry.favorite) favoriteCount++;

    final dateMs = entry.dateMs;
    if (dateMs > 0) {
      if (oldestDayMs == null || dateMs < oldestDayMs) oldestDayMs = dateMs;
      final date = DateTime.fromMillisecondsSinceEpoch(dateMs);
      final dayUtc = DateTime.utc(date.year, date.month, date.day);
      final daysAgo = todayUtc.difference(dayUtc).inDays;
      if (daysAgo == 0) todayCount++;
      if (daysAgo >= 0 && daysAgo < 7) weekCount++;
      if (daysAgo >= 0 && daysAgo < 30) monthCount++;
      if (daysAgo >= 0 && daysAgo < 7) {
        dayBuckets[6 - daysAgo]++;
      }
    }
  }

  final largest = [...entries]
    ..sort((a, b) => (b.sizeBytes ?? 0).compareTo(a.sizeBytes ?? 0));

  return InsightStats(
    totalCount: entries.length,
    videoCount: videoCount,
    audioCount: audioCount,
    favoriteCount: favoriteCount,
    totalBytes: videoBytes + audioBytes,
    videoBytes: videoBytes,
    audioBytes: audioBytes,
    todayCount: todayCount,
    weekCount: weekCount,
    monthCount: monthCount,
    last7Days: dayBuckets,
    largest: largest.take(5).toList(),
    oldestDayMs: oldestDayMs,
  );
}
