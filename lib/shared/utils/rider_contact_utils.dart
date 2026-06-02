import 'package:url_launcher/url_launcher.dart';

/// How [openRiderWhatsApp] opened (or failed).
enum RiderWhatsAppLaunch {
  nativeApp,
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

/// Opens WhatsApp chat with [rawPhone] and optional prefilled [message].
///
/// 1. Native app (`whatsapp://`) when installed.
/// Strict native flow only (`whatsapp://`) to guarantee app-to-app redirect.
/// If WhatsApp is not installed / unavailable, return [RiderWhatsAppLaunch.failed].
Future<RiderWhatsAppLaunch> openRiderWhatsApp(
  String rawPhone, {
  String? message,
}) async {
  final digits = riderPhoneDigitsForWhatsApp(rawPhone);
  if (digits.isEmpty) return RiderWhatsAppLaunch.failed;
  final encodedMessage = (message ?? '').trim();
  final text = encodedMessage.isEmpty ? null : encodedMessage;

  final nativeCandidates = <Uri>[
    Uri(
      scheme: 'whatsapp',
      host: 'send',
      queryParameters: {
        'phone': digits,
        if (text != null) 'text': text,
      },
    ),
    // iOS builds sometimes accept this variant more reliably.
    Uri.parse(
      'whatsapp://send/?phone=$digits'
      '${text == null ? '' : '&text=${Uri.encodeComponent(text)}'}',
    ),
  ];

  for (final uri in nativeCandidates) {
    if (await _tryLaunch(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      return RiderWhatsAppLaunch.nativeApp;
    }
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
    RiderWhatsAppLaunch.failed =>
      'Unable to open WhatsApp app. Check the rider phone number and ensure WhatsApp is installed.',
  };
}
