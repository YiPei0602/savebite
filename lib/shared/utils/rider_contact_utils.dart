import 'package:url_launcher/url_launcher.dart';

/// How [openRiderWhatsApp] opened (or failed).
enum RiderWhatsAppLaunch {
  nativeApp,
  whatsAppWeb,
  waMeLink,
  failed,
}

/// Formats a Malaysia-style local number for WhatsApp (`wa.me` / `whatsapp://`).
String riderPhoneDigitsForWhatsApp(String raw) {
  final d = raw.replaceAll(RegExp(r'\D'), '');
  if (d.isEmpty) return '';
  if (d.startsWith('60') && d.length >= 10) return d;
  if (d.startsWith('0') && d.length >= 9) return '60${d.substring(1)}';
  // Local mobile without leading 0 (e.g. 174163920).
  if (d.length >= 9 && d.length <= 10 && d.startsWith('1')) return '60$d';
  return d;
}

/// Opens WhatsApp chat with [rawPhone].
///
/// 1. Native app (`whatsapp://`) when installed.
/// 2. [WhatsApp Web](https://web.whatsapp.com) — works on iOS Simulator after QR login.
/// 3. `wa.me` universal link as last resort.
Future<RiderWhatsAppLaunch> openRiderWhatsApp(String rawPhone) async {
  final digits = riderPhoneDigitsForWhatsApp(rawPhone);
  if (digits.isEmpty) return RiderWhatsAppLaunch.failed;

  final nativeUri = Uri.parse('whatsapp://send?phone=$digits');
  if (await _tryLaunch(
    nativeUri,
    mode: LaunchMode.externalNonBrowserApplication,
  )) {
    return RiderWhatsAppLaunch.nativeApp;
  }

  final webChatUri = Uri.parse(
    'https://web.whatsapp.com/send?phone=$digits',
  );
  if (await _tryLaunch(
    webChatUri,
    mode: LaunchMode.externalApplication,
  )) {
    return RiderWhatsAppLaunch.whatsAppWeb;
  }

  final waMeUri = Uri.parse('https://wa.me/$digits');
  if (await _tryLaunch(
    waMeUri,
    mode: LaunchMode.externalApplication,
  )) {
    return RiderWhatsAppLaunch.waMeLink;
  }

  return RiderWhatsAppLaunch.failed;
}

Future<bool> _tryLaunch(
  Uri uri, {
  required LaunchMode mode,
}) async {
  try {
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: mode);
    }
  } catch (_) {
    //
  }
  try {
    return await launchUrl(uri, mode: mode);
  } catch (_) {
    return false;
  }
}

Future<bool> callRiderPhone(String rawPhone) async {
  final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return false;
  final uri = Uri(scheme: 'tel', path: digits);
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// User-facing hint after [openRiderWhatsApp] (null = no snackbar needed).
String? riderWhatsAppLaunchSnackMessage(RiderWhatsAppLaunch result) {
  return switch (result) {
    RiderWhatsAppLaunch.nativeApp => null,
    RiderWhatsAppLaunch.whatsAppWeb =>
      'Opened WhatsApp Web. On first use, scan the QR code with WhatsApp on your phone.',
    RiderWhatsAppLaunch.waMeLink =>
      'Opened WhatsApp link. Use Open app if WhatsApp is installed, or try WhatsApp Web in Safari.',
    RiderWhatsAppLaunch.failed =>
      'Unable to open WhatsApp. Check the rider phone number or install WhatsApp.',
  };
}
