import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savebite/screens/landing_page_screen.dart';

void main() {
  group('Landing Page Tests', () {
    testWidgets('Landing page renders with correct background color',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const LandingPageScreen(),
        ),
      );

      // Verify background color is deep teal
      final scaffold = find.byType(Scaffold);
      expect(scaffold, findsOneWidget);

      final scaffoldWidget = tester.widget<Scaffold>(scaffold);
      expect(
        scaffoldWidget.backgroundColor,
        const Color(0xFF00615F),
      );

      // Pump to clear timers
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('Landing page displays logo', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const LandingPageScreen(),
        ),
      );

      // Verify logo image is displayed
      final logoImage = find.byType(Image);
      expect(logoImage, findsOneWidget);

      final imageWidget = tester.widget<Image>(logoImage);
      expect(
        imageWidget.image,
        isA<AssetImage>().having(
          (image) => image.assetName,
          'assetName',
          'assets/images/logo.png',
        ),
      );

      // Pump to clear timers
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('Landing page displays SaveBite text in off-white',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const LandingPageScreen(),
        ),
      );

      // Verify SaveBite text is displayed
      final textFinder = find.text('SaveBite');
      expect(textFinder, findsOneWidget);

      // Verify text color is off-white
      final textWidget = tester.widget<Text>(textFinder);
      expect(
        textWidget.style?.color,
        const Color(0xFFF9F3F0),
      );

      // Pump to clear timers
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('Landing page text has correct styling',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const LandingPageScreen(),
        ),
      );

      final textFinder = find.text('SaveBite');
      final textWidget = tester.widget<Text>(textFinder);

      expect(textWidget.style?.fontSize, 48);
      expect(textWidget.style?.fontWeight, FontWeight.bold);

      // Pump to clear timers
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('Landing page has fade animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const LandingPageScreen(),
        ),
      );

      // Verify FadeTransition is present
      expect(find.byType(FadeTransition), findsOneWidget);

      // Pump to clear timers
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('Landing page elements are centered',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const LandingPageScreen(),
        ),
      );

      // Pump once to render
      await tester.pump();

      // Verify Center widget is used
      expect(find.byType(Center), findsOneWidget);

      // Verify Column is centered
      final column = find.byType(Column);
      expect(column, findsOneWidget);

      final columnWidget = tester.widget<Column>(column);
      expect(
        columnWidget.mainAxisAlignment,
        MainAxisAlignment.center,
      );

      // Pump to clear any pending timers
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });
  });
}
