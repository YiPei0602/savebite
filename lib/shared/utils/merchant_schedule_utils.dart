import 'package:timezone/timezone.dart' as tz;
import 'package:savebite/features/marketplace_surplus/domain/models/merchant_model.dart';
import 'package:savebite/shared/utils/malaysia_store_time_utils.dart';

/// Parses `HH:mm` into minutes from midnight.
int merchantTimeToMinutes(String hhmm) {
  final p = hhmm.split(':');
  final h = int.tryParse(p[0]) ?? 0;
  final m = int.tryParse(p.length > 1 ? p[1] : '0') ?? 0;
  return h * 60 + m;
}

bool hasValidOperatingSchedule(MerchantModel? m) {
  if (m == null) return false;
  final opening = m.openingTime?.trim() ?? '';
  final closing = m.closingTime?.trim() ?? '';
  final days = m.operatingDays;
  final timeOk = RegExp(r'^\d{1,2}:\d{2}$').hasMatch(opening) &&
      RegExp(r'^\d{1,2}:\d{2}$').hasMatch(closing);
  return days.isNotEmpty && timeOk;
}

bool _hasValidSchedule(MerchantModel? m) => hasValidOperatingSchedule(m);

int _prevWeekday(int weekday) => weekday == 1 ? 7 : weekday - 1;

/// Whether the store is open for [weekday] (Mon=1…Sun=7) at [minutesFromMidnight].
///
/// Supports overnight (e.g. Fri 20:00 → Sat 02:00): when closing minutes ≤ opening
/// minutes, the session crosses midnight (closing is **later** in real time).
bool isMerchantOpenAtWallClock(
  MerchantModel? merchant, {
  required int weekday,
  required int minutesFromMidnight,
}) {
  if (merchant == null) return true;
  if (!_hasValidSchedule(merchant)) {
    return merchant.isOpen;
  }
  final days = merchant.operatingDays.toSet();
  final opening = merchant.openingTime!.trim();
  final closing = merchant.closingTime!.trim();
  final openM = merchantTimeToMinutes(opening);
  final closeM = merchantTimeToMinutes(closing);
  final nowM = minutesFromMidnight;
  final wd = weekday;

  if (openM == closeM) return false;

  if (closeM > openM) {
    if (!days.contains(wd)) return false;
    return nowM >= openM && nowM < closeM;
  }

  if (nowM < closeM) {
    return days.contains(_prevWeekday(wd));
  }
  if (nowM >= openM) {
    return days.contains(wd);
  }
  return false;
}

/// Uses device-local [DateTime] wall clock (prefer [isMerchantOpenNowMalaysia] for stores).
bool isMerchantOpenAt(MerchantModel? merchant, DateTime now) {
  return isMerchantOpenAtWallClock(
    merchant,
    weekday: now.weekday,
    minutesFromMidnight: now.hour * 60 + now.minute,
  );
}

/// Store open **now** in Asia/Kuala_Lumpur (opening/closing + operating days, overnight OK).
bool isMerchantOpenNowMalaysia(MerchantModel? merchant) {
  final c = MalaysiaStoreTimeUtils.scheduleNowMalaysia();
  return isMerchantOpenAtWallClock(
    merchant,
    weekday: c.weekday,
    minutesFromMidnight: c.minutesFromMidnight,
  );
}

