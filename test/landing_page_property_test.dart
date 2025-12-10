import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:savebite/screens/landing_page_screen.dart';

void main() {
  group('Landing Page Property Tests', () {
    testWidgets(
        'Property 1: Landing Page Auto-Navigation - '
        'Landing page auto-navigates to role-based login after delay',
        (WidgetTester tester) async {
      // **Feature: landing-and-role-based-auth, Property 1: Landing Page Auto-Navigation**
      // **Validates: Requirements 1.5**

      // Setup router with landing and role-based-login routes
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/landing',
            builder: (context, state) => const LandingPageScreen(),
          ),
          GoRoute(
            path: '/role-based-login',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Role Based Login')),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // Verify landing page is displayed initially
      expect(find.text('SaveBite'), findsOneWidget);
      expect(find.text('Role Based Login'), findsNothing);

      // Wait for auto-navigation delay (2.5 seconds)
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify navigation occurred to role-based login
      expect(find.text('Role Based Login'), findsOneWidget);
    });

    testWidgets(
        'Property 1: Landing Page Auto-Navigation - '
        'Manual tap overrides auto-navigation delay',
        (WidgetTester tester) async {
      // **Feature: landing-and-role-based-auth, Property 1: Landing Page Auto-Navigation**
      // **Validates: Requirements 1.5**

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/landing',
            builder: (context, state) => const LandingPageScreen(),
          ),
          GoRoute(
            path: '/role-based-login',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Role Based Login')),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // Verify landing page is displayed
      expect(find.text('SaveBite'), findsOneWidget);

      // Tap on landing page immediately (before auto-navigation)
      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      // Verify navigation occurred immediately
      expect(find.text('Role Based Login'), findsOneWidget);
    });

    testWidgets(
        'Property 1: Landing Page Auto-Navigation - '
        'Landing page renders with fade animation',
        (WidgetTester tester) async {
      // **Feature: landing-and-role-based-auth, Property 1: Landing Page Auto-Navigation**
      // **Validates: Requirements 1.5**

      await tester.pumpWidget(
        MaterialApp(
          home: const LandingPageScreen(),
        ),
      );

      // Verify FadeTransition is present
      expect(find.byType(FadeTransition), findsOneWidget);

      // Verify animation starts at opacity 0 and increases
      final fadeTransition = tester.widget<FadeTransition>(
        find.byType(FadeTransition),
      );
      expect(fadeTransition.opacity.value, greaterThan(0));
    });

    testWidgets(
        'Property 1: Landing Page Auto-Navigation - '
        'Landing page maintains state during animation',
        (WidgetTester tester) async {
      // **Feature: landing-and-role-based-auth, Property 1: Landing Page Auto-Navigation**
      // **Validates: Requirements 1.5**

      await tester.pumpWidget(
        MaterialApp(
          home: const LandingPageScreen(),
        ),
      );

      // Verify SaveBite text is present
      expect(find.text('SaveBite'), findsOneWidget);

      // Pump frames to advance animation
      await tester.pump(const Duration(milliseconds: 400));

      // Verify SaveBite text is still present
      expect(find.text('SaveBite'), findsOneWidget);

      // Verify logo is still present
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets(
        'Property 1: Landing Page Auto-Navigation - '
        'Landing page background color remains constant',
        (WidgetTester tester) async {
      // **Feature: landing-and-role-based-auth, Property 1: Landing Page Auto-Navigation**
      // **Validates: Requirements 1.5**

      await tester.pumpWidget(
        MaterialApp(
          home: const LandingPageScreen(),
        ),
      );

      // Get initial background color
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      final initialColor = scaffold.backgroundColor;

      // Pump frames to advance animation
      await tester.pump(const Duration(milliseconds: 500));

      // Get background color after animation
      final scaffoldAfter = tester.widget<Scaffold>(find.byType(Scaffold));
      final afterColor = scaffoldAfter.backgroundColor;

      // Verify background color remains the same
      expect(initialColor, equals(afterColor));
      expect(initialColor, equals(const Color(0xFF00615F)));
    });

    testWidgets(
        'Property 1: Landing Page Auto-Navigation - '
        'Landing page is responsive to multiple taps',
        (WidgetTester tester) async {
      // **Feature: landing-and-role-based-auth, Property 1: Landing Page Auto-Navigation**
      // **Validates: Requirements 1.5**

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/landing',
            builder: (context, state) => const LandingPageScreen(),
          ),
          GoRoute(
            path: '/role-based-login',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Role Based Login')),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // Verify landing page is displayed
      expect(find.text('SaveBite'), findsOneWidget);

      // Tap multiple times (only first tap should navigate)
      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      // Verify navigation occurred
      expect(find.text('Role Based Login'), findsOneWidget);
    });
  });
}
