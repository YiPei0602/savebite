import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'app/theme/app_theme.dart';
import 'app/router/app_router.dart';
import 'features/auth_profile_impact/state/providers/auth_provider.dart';
import 'features/marketplace_surplus/state/providers/food_provider.dart';
import 'features/orders_payments/state/providers/cart_provider.dart';
import 'features/orders_payments/state/providers/order_provider.dart';
import 'features/marketplace_surplus/state/providers/merchant_provider.dart';
import 'features/donations/state/providers/donation_provider.dart';

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
      child: const _AppShell(),
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  AuthProvider? _authProvider;
  late final GoRouter _router;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context);
    if (_authProvider == null) {
      _authProvider = authProvider;
      _router = AppRouter.createRouter(authProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SaveBite',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      // Initial route is set in AppRouter to '/landing'
    );
  }
}
