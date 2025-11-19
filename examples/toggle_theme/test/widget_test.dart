// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:toggle_theme/main.dart';

void main() {
  testWidgets(
    'Check that when the app is in light mode the icon button shows a moon, while in dark mode it shows a sun',
    (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const MyApp());

      // Icon finders
      Finder lightModeIcon() => find.byIcon(Icons.light_mode);
      Finder darkModeIcon() => find.byIcon(Icons.dark_mode);

      // Given that our theme starts at light mode
      // Verify that the toggle theme icon button shows the dark mode icon
      expect(darkModeIcon(), findsOneWidget);
      expect(lightModeIcon(), findsNothing);

      // Tap the icon button to toggle the theme mode and trigger a frame.
      await tester.tap(darkModeIcon());
      await tester.pump();

      // Verify that our theme has changed to 'dark' mode and the `light_mode` icon should be shown
      expect(lightModeIcon(), findsOneWidget);
      expect(darkModeIcon(), findsNothing);

      // Tap the icon button to toggle the theme mode and trigger a frame.
      await tester.tap(lightModeIcon());
      await tester.pump();

      // Verify that our theme has changed to 'light' mode and the `dark_mode` icon should be shown
      expect(darkModeIcon(), findsOneWidget);
      expect(lightModeIcon(), findsNothing);
    },
  );
}
