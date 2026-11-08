// Small formatting helpers shared across screens.

String formatBytes(int? bytes) {
  if (bytes == null) return '';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final fixed = value >= 100 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  return '$fixed ${units[unit]}';
}

String formatSpeed(double? bytesPerSecond) {
  if (bytesPerSecond == null || bytesPerSecond <= 0) return '';
  return '${formatBytes(bytesPerSecond.round())}/s';
}

String formatEta(double? seconds) {
  if (seconds == null || seconds.isNaN || seconds.isInfinite) return '';
  final total = seconds.round();
  if (total < 60) return '${total}s';
  final minutes = total ~/ 60;
  final remainder = total % 60;
  if (minutes < 60) return '${minutes}m ${remainder.toString().padLeft(2, '0')}s';
  final hours = minutes ~/ 60;
  return '${hours}h ${(minutes % 60).toString().padLeft(2, '0')}m';
}

String formatDuration(Duration? duration) {
  if (duration == null) return '';
  final total = duration.inSeconds;
  final hours = total ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  final seconds = total % 60;
  final mm = minutes.toString().padLeft(2, '0');
  final ss = seconds.toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$mm:$ss' : '$minutes:$ss';
}

String formatDate(int dateMs) {
  final date = DateTime.fromMillisecondsSinceEpoch(dateMs);
  final dd = date.day.toString().padLeft(2, '0');
  final mm = date.month.toString().padLeft(2, '0');
  return '$dd.$mm.${date.year}';
}
