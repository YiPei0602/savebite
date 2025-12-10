import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/landing_page_screen.dart';
import '../../screens/role_based_login_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/marketplace/screens/marketplace_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/impact/screens/impact_dashboard_screen.dart';
import '../../features/merchant/screens/merchant_dashboard_screen.dart';
import '../../features/merchant/screens/add_surplus_screen.dart';
import '../../features/merchant/screens/merchant_orders_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/payment/screens/payment_methods_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/donation/screens/donation_prompt_screen.dart';

/// SaveBite App Router
/// 
/// Centralized routing configuration using go_router.
/// Includes auth-based redirects (placeholder for now).
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/landing',
    redirect: (BuildContext context, GoRouterState state) {
      // TODO: Implement auth-based redirects
      // Check if user is authenticated
      // Redirect to login if not authenticated and trying to access protected routes
      // Redirect to appropriate dashboard based on user role
      
      // For now, allow all navigation
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
        path: '/marketplace',
        name: 'marketplace',
        builder: (context, state) => const MarketplaceScreen(),
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
      // FEATURE ROUTES (To be added as features are developed)
      // ========================================================================
      // Additional features can be added here
    ],
  );
}
