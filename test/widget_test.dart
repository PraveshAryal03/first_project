import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:first_project/main.dart'; // Your app imports
import 'package:first_project/calorie_tracker_provider.dart'; // Your provider import

void main() {
  testWidgets('Calorie increments smoke test', (WidgetTester tester) async {
    // Wrap MyApp with ChangeNotifierProvider for the test environment
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => CalorieTrackerProvider(),
        child: const MyApp(),
      ),
    );

    // Verify counter starts at 0
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and rebuild the widget
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify counter incremented
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
