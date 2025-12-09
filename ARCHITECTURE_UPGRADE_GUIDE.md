# SaveBite Architecture Upgrade Guide

## Overview

This document describes the architecture upgrade from UI-only prototype to a structured app with proper state management, data models, and service layer.

---

## What Was Added

### 1. Data Models (`lib/models/`)

All models include:
- `fromJson()` / `toJson()` for serialization
- `copyWith()` for immutable updates
- Proper enums for type safety

**Created Models:**
- `UserModel` - User data with role and impact metrics
- `FoodItemModel` - Surplus food items with pricing and availability
- `CartItemModel` - Shopping cart items
- `OrderModel` - Customer orders with status tracking
- `MerchantModel` - Merchant/restaurant profiles
- `DonationModel` - Food donations to NGOs

### 2. Service Layer (`lib/services/`)

All services use:
- Singleton pattern
- Async/await for network simulation
- Mock data for now (ready for Firebase replacement)

**Created Services:**
- `AuthService` - User authentication (login, signup, logout)
- `FoodService` - Food item CRUD operations
- `MerchantService` - Merchant management
- `OrderService` - Order creation and tracking
- `DonationService` - Donation coordination

### 3. State Management (`lib/providers/`)

All providers use:
- `ChangeNotifier` pattern
- Loading states
- Error handling
- `notifyListeners()` for UI updates

**Created Providers:**
- `AuthProvider` - Authentication state
- `FoodProvider` - Food items with filtering/search
- `CartProvider` - Shopping cart management
- `OrderProvider` - Order history and tracking
- `MerchantProvider` - Merchant data
- `DonationProvider` - Donation management

### 4. App Initialization

**Updated `main.dart`:**
- Wrapped app with `MultiProvider`
- Registered all 6 providers
- Auto-initialized auth and food data on startup

**Updated `app_router.dart`:**
- Added redirect placeholder for auth guards
- Ready for role-based routing

---

## How to Use Providers in Screens

### Reading Data

```dart
// In any screen
import 'package:provider/provider.dart';

// Read data (rebuilds on change)
final foodProvider = context.watch<FoodProvider>();
final foods = foodProvider.displayedFoodItems;

// Read data once (no rebuild)
final cartProvider = context.read<CartProvider>();
```

### Updating Data

```dart
// Add to cart
context.read<CartProvider>().addItem(foodItem);

// Create order
final order = await context.read<OrderProvider>().createOrder(
  userId: userId,
  merchantId: merchantId,
  // ... other params
);

// Update user profile
await context.read<AuthProvider>().updateProfile(
  name: 'New Name',
);
```

---

## Integration Examples

### Example 1: Home Screen with FoodProvider

**Before (Mock Data):**
```dart
final List<Map<String, dynamic>> _surplusItems = [
  {'name': 'Food 1', 'price': 10.0},
  // ...
];
```

**After (Provider):**
```dart
@override
Widget build(BuildContext context) {
  final foodProvider = context.watch<FoodProvider>();
  
  if (foodProvider.isLoading) {
    return CircularProgressIndicator();
  }
  
  final items = foodProvider.displayedFoodItems;
  
  return ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, index) {
      final item = items[index];
      return FoodCard(
        imageUrl: item.imageUrl,
        title: item.name,
        merchantName: item.merchantName,
        originalPrice: item.originalPrice,
        discountedPrice: item.discountedPrice,
        discountPercentage: item.discountPercentage,
        // ...
      );
    },
  );
}
```

### Example 2: Cart Screen with CartProvider

**Before (Local State):**
```dart
final Map<String, int> _cart = {};

void _addToCart(item) {
  setState(() {
    _cart[item.id] = (_cart[item.id] ?? 0) + 1;
  });
}
```

**After (Provider):**
```dart
void _addToCart(FoodItemModel item) {
  try {
    context.read<CartProvider>().addItem(item);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added to cart')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  }
}

@override
Widget build(BuildContext context) {
  final cartProvider = context.watch<CartProvider>();
  
  return Column(
    children: [
      Text('Items: ${cartProvider.itemCount}'),
      Text('Total: RM ${cartProvider.subtotal.toStringAsFixed(2)}'),
      // ...
    ],
  );
}
```

