import 'package:timezone/timezone.dart' as tz;

/// Malaysia (Asia/Kuala_Lumpur) clock helpers for store schedules.
class MalaysiaStoreTimeUtils {
  MalaysiaStoreTimeUtils._();

  static final tz.Location _my = tz.getLocation('Asia/Kuala_Lumpur');

  static tz.TZDateTime nowMalaysia() => tz.TZDateTime.now(_my);

  /// Weekday (Mon=1 … Sun=7) and minutes since midnight in Malaysia.
  static ({int weekday, int minutesFromMidnight}) scheduleNowMalaysia() {
    final z = nowMalaysia();
    return (
      weekday: z.weekday,
      minutesFromMidnight: z.hour * 60 + z.minute,
    );
  }

  /// `HH:MM:SS` (24h), 24h-capable display. Use when [duration] is non-negative.
  static String formatHhMmSs(Duration duration) {
    if (duration.isNegative) return '00:00:00';
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }
}
