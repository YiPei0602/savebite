import 'package:url_launcher/url_launcher.dart';

/// Formats a Malaysia-style local number for `wa.me` (digits only, country 60).
String riderPhoneDigitsForWhatsApp(String raw) {
  final d = raw.replaceAll(RegExp(r'\D'), '');
  if (d.isEmpty) return '';
  if (d.startsWith('60')) return d;
  if (d.startsWith('0')) return '60${d.substring(1)}';
  return d;
}

Future<bool> openRiderWhatsApp(String rawPhone) async {
  final digits = riderPhoneDigitsForWhatsApp(rawPhone);
  if (digits.isEmpty) return false;
  final uri = Uri.parse('https://wa.me/$digits');
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<bool> callRiderPhone(String rawPhone) async {
  final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return false;
  final uri = Uri(scheme: 'tel', path: digits);
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