### Example 3: Checkout with OrderProvider

**Before (Simulated):**
```dart
void _placeOrder() async {
  await Future.delayed(Duration(seconds: 2));
  Navigator.push(context, MaterialPageRoute(...));
}
```

**After (Provider):**
```dart
void _placeOrder() async {
  final authProvider = context.read<AuthProvider>();
  final cartProvider = context.read<CartProvider>();
  final orderProvider = context.read<OrderProvider>();
  
  final order = await orderProvider.createOrder(
    userId: authProvider.currentUser!.id,
    merchantId: 'merchant_001',
    merchantName: 'The Baker\'s Cottage',
    items: cartProvider.items,
    subtotal: cartProvider.subtotal,
    serviceFee: 2.00,
    deliveryFee: _isSelfPickup ? 0.00 : 5.00,
    totalPrice: _total,
    totalSavings: cartProvider.totalSavings,
    fulfillmentType: _isSelfPickup 
        ? FulfillmentType.pickup 
        : FulfillmentType.delivery,
    paymentMethod: PaymentMethod.card,
  );
  
  if (order != null) {
    cartProvider.clearCart();
    context.go('/track-order/${order.id}');
  }
}
```

### Example 4: Impact Dashboard with AuthProvider

**Before (Static Data):**
```dart
final int mealsSaved = 42;
final double co2Reduced = 105.0;
```

**After (Provider):**
```dart
@override
Widget build(BuildContext context) {
  final authProvider = context.watch<AuthProvider>();
  final impactData = authProvider.currentUser?.impactData;
  
  if (impactData == null) {
    return Text('No impact data available');
  }
  
  return Column(
    children: [
      ImpactCard(
        title: 'Meals Saved',
        value: impactData.mealsSaved.toString(),
      ),
      ImpactCard(
        title: 'CO₂ Reduced',
        value: '${impactData.co2Reduced.toStringAsFixed(1)} kg',
      ),
      ImpactCard(
        title: 'Money Saved',
        value: 'RM ${impactData.moneySaved.toStringAsFixed(2)}',
      ),
    ],
  );
}
```

---

## Migration Checklist

### Screens to Update

- [ ] `lib/screens/home_screen.dart` - Use FoodProvider
- [ ] `lib/screens/merchant_details_screen.dart` - Use FoodProvider & CartProvider
- [ ] `lib/screens/cart_screen.dart` - Use CartProvider
- [ ] `lib/screens/checkout_screen.dart` - Use CartProvider & OrderProvider
- [ ] `lib/screens/order_history_screen.dart` - Use OrderProvider
- [ ] `lib/screens/track_order_screen.dart` - Use OrderProvider
- [ ] `lib/features/auth/screens/login_screen.dart` - Use AuthProvider
- [ ] `lib/features/auth/screens/signup_screen.dart` - Use AuthProvider
- [ ] `lib/features/impact/screens/impact_dashboard_screen.dart` - Use AuthProvider
- [ ] `lib/features/marketplace/screens/marketplace_screen.dart` - Use FoodProvider
- [ ] `lib/features/merchant/screens/merchant_dashboard_screen.dart` - Use MerchantProvider & FoodProvider
- [ ] `lib/features/profile/screens/profile_screen.dart` - Use AuthProvider

### Features to Implement

1. **Authentication Flow**
   - Update login screen to use AuthProvider
   - Update signup screen to use AuthProvider
   - Implement auth guards in router
   - Add role-based navigation

2. **Food Discovery**
   - Replace mock data with FoodProvider
   - Implement search functionality
   - Implement category filtering
   - Add location-based filtering

3. **Shopping Cart**
   - Replace local state with CartProvider
   - Add cart persistence (SharedPreferences)
   - Handle stock validation
   - Support multiple merchants

4. **Order Management**
   - Use OrderProvider for order creation
   - Implement order tracking
   - Add order history
   - Support order status updates

5. **Merchant Features**
   - Use MerchantProvider for merchant data
   - Implement food item management
   - Add order management for merchants
   - Support merchant analytics

6. **Donation System**
   - Use DonationProvider
   - Implement donation creation
   - Add NGO selection
   - Track donation status

---

## Future Backend Integration

