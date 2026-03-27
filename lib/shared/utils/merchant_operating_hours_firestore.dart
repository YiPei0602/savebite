import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/timezone.dart' as tz;

/// Firestore encoding for merchant [openingTime] / [closingTime].
///
/// Stored as [Timestamp] on a **fixed anchor calendar date** in
/// [Asia/Kuala_Lumpur]; only **hour and minute** are meaningful (daily
/// recurring schedule). Legacy string `HH:mm` is still read for old documents.
class MerchantOperatingHoursFirestore {
  MerchantOperatingHoursFirestore._();

  static final tz.Location _my = tz.getLocation('Asia/Kuala_Lumpur');
  static const int _y = 2000;
  static const int _mo = 1;
  static const int _d = 1;

  static final RegExp _hhMm = RegExp(r'^(\d{1,2}):(\d{2})$');

  /// `HH:mm` from Firestore [Timestamp], or legacy string; `null` if missing/invalid.
  static String? readHhMm(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final s = value.trim();
      if (s.isEmpty) return null;
      final m = _hhMm.firstMatch(s);
      if (m != null) {
        final h = int.parse(m.group(1)!);
        final min = int.parse(m.group(2)!);
        return '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
      }
      return null;
    }
    if (value is Timestamp) {
      final z = tz.TZDateTime.from(value.toDate(), _my);
      return '${z.hour.toString().padLeft(2, '0')}:'
          '${z.minute.toString().padLeft(2, '0')}';
    }
    return null;
  }

  /// Writes wall-clock [hhMm] (`HH:mm`) as a Malaysia-local [Timestamp] on the anchor date.
  static Timestamp? writeHhMm(String? hhMm) {
    if (hhMm == null || hhMm.trim().isEmpty) return null;
    final m = _hhMm.firstMatch(hhMm.trim());
    if (m == null) return null;
    final h = int.parse(m.group(1)!);
    final min = int.parse(m.group(2)!);
    if (h < 0 || h > 23 || min < 0 || min > 59) return null;
    final z = tz.TZDateTime(_my, _y, _mo, _d, h, min, 0);
    return Timestamp.fromMillisecondsSinceEpoch(z.millisecondsSinceEpoch);
  }
}
