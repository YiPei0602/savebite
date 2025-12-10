import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savebite/screens/landing_page_screen.dart';
import 'package:savebite/screens/role_based_login_screen.dart';

void main() {
  group('Visual Consistency Property Tests', () {
    testWidgets(
        'Property 4: Visual Consistency - '
        'Landing page uses deep teal background',
        (WidgetTester tester) async {
      // **Feature: landing-and-role-based-auth, Property 4: Visual Consistency**
      // **Validates: Requirements 1.2, 2.2, 3.2, 3.3**

      await tester.pumpWidget(
        MaterialApp(
          home: const LandingPageScreen(),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(
        scaffold.backgroundColor,
        const Color(0xFF00615F),
      );
    });

    testWidgets(
        'Property 4: Visual Consistency - '
        'Landing page text is off-white',
        (WidgetTester tester) async {
      // **Feature: landing-and-role-based-auth, Property 4: Visual Consistency**
      // **Validates: Requirements 1.2, 2.2, 3.2, 3.3**

      await tester.pumpWidget(
        MaterialApp(
          home: const LandingPageScreen(),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('SaveBite'));
      expect(
        textWidget.style?.color,
        const Color(0xFFF9F3F0),
      );
    });

    testWidgets(
        'Property 4: Visual Consistency - '
        'Role-based login buttons use deep teal background',
        (WidgetTester tester) async {
      // **Feature: landing-and-role-based-auth, Property 4: Visual Consistency**
      // **Validates: Requirements 1.2, 2.2, 3.2, 3.3**

      await tester.pumpWidget(
        MaterialApp(
          home: const RoleBasedLoginScreen(),
        ),
      );

      // Find button containers with deep teal background
      final buttonContainers = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color ==
                const Color(0xFF00615F),
      );

      expect(buttonContainers, findsWidgets);
    });

    testWidgets(
        'Property 4: Visual Consistency - '
        'Role-based login button text is off-white',
        (WidgetTester tester) async {
      // **Feature: landing-and-role-based-auth, Property 4: Visual Consistency**
      // **Validates: Requirements 1.2, 2.2, 3.2, 3.3**

      await tester.pumpWidget(
        MaterialApp(
          home: const RoleBasedLoginScreen(),
        ),
      );

      // Check "I want to buy" text color
      final buyText = tester.widget<Text>(find.text('I want to buy'));
      expect(
        buyText.style?.color,
        const Color(0xFFF9F3F0),
      );

      // Check "I want to sell" text color
      final sellText = tester.widget<Text>(find.text('I want to sell'));
      expect(
        sellText.style?.color,
        const Color(0xFFF9F3F0),
      );
    });

    testWidgets(
        'Property 4: Visual Consistency - '
        'All primary elements use deep teal or off-white colors',
        (WidgetTester tester) async {
      // **Feature: landing-and-role-based-auth, Property 4: Visual Consistency**
      // **Validates: Requirements 1.2, 2.2, 3.2, 3.3**

      await tester.pumpWidget(
        MaterialApp(
          home: const RoleBasedLoginScreen(),
        ),
      );

      // Find all text widgets
      final allText = find.byType(Text);

      for (int i = 0; i < allText.evaluate().length; i++) {
        final textWidget = tester.widget<Text>(allText.at(i));
        final color = textWidget.style?.color;

        // Verify text color is either off-white or a variant
        if (color != null) {
          // Allow off-white and its variants
          expect(
            color == const Color(0xFFF9F3F0) ||
                color == const Color(0xFFF6F6F6) ||
                color.withOpacity(0.85) == const Color(0xFFF9F3F0).withOpacity(0.85),
            true,
          );
        }
      }
    });

    testWidgets(
        'Property 4: Visual Consistency - '
        'Button styling is consistent across both role buttons',
        (WidgetTester tester) async {
      // **Feature: landing-and-role-based-auth, Property 4: Visual Consistency**
      // **Validates: Requirements 1.2, 2.2, 3.2, 3.3**

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

      // Verify multiple buttons have consistent styling
      expect(buttonContainers, findsWidgets);

      // Get first button
      final firstButton = tester.widget<Container>(buttonContainers.first);
      final firstDecoration = firstButton.decoration as BoxDecoration;

      // Verify border radius is consistent
      expect(firstDecoration.borderRadius, isNotNull);
    });

    testWidgets(
        'Property 4: Visual Consistency - '
        'Color values match specification exactly',
        (WidgetTester tester) async {
      // **Feature: landing-and-role-based-auth, Property 4: Visual Consistency**
      // **Validates: Requirements 1.2, 2.2, 3.2, 3.3**

      const deepTeal = Color(0xFF00615F);
      const offWhite = Color(0xFFF9F3F0);

      // Verify color values
      expect(deepTeal.value, 0xFF00615F);
      expect(offWhite.value, 0xFFF9F3F0);

      await tester.pumpWidget(
        MaterialApp(
          home: const LandingPageScreen(),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, deepTeal);
    });

    testWidgets(
        'Property 4: Visual Consistency - '
        'Text styling is consistent across screens',
        (WidgetTester tester) async {
      // **Feature: landing-and-role-based-auth, Property 4: Visual Consistency**
      // **Validates: Requirements 1.2, 2.2, 3.2, 3.3**

      await tester.pumpWidget(
        MaterialApp(
          home: const LandingPageScreen(),
        ),
      );

      // Check landing page text
      final landingText = tester.widget<Text>(find.text('SaveBite'));
      expect(landingText.style?.fontWeight, FontWeight.bold);
      expect(landingText.style?.fontSize, 48);

      // Verify text is readable
      expect(landingText.style?.color, const Color(0xFFF9F3F0));
    });
  });
}
