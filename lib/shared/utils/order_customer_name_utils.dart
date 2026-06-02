import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:savebite/features/auth_profile_impact/domain/models/user_model.dart';
import 'package:savebite/features/orders_payments/domain/models/order_model.dart';

String customerNameFromUser(UserModel? user) {
  if (user == null) return 'Customer';
  final full = user.name.trim();
  if (full.isNotEmpty) return full;
  final first = user.firstName.trim();
  if (first.isNotEmpty) return first;
  return 'Customer';
}

String plainMerchantCustomerName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'Customer';
  return trimmed;
}

String formatMerchantCustomerLine(String name) {
  return 'Customer: ${plainMerchantCustomerName(name)}';
}

Future<String> resolveMerchantCustomerLabel(OrderModel order) async {
  final stored = order.customerName?.trim();
  if (stored != null && stored.isNotEmpty) {
    return plainMerchantCustomerName(stored);
  }

  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(order.userId)
        .get();
    final data = doc.data();
    if (data != null) {
      final user = UserModel.fromFirestore(data, doc.id);
      return plainMerchantCustomerName(customerNameFromUser(user));
    }
  } catch (_) {
    // Fallback label below when user doc cannot be read.
  }

  return 'Customer';
}
