import 'package:cloud_firestore/cloud_firestore.dart';

/// Parse Firestore-backed instant fields: [Timestamp], ISO [String], or [DateTime].
DateTime? dateTimeFromFirestore(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

DateTime dateTimeFromFirestoreWithDefault(
  dynamic value, {
  DateTime? defaultValue,
}) {
  return dateTimeFromFirestore(value) ?? defaultValue ?? DateTime.now();
}

Timestamp? timestampFromDateTime(DateTime? dt) {
  if (dt == null) return null;
  return Timestamp.fromDate(dt);
}
