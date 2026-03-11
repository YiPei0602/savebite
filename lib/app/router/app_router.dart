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
import '../../features/merchant_management/presentation/screens/merchant_dashboard_screen.dart';
import '../../features/merchant_management/presentation/screens/add_surplus_screen.dart';
import '../../features/merchant_management/presentation/screens/merchant_orders_screen.dart';
import '../../features/auth_profile_impact/presentation/screens/edit_profile_screen.dart';
import '../../features/orders_payments/presentation/screens/payment_methods_screen.dart';
import '../../features/core_notifications/presentation/screens/notifications_screen.dart';
import '../../features/donations/presentation/screens/donation_prompt_screen.dart';
import '../../features/orders_payments/presentation/screens/cart_screen.dart';
import '../../features/orders_payments/presentation/screens/checkout_screen.dart';
import '../../features/orders_payments/presentation/screens/order_history_screen.dart';
import '../../features/orders/screens/order_tracking_screen.dart';
import '../../features/orders/screens/track_order_screen.dart';
import '../../features/marketplace_surplus/presentation/screens/merchant_details_screen.dart';
import '../../features/marketplace_surplus/presentation/screens/category_listing_screen.dart';

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
  '/donation-prompt',
];

const _consumerOnlyRoutePrefixes = [
  '/home',
  '/profile',
  '/impact',
  '/edit-profile',
  '/payment-methods',
  '/notifications',
  '/cart',
  '/checkout',
  '/order-history',
  '/order-tracking',
  '/track-order',
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
        final isAuthenticated = authProvider.isAuthenticated;
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

        if (!isAuthenticated) {
          // Not logged in: redirect protected routes to landing
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

        if (role == UserRole.merchant && isConsumerOnly) return _homeForRole(role);
        if (role == UserRole.consumer && isMerchantOnly) return _homeForRole(role);

        // Apply role rules to all remaining protected routes too:
        // any protected route must be explicitly categorized, otherwise redirect to role home.
        if (!isMerchantOnly && !isConsumerOnly) {
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
          builder: (context, state) => const HomeScreen(),
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
          builder: (context, state) => const MerchantDashboardScreen(),
        ),
        GoRoute(
          path: '/add-surplus',
          name: 'add-surplus',
          builder: (context, state) => const AddSurplusScreen(),
        ),
        GoRoute(
          path: '/merchant-orders',
          name: 'merchant-orders',
          builder: (context, state) => const MerchantOrdersScreen(),
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
        // DONATION ROUTES
        // ========================================================================
        GoRoute(
          path: '/donation-prompt',
          name: 'donation-prompt',
          builder: (context, state) => const DonationPromptScreen(),
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
        GoRoute(
          path: '/track-order',
          name: 'track-order',
          builder: (context, state) {
            // Get parameters from extra
            final extra = state.extra as Map<String, dynamic>?;
            if (extra != null) {
              return TrackOrderScreen(
                orderId: extra['orderId'] as String,
                cartItems:
                    extra['cartItems'] as Map<String, Map<String, dynamic>>,
                subtotal: extra['subtotal'] as double,
                totalSavings: extra['totalSavings'] as double,
                isSelfPickup: extra['isSelfPickup'] as bool,
                paymentMethod: extra['paymentMethod'] as String,
              );
            }
            // Fallback - should not happen
            return const Scaffold(
              body: Center(child: Text('Invalid order data')),
            );
          },
        ),

        // ========================================================================
        // MARKETPLACE ROUTES
        // ========================================================================
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

