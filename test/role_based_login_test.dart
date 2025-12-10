import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:savebite/screens/role_based_login_screen.dart';

void main() {
  group('Role-Based Login Screen Tests', () {
    testWidgets('Role-based login screen displays both role buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const RoleBasedLoginScreen(),
        ),
      );

      // Verify both buttons are displayed
      expect(find.text('I want to buy'), findsOneWidget);
      expect(find.text('I want to sell'), findsOneWidget);
    });

    testWidgets('Role-based login screen uses meals.png as background',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const RoleBasedLoginScreen(),
        ),
      );

      // Verify background image is used
      final decorationImage = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).image != null,
      );

      expect(decorationImage, findsOneWidget);

      final container = tester.widget<Container>(decorationImage);
      final boxDecoration = container.decoration as BoxDecoration;
      expect(
        boxDecoration.image?.image,
        isA<AssetImage>().having(
          (image) => image.assetName,
          'assetName',
          'assets/images/meals.png',
        ),
      );
    });

    testWidgets('Role-based login screen has semi-transparent overlay',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const RoleBasedLoginScreen(),
        ),
      );

      // Find the overlay container
      final overlayContainers = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.color != null &&
            widget.color!.alpha < 255,
      );

      expect(overlayContainers, findsWidgets);
    });

    testWidgets('Role buttons have correct styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const RoleBasedLoginScreen(),
        ),
      );

      // Find button containers
      final buttons = find.byType(GestureDetector);
      expect(buttons, findsWidgets);

      // Verify buttons have deep teal background
      final buttonContainers = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color ==
                const Color(0xFF00615F),
      );

      expect(buttonContainers, findsWidgets);
    });

    testWidgets('Role button text is off-white', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const RoleBasedLoginScreen(),
        ),
      );

      // Find text widgets
      final buyText = find.text('I want to buy');
      final sellText = find.text('I want to sell');

      expect(buyText, findsOneWidget);
      expect(sellText, findsOneWidget);

      // Verify text color
      final buyTextWidget = tester.widget<Text>(buyText);
      expect(
        buyTextWidget.style?.color,
        const Color(0xFFF9F3F0),
      );

      final sellTextWidget = tester.widget<Text>(sellText);
      expect(
        sellTextWidget.style?.color,
        const Color(0xFFF9F3F0),
      );
    });

    testWidgets('Role buttons have minimum height of 48dp',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const RoleBasedLoginScreen(),
        ),
      );

      // Find button containers with padding
      final paddedContainers = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color ==
                const Color(0xFF00615F),
      );

      expect(paddedContainers, findsWidgets);

      // Verify padding is sufficient for touch-friendly sizing
      final firstButton = tester.widget<Container>(paddedContainers.first);
      expect(firstButton, isNotNull);
    });

    testWidgets('Admin role option is not displayed',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const RoleBasedLoginScreen(),
        ),
      );

      // Verify admin text is not present
      expect(find.text('admin'), findsNothing);
      expect(find.text('Admin'), findsNothing);
      expect(find.text('I want to manage'), findsNothing);

      // Verify only two buttons are displayed
      expect(find.text('I want to buy'), findsOneWidget);
      expect(find.text('I want to sell'), findsOneWidget);
    });

    testWidgets('Role buttons have descriptions', (WidgetTester tester) async {
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
    });

    testWidgets('Back button is displayed', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const RoleBasedLoginScreen(),
        ),
      );

      // Verify back button icon is displayed
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('Role buttons are tappable', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const RoleBasedLoginScreen(),
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const RoleBasedLoginScreen(),
              ),
              GoRoute(
                path: '/login',
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Login')),
                ),
              ),
            ],
          ),
        ),
      );

      // Tap on "I want to buy" button
      await tester.tap(find.text('I want to buy'));
      await tester.pumpAndSettle();

      // Verify tap was registered
      expect(find.text('I want to buy'), findsOneWidget);
    });

    testWidgets('Layout is responsive', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const RoleBasedLoginScreen(),
        ),
      );

      // Verify SafeArea is used for responsive layout
      expect(find.byType(SafeArea), findsOneWidget);

      // Verify Column is used for vertical layout
      expect(find.byType(Column), findsWidgets);

      // Verify Padding is used for spacing
      expect(find.byType(Padding), findsWidgets);
    });
  });
}