### Firebase Setup (When Ready)

1. **Authentication**
   ```dart
   // In auth_service.dart
   Future<UserModel> login(String email, String password) async {
     final credential = await FirebaseAuth.instance
         .signInWithEmailAndPassword(email: email, password: password);
     
     final userDoc = await FirebaseFirestore.instance
         .collection('users')
         .doc(credential.user!.uid)
         .get();
     
     return UserModel.fromJson(userDoc.data()!);
   }
   ```

2. **Firestore Queries**
   ```dart
   // In food_service.dart
   Future<List<FoodItemModel>> getAllFoodItems() async {
     final snapshot = await FirebaseFirestore.instance
         .collection('food_items')
         .where('isAvailable', isEqualTo: true)
         .orderBy('createdAt', descending: true)
         .get();
     
     return snapshot.docs
         .map((doc) => FoodItemModel.fromJson(doc.data()))
         .toList();
   }
   ```

3. **Real-time Updates**
   ```dart
   // In food_provider.dart
   void listenToFoodItems() {
     FirebaseFirestore.instance
         .collection('food_items')
         .snapshots()
         .listen((snapshot) {
       _allFoodItems = snapshot.docs
           .map((doc) => FoodItemModel.fromJson(doc.data()))
           .toList();
       notifyListeners();
     });
   }
   ```

### API Integration (Alternative)

```dart
// In food_service.dart
Future<List<FoodItemModel>> getAllFoodItems() async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/food-items'),
    headers: {'Authorization': 'Bearer $token'},
  );
  
  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => FoodItemModel.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load food items');
  }
}
```

---

## Testing the Architecture

### 1. Test Providers

```dart
void main() {
  test('CartProvider adds items correctly', () {
    final cart = CartProvider();
    final foodItem = FoodItemModel(/* ... */);
    
    cart.addItem(foodItem);
    
    expect(cart.itemCount, 1);
    expect(cart.subtotal, foodItem.discountedPrice);
  });
}
```

### 2. Test Services

```dart
void main() {
  test('FoodService returns mock data', () async {
    final service = FoodService();
    final items = await service.getAllFoodItems();
    
    expect(items.isNotEmpty, true);
    expect(items.first.name, isNotEmpty);
  });
}
```

### 3. Test Models

```dart
void main() {
  test('UserModel serialization works', () {
    final user = UserModel(/* ... */);
    final json = user.toJson();
    final decoded = UserModel.fromJson(json);
    
    expect(decoded.id, user.id);
    expect(decoded.name, user.name);
  });
}
```

---

## Common Patterns

### Loading States

```dart
@override
Widget build(BuildContext context) {
  final provider = context.watch<FoodProvider>();
  
  if (provider.isLoading) {
    return Center(child: CircularProgressIndicator());
  }
  
  if (provider.errorMessage != null) {
    return Center(child: Text('Error: ${provider.errorMessage}'));
  }
  
  return ListView(...);
}
```

### Error Handling

```dart
try {
  await context.read<OrderProvider>().createOrder(/* ... */);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Order placed successfully!')),
  );
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: $e')),
  );
}
```

### Conditional Rendering

```dart
final authProvider = context.watch<AuthProvider>();

if (!authProvider.isAuthenticated) {
  return LoginScreen();
}

if (authProvider.userRole == UserRole.merchant) {
  return MerchantDashboard();
} else {
  return ConsumerHome();
}
```

---

## Next Steps

1. **Update existing screens** to use providers instead of local state
2. **Test the app** to ensure everything still works
3. **Add cart persistence** using SharedPreferences
4. **Implement auth guards** in router
5. **Add error boundaries** for better error handling
6. **Prepare for Firebase** by reviewing service layer
7. **Add unit tests** for providers and services
8. **Document API contracts** for backend team

---

## Notes

- All existing UI screens remain unchanged
- Mock data is used throughout for now
- Architecture is ready for Firebase/API integration
- Providers auto-initialize on app startup
- Error handling is built into all providers
- Models support JSON serialization for API calls

---

## Support

For questions or issues with the architecture:
1. Review this guide
2. Check provider documentation
3. Test with mock data first
4. Prepare for backend integration

**The app should compile and run exactly as before, but now with proper architecture!**
