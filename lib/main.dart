import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'core/config/stripe_publishable_key.dart';
import 'firebase_options.dart';
import 'app/theme/app_theme.dart';
import 'app/router/app_router.dart';
import 'features/auth_profile_impact/state/providers/auth_provider.dart';
import 'features/marketplace_surplus/state/providers/food_provider.dart';
import 'features/orders_payments/state/providers/cart_provider.dart';
import 'features/orders_payments/state/providers/order_provider.dart';
import 'features/marketplace_surplus/state/providers/merchant_provider.dart';

/// SaveBite - Food Rescue Platform
///
/// Main entry point of the application.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  Stripe.publishableKey = StripePublishableKey.value;
  // Required on iOS for Payment Sheet (3DS, Link, redirects). Must match
  // CFBundleURLSchemes in ios/Runner/Info.plist.
  Stripe.urlScheme = 'savebite';
  await Stripe.instance.applySettings();

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
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(
          create: (_) => FoodProvider()
            ..loadFoodItems()
            ..startRealtimeCatalogSync(),
        ),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(
            create: (_) => MerchantProvider()..loadMerchants()),
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
    );
  }
}
