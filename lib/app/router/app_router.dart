import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth_profile_impact/state/providers/auth_provider.dart';
import '../../features/auth_profile_impact/domain/models/user_model.dart';
import '../../features/auth_profile_impact/presentation/screens/landing_page_screen.dart';
import '../../features/auth_profile_impact/presentation/screens/role_based_login_screen.dart';
import '../../features/auth_profile_impact/presentation/screens/welcome_screen.dart';
import '../../features/auth_profile_impact/presentation/screens/login_screen.dart';
import '../../features/auth_profile_impact/presentation/screens/signup_screen.dart';
import '../../features/marketplace_surplus/presentation/screens/home_screen.dart';
import '../../features/auth_profile_impact/presentation/screens/profile_screen.dart';
import '../../features/auth_profile_impact/presentation/screens/impact_dashboard_screen.dart';
import '../../features/merchant_management/presentation/screens/add_surplus_screen.dart';
import '../../features/merchant_management/presentation/screens/merchant_shell_screen.dart';
import '../../features/merchant_management/presentation/screens/merchant_store_setup_screen.dart';
import '../../features/auth_profile_impact/presentation/screens/edit_profile_screen.dart';
import '../../features/orders_payments/presentation/screens/payment_methods_screen.dart';
import '../../features/core_notifications/presentation/screens/notifications_screen.dart';
import '../../features/orders_payments/presentation/screens/cart_screen.dart';
import '../../features/orders_payments/presentation/screens/checkout_screen.dart';
import '../../features/orders_payments/presentation/screens/payment_screen.dart';
import '../../features/orders_payments/domain/payment_checkout_args.dart';
import '../../features/orders_payments/presentation/screens/order_history_screen.dart';
import '../../features/orders/screens/order_tracking_screen.dart';
import '../../features/marketplace_surplus/presentation/screens/merchant_details_screen.dart';
import '../../features/marketplace_surplus/presentation/screens/food_item_detail_screen.dart';
import '../../features/marketplace_surplus/presentation/screens/category_listing_screen.dart';
import '../../features/marketplace_surplus/domain/models/food_item_model.dart';

/// Public routes that don't require authentication
const _publicRoutes = [
  '/landing',
  '/welcome',
  '/role-based-login',
  '/login',
  '/signup',
];

/// Role-specific routes (prefix checks)
const _merchantOnlyRoutePrefixes = [
  '/merchant-dashboard',
  '/add-surplus',
  '/merchant-orders',
  '/merchant-profile',
  '/merchant-store-setup',
];

/// Routes that are valid for both roles (authenticated).
const _sharedRoutePrefixes = [
  '/edit-profile',
];

const _consumerOnlyRoutePrefixes = [
  '/home',
  '/profile',
  '/impact',
  '/payment-methods',
  '/notifications',
  '/cart',
  '/checkout',
  '/payment',
  '/order-history',
  '/order-tracking',
  '/category/',
  '/merchant/', // consumer marketplace merchant-details
];

String _homeForRole(UserRole? role) {
  return role == UserRole.merchant ? '/merchant-dashboard' : '/home';
}

bool _startsWithAnyPrefix(String location, List<String> prefixes) {
  for (final p in prefixes) {
    if (location == p || location.startsWith(p)) return true;
  }
  return false;
}

bool _didForceLandingOnLaunch = false;

