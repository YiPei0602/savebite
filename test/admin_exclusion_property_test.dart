import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savebite/models/user_model.dart';
import 'package:savebite/screens/role_based_login_screen.dart';

void main() {
  group('Admin Role Exclusion Property Tests', () {
    testWidgets(
        'Property 3: Admin Role Excluded - '
        'Admin role button is not displayed on role-based login screen',
        (WidgetTester tester) async {
      // **Feature: landing-and-role-based-auth, Property 3: Admin Role Excluded**
      // **Validates: Requirements 4.1, 4.2, 4.3**

      await tester.pumpWidget(
        MaterialApp(
          home: const RoleBasedLoginScreen(),
        ),
      );

      // Verify admin-related text is not present
      expect(find.text('admin'), findsNothing);
      expect(find.text('Admin'), findsNothing);
      expect(find.text('I want to manage'), findsNothing);
      expect(find.text('I want to administer'), findsNothing);

      // Verify only consumer and merchant options are present
      expect(find.text('I want to buy'), findsOneWidget);
      expect(find.text('I want to sell'), findsOneWidget);
    });

    testWidgets(
        'Property 3: Admin Role Excluded - '
        'Admin role is not in UserRole enum',
        (WidgetTester tester) async {
      // **Feature: landing-and-role-based-auth, Property 3: Admin Role Excluded**
      // **Validates: Requirements 4.1, 4.2, 4.3**

      // Verify admin is not in UserRole enum
      final availableRoles = UserRole.values;

      expect(availableRoles, isNotEmpty);
      expect(availableRoles.contains(UserRole.consumer), true);
      expect(availableRoles.contains(UserRole.merchant), true);

      // Verify admin role does not exist
      final adminExists = availableRoles.any(
        (role) => role.toString() == 'UserRole.admin',
      );
      expect(adminExists, false);
    });

    testWidgets(
        'Property 3: Admin Role Excluded - '
        'Only two role buttons are displayed',
        (WidgetTester tester) async {
      // **Feature: landing-and-role-based-auth, Property 3: Admin Role Excluded**
      // **Validates: Requirements 4.1, 4.2, 4.3**

      await tester.pumpWidget(
        MaterialApp(
          home: const RoleBasedLoginScreen(),
        ),
      );

      // Count role buttons (buttons with descriptions)
      final buyButton = find.text('I want to buy');
      final sellButton = find.text('I want to sell');

      expect(buyButton, findsOneWidget);
      expect(sellButton, findsOneWidget);

      // Verify no third button exists
      final allGestureDetectors = find.byType(GestureDetector);
      // Should have: back button + 2 role buttons = 3 total
      expect(allGestureDetectors, findsWidgets);
    });

    testWidgets(
        'Property 3: Admin Role Excluded - '
        'Admin option is not accessible through any UI element',
        (WidgetTester tester) async {
      // **Feature: landing-and-role-based-auth, Property 3: Admin Role Excluded**
      // **Validates: Requirements 4.1, 4.2, 4.3**

      await tester.pumpWidget(
        MaterialApp(
          home: const RoleBasedLoginScreen(),
        ),
      );

      // Search for any admin-related text in the entire widget tree
      final adminText = find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data?.toLowerCase().contains('admin') ?? false),
      );

      expect(adminText, findsNothing);
    });

    testWidgets(
        'Property 3: Admin Role Excluded - '
        'Role buttons only contain consumer and merchant descriptions',
        (WidgetTester tester) async {
      // **Feature: landing-and-role-based-auth, Property 3: Admin Role Excluded**
      // **Validates: Requirements 4.1, 4.2, 4.3**

      await tester.pumpWidget(
        MaterialApp(
          home: const RoleBasedLoginScreen(),
        ),
      );

      // Verify descriptions are for consumer and merchant only
      expect(
        find.text('Browse and purchase surplus food'),
        findsOneWidget,
      );
      expect(
        find.text('List and sell your surplus food'),
        findsOneWidget,
      );

      // Verify no admin-related descriptions
      expect(find.text('Manage users'), findsNothing);
      expect(find.text('Administer system'), findsNothing);
      expect(find.text('Admin dashboard'), findsNothing);
    });

    testWidgets(
        'Property 3: Admin Role Excluded - '
        'UserRole enum contains only consumer, merchant, and ngo',
        (WidgetTester tester) async {
      // **Feature: landing-and-role-based-auth, Property 3: Admin Role Excluded**
      // **Validates: Requirements 4.1, 4.2, 4.3**

      final roles = UserRole.values;

      // Verify expected roles exist
      expect(roles.contains(UserRole.consumer), true);
      expect(roles.contains(UserRole.merchant), true);
      expect(roles.contains(UserRole.ngo), true);

      // Verify admin does not exist
      expect(
        roles.any((role) => role.toString().contains('admin')),
        false,
      );

      // Verify only 3 roles exist
      expect(roles.length, 3);
    });

    testWidgets(
        'Property 3: Admin Role Excluded - '
        'No hidden admin UI elements exist',
        (WidgetTester tester) async {
      // **Feature: landing-and-role-based-auth, Property 3: Admin Role Excluded**
      // **Validates: Requirements 4.1, 4.2, 4.3**

      await tester.pumpWidget(
        MaterialApp(
          home: const RoleBasedLoginScreen(),
        ),
      );

      // Search for any widget that might contain admin functionality
      final allText = find.byType(Text);
      final textWidgets = <String>[];

      for (int i = 0; i < allText.evaluate().length; i++) {
        final widget = tester.widget<Text>(allText.at(i));
        if (widget.data != null) {
          textWidgets.add(widget.data!.toLowerCase());
        }
      }

      // Verify no admin-related text exists
      final hasAdmin = textWidgets.any((text) => text.contains('admin'));
      expect(hasAdmin, false);
    });
  });
}
