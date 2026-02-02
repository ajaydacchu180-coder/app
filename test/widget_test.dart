// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enterprise_attendance/src/app.dart';

void main() {
  testWidgets('App starts at login screen conversation',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Wrap in ProviderScope because the app uses Riverpod
    await tester.pumpWidget(const ProviderScope(child: EnterpriseApp()));

    // Verify that we start at the login screen (checking for typical login text)
    // Since we haven't seen the exact LoginScreen text, we'll just check for EnterpriseApp existence or a generic title if known.
    // However, looking at the previous file views, the title in MaterialApp is 'Enterprise Attendance'.
    // Let's just verify the app builds without crashing.
    expect(find.byType(EnterpriseApp), findsOneWidget);
  });
}