/// SaveBite App Router
///
/// Centralized routing configuration using go_router.
/// Includes auth-based redirects for protected routes.
class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/landing',
      refreshListenable: authProvider,
      redirect: (BuildContext context, GoRouterState state) {
        final hasFirebaseSession = authProvider.hasFirebaseSession;
        final isLoading = authProvider.isLoading;
        final role = authProvider.userRole;
        final location = state.uri.path;

        // Always start at landing on cold start (prevents resuming into wrong role area)
        if (!_didForceLandingOnLaunch) {
          _didForceLandingOnLaunch = true;
          if (location != '/landing') return '/landing';
        }

        // Allow navigation while auth is initializing
        if (isLoading) return null;

        final isPublicRoute = _publicRoutes.any(
          (route) => location == route || location.startsWith('$route/'),
        );

        // Only treat as logged out when Firebase Auth has no user (avoid false kicks
        // when profile is still loading or briefly out of sync).
        if (!hasFirebaseSession) {
          if (!isPublicRoute) return '/landing';
          return null;
        }

        if (isPublicRoute) {
          // Keep the full onboarding/auth flow public even with an existing session.
          // Users should only enter role areas after explicitly completing auth flow.
          return null;
        }

        // Enforce role-based access (prevents role mixing)
        final isMerchantOnly =
            _startsWithAnyPrefix(location, _merchantOnlyRoutePrefixes);
        final isConsumerOnly =
            _startsWithAnyPrefix(location, _consumerOnlyRoutePrefixes);
        final isShared = _startsWithAnyPrefix(location, _sharedRoutePrefixes);

        if (role == UserRole.merchant && isConsumerOnly && !isShared) {
          return _homeForRole(role);
        }
        if (role == UserRole.consumer && isMerchantOnly && !isShared) {
          return _homeForRole(role);
        }

        // Apply role rules to all remaining protected routes too:
        // any protected route must be explicitly categorized, otherwise redirect to role home.
        if (!isMerchantOnly && !isConsumerOnly && !isShared) {
          return _homeForRole(role);
        }

        return null;
      },
      routes: [
        // ========================================================================
        // LANDING & ONBOARDING ROUTES
        // ========================================================================
        GoRoute(
          path: '/landing',
          name: 'landing',
          builder: (context, state) => const LandingPageScreen(),
        ),
        GoRoute(
          path: '/welcome',
          name: 'welcome',
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: '/role-based-login',
          name: 'role-based-login',
          builder: (context, state) => const RoleBasedLoginScreen(),
        ),

        // ========================================================================
        // AUTH ROUTES
        // ========================================================================
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          name: 'signup',
          builder: (context, state) => const SignupScreen(),
        ),

        // ========================================================================
        // MAIN APP ROUTES
        // ========================================================================
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) {
            final raw = state.uri.queryParameters['tab'];
            final parsed = int.tryParse(raw ?? '');
            final index = parsed == null
                ? 0
                : parsed.clamp(0, HomeScreen.tabCount - 1);
            return HomeScreen(initialTabIndex: index);
          },
        ),
        GoRoute(
          path: '/impact',
          name: 'impact',
          builder: (context, state) => const ImpactDashboardScreen(),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),

        // ========================================================================
        // MERCHANT ROUTES
        // ========================================================================
        GoRoute(
          path: '/merchant-dashboard',
          name: 'merchant-dashboard',
          builder: (context, state) => const MerchantShellScreen(
            key: ValueKey('merchant-shell-home'),
            initialTabIndex: 0,
          ),
        ),
        GoRoute(
          path: '/add-surplus',
          name: 'add-surplus',
          builder: (context, state) => AddSurplusScreen(
            initialItem: state.extra is FoodItemModel ? state.extra as FoodItemModel : null,
          ),
        ),
        GoRoute(
          path: '/merchant-orders',
          name: 'merchant-orders',
          builder: (context, state) => const MerchantShellScreen(
            key: ValueKey('merchant-shell-orders'),
            initialTabIndex: 1,
          ),
        ),
        GoRoute(
          path: '/merchant-profile',
          name: 'merchant-profile',
          builder: (context, state) => const MerchantShellScreen(
            key: ValueKey('merchant-shell-profile'),
            initialTabIndex: 2,
          ),
        ),
        GoRoute(
          path: '/merchant-store-setup',
          name: 'merchant-store-setup',
          builder: (context, state) {
            // Default: onboarding (used right after merchant signup).
            // Use `/merchant-store-setup?onboarding=false` to open as an editable
            // store profile screen that returns to previous page after save.
            final isOnboarding = state.uri.queryParameters['onboarding'] == 'false'
                ? false
                : true;
            return MerchantStoreSetupScreen(isOnboarding: isOnboarding);
          },
        ),

        // ========================================================================
        // PROFILE ROUTES
        // ========================================================================
        GoRoute(
          path: '/edit-profile',
          name: 'edit-profile',
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: '/payment-methods',
          name: 'payment-methods',
          builder: (context, state) => const PaymentMethodsScreen(),
        ),

        // ========================================================================
        // NOTIFICATION ROUTES
        // ========================================================================
        GoRoute(
          path: '/notifications',
          name: 'notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),

        // ========================================================================
        // CART & CHECKOUT ROUTES
        // ========================================================================
        GoRoute(
          path: '/cart',
          name: 'cart',
          builder: (context, state) => const CartScreen(),
        ),
        GoRoute(
          path: '/checkout',
          name: 'checkout',
          builder: (context, state) => const CheckoutScreen(),
        ),
        GoRoute(
          path: '/payment',
          name: 'payment',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is! PaymentCheckoutArgs) {
              return const Scaffold(
                body: Center(child: Text('Invalid checkout state')),
              );
            }
            return PaymentScreen(args: extra);
          },
        ),

        // ========================================================================
        // ORDER ROUTES
        // ========================================================================
        GoRoute(
          path: '/order-history',
          name: 'order-history',
          builder: (context, state) => const OrderHistoryScreen(),
        ),
        GoRoute(
          path: '/order-tracking/:orderId',
          name: 'order-tracking',
          builder: (context, state) {
            final orderId = state.pathParameters['orderId'] ?? '';
            return OrderTrackingScreen(orderId: orderId);
          },
        ),

        // ========================================================================
        // MARKETPLACE ROUTES
        // ========================================================================
        GoRoute(
          path: '/merchant/:merchantId/item/:itemId',
          name: 'food-item-detail',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is FoodItemModel) {
              return FoodItemDetailScreen(item: extra);
            }
            return const Scaffold(
              body: Center(child: Text('Missing item')),
            );
          },
        ),
        GoRoute(
          path: '/merchant/:merchantId',
          name: 'merchant-details',
          builder: (context, state) {
            final merchantId = state.pathParameters['merchantId'] ?? '';
            return MerchantDetailsScreen(merchantId: merchantId);
          },
        ),
        GoRoute(
          path: '/category/:category',
          name: 'category-listing',
          builder: (context, state) {
            final category = state.pathParameters['category'] ?? '';
            return CategoryListingScreen(category: category);
          },
        ),
      ],
    );
  }
}

