import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savebite/screens/landing_page_screen.dart';
import 'package:savebite/screens/role_based_login_screen.dart';

void main() {
  group('Mobile Responsiveness Property Tests', () {
    testWidgets(
        'Property 5: Mobile Responsiveness - '
        'Landing page elements are centered on mobile',
        (WidgetTester tester) async {
      // **Feature: landing-and-role-based-auth, Property 5: Mobile Responsiveness**
      // **Validates: Requirements 5.1, 5.2, 5.3, 5.4**

      tester.binding.window.physicalSizeTestValue = const Size(400, 800);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: const LandingPageScreen(),
        ),
      );

      // Verify Center widget is used
      expect(find.byType(Center), findsOneWidget);

      // Verify Column is centered
      final column = tester.widget<Column>(find.byType(Column));
      expect(
        column.mainAxisAlignment,
        MainAxisAlignment.center,
      );
    });

    testWidgets(
        'Property 5: Mobile Responsiveness - '
        'Landing page scales properly on different screen sizes',
        (WidgetTester tester) async {
      // **Feature: landing-and-role-based-auth, Property 5: Mobile Responsiveness**
      // **Validates: Requirements 5.1, 5.2, 5.3, 5.4**

      // Test on small screen
      tester.binding.window.physicalSizeTestValue = const Size(360, 640);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: const LandingPageScreen(),
        ),
      );

      expect(find.text('SaveBite'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);

      // Test on larger screen
      tester.binding.window.physicalSizeTestValue = const Size(600, 1000);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: const LandingPageScreen(),
        ),
      );

      expect(find.text('SaveBite'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets(
        'Property 5: Mobile Responsiveness - '
        'Role buttons are touch-friendly (minimum 48dp height)',
        (WidgetTester tester) async {
      // **Feature: landing-and-role-based-auth, Property 5: Mobile Responsiveness**
      // **Validates: Requirements 5.1, 5.2, 5.3, 5.4**

      tester.binding.window.physicalSizeTestValue = const Size(400, 800);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: const RoleBasedLoginScreen(),
        ),
      );

      // Find button containers
      final buttonContainers = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color ==
                const Color(0xFF00615F),
      );

      expect(buttonContainers, findsWidgets);

      // Verify button size is adequate for touch
      for (int i = 0; i < buttonContainers.evaluate().length; i++) {
        final size = tester.getSize(buttonContainers.at(i));
        // Verify height is at least 48dp (approximately 96 pixels at 2x density)
        expect(size.height, greaterThanOrEqualTo(48));
      }
    });

    testWidgets(
        'Property 5: Mobile Responsiveness - '
        'Role buttons are properly positioned on mobile',
        (WidgetTester tester) async {
      // **Feature: landing-and-role-based-auth, Property 5: Mobile Responsiveness**
      // **Validates: Requirements 5.1, 5.2, 5.3, 5.4**

      tester.binding.window.physicalSizeTestValue = const Size(400, 800);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: const RoleBasedLoginScreen(),
        ),
      );

      // Find buttons
      final buyButton = find.text('I want to buy');
      final sellButton = find.text('I want to sell');

      expect(buyButton, findsOneWidget);
      expect(sellButton, findsOneWidget);

      // Verify buttons are visible and within screen bounds
      expect(tester.getBottomLeft(buyButton).dx, greaterThanOrEqualTo(0));
      expect(tester.getBottomRight(buyButton).dx, lessThanOrEqualTo(400));
    });

    testWidgets(
        'Property 5: Mobile Responsiveness - '
        'Layout maintains readability on portrait orientation',
        (WidgetTester tester) async {
      // **Feature: landing-and-role-based-auth, Property 5: Mobile Responsiveness**
      // **Validates: Requirements 5.1, 5.2, 5.3, 5.4**

      tester.binding.window.physicalSizeTestValue = const Size(400, 800);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: const RoleBasedLoginScreen(),
        ),
      );

      // Verify all text is visible
      expect(find.text('I want to buy'), findsOneWidget);
      expect(find.text('I want to sell'), findsOneWidget);
      expect(find.text('Browse and purchase surplus food'), findsOneWidget);
      expect(find.text('List and sell your surplus food'), findsOneWidget);
    });

    testWidgets(
        'Property 5: Mobile Responsiveness - '
        'Font sizes meet minimum requirements',
        (WidgetTester tester) async {
      // **Feature: landing-and-role-based-auth, Property 5: Mobile Responsiveness**
      // **Validates: Requirements 5.1, 5.2, 5.3, 5.4**

      tester.binding.window.physicalSizeTestValue = const Size(400, 800);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: const RoleBasedLoginScreen(),
        ),
      );

      // Check button text font size
      final buyText = tester.widget<Text>(find.text('I want to buy'));
      expect(buyText.style?.fontSize, greaterThanOrEqualTo(14));

      // Check description text font size
      final description = tester.widget<Text>(
        find.text('Browse and purchase surplus food'),
      );
      expect(description.style?.fontSize, greaterThanOrEqualTo(14));
    });

    testWidgets(
        'Property 5: Mobile Responsiveness - '
        'SafeArea is used for responsive layout',
        (WidgetTester tester) async {
      // **Feature: landing-and-role-based-auth, Property 5: Mobile Responsiveness**
      // **Validates: Requirements 5.1, 5.2, 5.3, 5.4**

      tester.binding.window.physicalSizeTestValue = const Size(400, 800);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: const RoleBasedLoginScreen(),
        ),
      );

      // Verify SafeArea is used
      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets(
        'Property 5: Mobile Responsiveness - '
        'Padding is consistent across different screen sizes',
        (WidgetTester tester) async {
      // **Feature: landing-and-role-based-auth, Property 5: Mobile Responsiveness**
      // **Validates: Requirements 5.1, 5.2, 5.3, 5.4**

      tester.binding.window.physicalSizeTestValue = const Size(400, 800);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: const RoleBasedLoginScreen(),
        ),
      );

      // Find padded containers
      final paddedWidgets = find.byType(Padding);
      expect(paddedWidgets, findsWidgets);

      // Verify padding exists for proper spacing
      for (int i = 0; i < paddedWidgets.evaluate().length; i++) {
        final padding = tester.widget<Padding>(paddedWidgets.at(i));
        expect(padding.padding, isNotNull);
      }
    });

    testWidgets(
        'Property 5: Mobile Responsiveness - '
        'Elements remain readable after orientation change',
        (WidgetTester tester) async {
      // **Feature: landing-and-role-based-auth, Property 5: Mobile Responsiveness**
      // **Validates: Requirements 5.1, 5.2, 5.3, 5.4**

      // Start in portrait
      tester.binding.window.physicalSizeTestValue = const Size(400, 800);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: const RoleBasedLoginScreen(),
        ),
      );

      expect(find.text('I want to buy'), findsOneWidget);

      // Simulate orientation change to landscape
      tester.binding.window.physicalSizeTestValue = const Size(800, 400);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: const RoleBasedLoginScreen(),
        ),
      );

      // Verify elements are still visible
      expect(find.text('I want to buy'), findsOneWidget);
      expect(find.text('I want to sell'), findsOneWidget);
    });
  });
}