/// Next closing instant for the **current** open session in Malaysia, or `null`.
DateTime? closingInstantForCurrentOpenSessionMalaysia(MerchantModel? merchant) {
  if (merchant == null || !_hasValidSchedule(merchant)) return null;
  final loc = tz.getLocation('Asia/Kuala_Lumpur');
  final z = MalaysiaStoreTimeUtils.nowMalaysia();
  if (!isMerchantOpenAtWallClock(
    merchant,
    weekday: z.weekday,
    minutesFromMidnight: z.hour * 60 + z.minute,
  )) {
    return null;
  }

  final days = merchant.operatingDays.toSet();
  final opening = merchant.openingTime!.trim();
  final closing = merchant.closingTime!.trim();
  final openM = merchantTimeToMinutes(opening);
  final closeM = merchantTimeToMinutes(closing);
  final nowM = z.hour * 60 + z.minute;
  final wd = z.weekday;

  final closeParts = closing.split(':');
  final ch = int.tryParse(closeParts[0]) ?? 0;
  final cm = int.tryParse(closeParts.length > 1 ? closeParts[1] : '0') ?? 0;

  if (openM == closeM) return null;

  late final tz.TZDateTime end;

  if (closeM > openM) {
    if (!days.contains(wd) || nowM < openM || nowM >= closeM) return null;
    end = tz.TZDateTime(loc, z.year, z.month, z.day, ch, cm, 0);
  } else if (nowM < closeM) {
    if (!days.contains(_prevWeekday(wd))) return null;
    end = tz.TZDateTime(loc, z.year, z.month, z.day, ch, cm, 0);
  } else if (nowM >= openM) {
    if (!days.contains(wd)) return null;
    final t1 = z.add(const Duration(days: 1));
    end = tz.TZDateTime(loc, t1.year, t1.month, t1.day, ch, cm, 0);
  } else {
    return null;
  }

  return DateTime.fromMillisecondsSinceEpoch(end.millisecondsSinceEpoch);
}

/// Countdown until session closing in Malaysia; `null` if no valid schedule.
/// [Duration.zero] when closed or past closing for the session.
Duration? durationUntilClosingMalaysia(MerchantModel? merchant) {
  if (merchant == null || !_hasValidSchedule(merchant)) return null;
  if (!isMerchantOpenNowMalaysia(merchant)) {
    return Duration.zero;
  }
  final end = closingInstantForCurrentOpenSessionMalaysia(merchant);
  if (end == null) return Duration.zero;
  final ms = end.millisecondsSinceEpoch - DateTime.now().millisecondsSinceEpoch;
  return Duration(milliseconds: ms);
}

/// Surplus listings should not be sold when the store session is closed (Malaysia).
bool isListingPastStoreSessionMalaysia(MerchantModel? merchant) {
  if (merchant == null) return false;
  if (!_hasValidSchedule(merchant)) {
    return !merchant.isOpen;
  }
  return !isMerchantOpenNowMalaysia(merchant);
}

/// Next instant when the store closes for the **current** open session, or `null`.
///
/// Uses [now]'s calendar date and wall clock (device local). Prefer
/// [closingInstantForCurrentOpenSessionMalaysia] for Malaysia-based stores.
DateTime? closingInstantForCurrentOpenSession(
  MerchantModel? merchant,
  DateTime now,
) {
  if (merchant == null || !_hasValidSchedule(merchant)) return null;
  if (!isMerchantOpenAtWallClock(
    merchant,
    weekday: now.weekday,
    minutesFromMidnight: now.hour * 60 + now.minute,
  )) {
    return null;
  }

  final days = merchant.operatingDays.toSet();
  final opening = merchant.openingTime!.trim();
  final closing = merchant.closingTime!.trim();
  final openM = merchantTimeToMinutes(opening);
  final closeM = merchantTimeToMinutes(closing);
  final nowM = now.hour * 60 + now.minute;
  final wd = now.weekday;

  final closeParts = closing.split(':');
  final ch = int.tryParse(closeParts[0]) ?? 0;
  final cm = int.tryParse(closeParts.length > 1 ? closeParts[1] : '0') ?? 0;

  if (openM == closeM) return null;

  if (closeM > openM) {
    if (!days.contains(wd) || nowM < openM || nowM >= closeM) return null;
    return DateTime(now.year, now.month, now.day, ch, cm);
  }
  if (nowM < closeM) {
    if (!days.contains(_prevWeekday(wd))) return null;
    return DateTime(now.year, now.month, now.day, ch, cm);
  }
  if (nowM >= openM) {
    if (!days.contains(wd)) return null;
    final tomorrow = now.add(const Duration(days: 1));
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, ch, cm);
  }
  return null;
}

/// Time remaining until pickup closes for the current session.
/// Returns `null` if no countdown should be shown.
Duration? durationUntilPickupClosing(MerchantModel? merchant, DateTime now) {
  final end = closingInstantForCurrentOpenSession(merchant, now);
  if (end == null) return null;
  final diff = end.difference(now);
  if (diff.isNegative) return Duration.zero;
  return diff;
}
