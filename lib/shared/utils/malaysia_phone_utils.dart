/// Malaysian mobile number helpers (default country +60).
///
/// Accepts common local formats:
/// - `01X-XXX XXXX` / `01XXXXXXXXX` (10 digits incl. leading 0)
/// - `011-XXXX XXXX` / `011XXXXXXXXX` (11 digits incl. leading 0)
/// - E.164: `+601XXXXXXXX`, `+6011XXXXXXXX`
library malaysia_phone_utils;

/// Normalizes input to E.164 `+60…` or returns null if invalid.
String? normalizeMalaysianMobileToE164(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  final digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');
  if (digitsOnly.isEmpty) return null;

  late String nsn;

  if (trimmed.startsWith('+')) {
    if (!trimmed.startsWith('+60')) return null;
    if (!digitsOnly.startsWith('60')) return null;
    nsn = digitsOnly.substring(2);
  } else if (digitsOnly.startsWith('60') && digitsOnly.length >= 11) {
    nsn = digitsOnly.substring(2);
  } else if (digitsOnly.startsWith('0')) {
    nsn = digitsOnly.substring(1);
  } else if (digitsOnly.startsWith('1') &&
      (digitsOnly.length == 9 || digitsOnly.length == 10)) {
    nsn = digitsOnly;
  } else {
    return null;
  }

  if (!RegExp(r'^(1[0-9]\d{7}|11\d{8})$').hasMatch(nsn)) {
    return null;
  }

  return '+60$nsn';
}

/// Returns null if valid, otherwise an error message for [TextFormField].
String? validateMalaysianMobileField(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Please enter your mobile number';
  }
  if (normalizeMalaysianMobileToE164(value) == null) {
    return 'Use a valid Malaysian mobile number '
        '(e.g. 012-345 6789 or 011-1234 5678)';
  }
  return null;
}
