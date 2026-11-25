/// True when [now] falls inside the configured quiet window.
///
/// Windows that cross midnight are supported, for example 22 to 6 means the
/// window is active from 22:00 through 05:59.
bool isWithinQuietHours(DateTime now, int startHour, int endHour) {
  final hour = now.hour;
  if (startHour == endHour) return false;
  if (startHour < endHour) {
    return hour >= startHour && hour < endHour;
  }
  return hour >= startHour || hour < endHour;
}
