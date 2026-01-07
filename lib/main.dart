import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/marketplace/providers/food_provider.dart';
import 'features/cart/providers/cart_provider.dart';
import 'features/orders/providers/order_provider.dart';
import 'features/marketplace/providers/merchant_provider.dart';
import 'features/donation/providers/donation_provider.dart';

/// SaveBite - Food Rescue Platform
/// 
/// Main entry point of the application.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const SaveBiteApp());
}

class SaveBiteApp extends StatelessWidget {
  const SaveBiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Authentication Provider
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        
        // Food Provider
        ChangeNotifierProvider(create: (_) => FoodProvider()..loadFoodItems()),
        
        // Cart Provider
        ChangeNotifierProvider(create: (_) => CartProvider()),
        
        // Order Provider
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        
        // Merchant Provider
        ChangeNotifierProvider(create: (_) => MerchantProvider()..loadMerchants()),
        
        // Donation Provider
        ChangeNotifierProvider(create: (_) => DonationProvider()),
      ],
      child: MaterialApp.router(
        title: 'SaveBite',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
        // Initial route is set in AppRouter to '/landing'
      ),
    );
  }
}
