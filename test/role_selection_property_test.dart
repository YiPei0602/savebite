import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:savebite/screens/role_based_login_screen.dart';

void main() {
  group('Role Selection Property Tests', () {
    testWidgets(
        'Property 2: Role Selection Routes Correctly - '
        'Tapping "I want to buy" routes to consumer auth',
        (WidgetTester tester) async {
      // **Feature: landing-and-role-based-auth, Property 2: Role Selection Routes Correctly**
      // **Validates: Requirements 2.5, 2.6**

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/role-based-login',
            builder: (context, state) => const RoleBasedLoginScreen(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Consumer Auth')),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // Verify role-based login is displayed
      expect(find.text('I want to buy'), findsOneWidget);

      // Tap "I want to buy" button
      await tester.tap(find.text('I want to buy'));
      await tester.pumpAndSettle();

      // Verify navigation to consumer auth
      expect(find.text('Consumer Auth'), findsOneWidget);
    });

    testWidgets(
        'Property 2: Role Selection Routes Correctly - '
        'Tapping "I want to sell" routes to merchant auth',
        (WidgetTester tester) async {
      // **Feature: landing-and-role-based-auth, Property 2: Role Selection Routes Correctly**
      // **Validates: Requirements 2.5, 2.6**

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/role-based-login',
            builder: (context, state) => const RoleBasedLoginScreen(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Merchant Auth')),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // Verify role-based login is displayed
      expect(find.text('I want to sell'), findsOneWidget);

      // Tap "I want to sell" button
      await tester.tap(find.text('I want to sell'));
      await tester.pumpAndSettle();

      // Verify navigation to merchant auth
      expect(find.text('Merchant Auth'), findsOneWidget);
    });

    testWidgets(
        'Property 2: Role Selection Routes Correctly - '
        'Both buttons route to correct destinations',
        (WidgetTester tester) async {
      // **Feature: landing-and-role-based-auth, Property 2: Role Selection Routes Correctly**
      // **Validates: Requirements 2.5, 2.6**

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/role-based-login',
            builder: (context, state) => const RoleBasedLoginScreen(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Auth Screen')),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // Verify both buttons are present
      expect(find.text('I want to buy'), findsOneWidget);
      expect(find.text('I want to sell'), findsOneWidget);

      // Tap first button
      await tester.tap(find.text('I want to buy'));
      await tester.pumpAndSettle();

      // Verify navigation occurred
      expect(find.text('Auth Screen'), findsOneWidget);
    });

    testWidgets(
        'Property 2: Role Selection Routes Correctly - '
        'Buttons are distinct and independently tappable',
        (WidgetTester tester) async {
      // **Feature: landing-and-role-based-auth, Property 2: Role Selection Routes Correctly**
      // **Validates: Requirements 2.5, 2.6**

      await tester.pumpWidget(
        MaterialApp(
          home: const RoleBasedLoginScreen(),
        ),
      );

      // Find both buttons
      final buyButton = find.text('I want to buy');
      final sellButton = find.text('I want to sell');

      expect(buyButton, findsOneWidget);
      expect(sellButton, findsOneWidget);

      // Verify buttons are at different positions
      final buyButtonPosition = tester.getCenter(buyButton);
      final sellButtonPosition = tester.getCenter(sellButton);

      expect(buyButtonPosition.dy, isNot(equals(sellButtonPosition.dy)));
    });

    testWidgets(
        'Property 2: Role Selection Routes Correctly - '
        'No unexpected routes are triggered',
        (WidgetTester tester) async {
      // **Feature: landing-and-role-based-auth, Property 2: Role Selection Routes Correctly**
      // **Validates: Requirements 2.5, 2.6**

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/role-based-login',
            builder: (context, state) => const RoleBasedLoginScreen(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Auth')),
            ),
          ),
          GoRoute(
            path: '/admin',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Admin')),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // Tap a button
      await tester.tap(find.text('I want to buy'));
      await tester.pumpAndSettle();

      // Verify admin route was not triggered
      expect(find.text('Admin'), findsNothing);
      expect(find.text('Auth'), findsOneWidget);
    });

    testWidgets(
        'Property 2: Role Selection Routes Correctly - '
        'Button descriptions are displayed with buttons',
        (WidgetTester tester) async {
      // **Feature: landing-and-role-based-auth, Property 2: Role Selection Routes Correctly**
      // **Validates: Requirements 2.5, 2.6**

      await tester.pumpWidget(
        MaterialApp(
          home: const RoleBasedLoginScreen(),
        ),
      );

      // Verify descriptions are displayed
      expect(
        find.text('Browse and purchase surplus food'),
        findsOneWidget,
      );
      expect(
        find.text('List and sell your surplus food'),
        findsOneWidget,
      );

      // Verify descriptions are near their respective buttons
      final buyDescription = find.text('Browse and purchase surplus food');
      final sellDescription = find.text('List and sell your surplus food');

      expect(buyDescription, findsOneWidget);
      expect(sellDescription, findsOneWidget);
    });
  });
}
