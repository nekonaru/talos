/// True when [now] falls inside the configured quiet window.
///
/// Windows that cross midnight are supported, for example 22 to 6 means the
/// window is active from 22:00 through 05:59.
bool isWithinQuietHours(DateTime now, int startHour, int endHour) {
  final hour = now.hour;
  // Equal bounds mean no restriction. Blocking on every hour would strand the
  // queue forever when the user leaves the two dropdowns on the same value.
  if (startHour == endHour) return true;
  if (startHour < endHour) {
    return hour >= startHour && hour < endHour;
  }
  return hour >= startHour || hour < endHour;
}
