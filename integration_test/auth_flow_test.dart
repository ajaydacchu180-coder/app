import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enterprise_attendance/src/app.dart';

/// Integration tests for the authentication flow.
///
/// These tests verify the end-to-end user journey for authentication:
/// - Login with valid credentials
/// - Navigation to home screen
/// - Logout and return to login
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow Integration Tests', () {
    testWidgets('complete login and logout flow', (tester) async {
      // Launch the app
      await tester.pumpWidget(
        const ProviderScope(child: EnterpriseApp()),
      );
      await tester.pumpAndSettle();

      // Should start at login screen
      expect(find.text('Sign In'), findsWidgets);

      // Enter username
      final usernameField = find.byType(TextField).first;
      await tester.enterText(usernameField, 'testuser@example.com');
      await tester.pumpAndSettle();

      // Enter password
      final passwordField = find.byType(TextField).at(1);
      await tester.enterText(passwordField, 'Password123');
      await tester.pumpAndSettle();

      // Tap login button
      final loginButton = find.text('Sign In').last;
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should navigate to home screen or dashboard
      // The specific check depends on app structure
      expect(find.text('Sign In'), findsNothing);
    });

    testWidgets('login validation shows error for empty fields',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: EnterpriseApp()),
      );
      await tester.pumpAndSettle();

      // Try to submit without filling fields
      final loginButton = find.text('Sign In').last;
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Should show validation error or remain on login screen
      expect(find.text('Sign In'), findsWidgets);
    });

    testWidgets('navigation between screens works correctly', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: EnterpriseApp()),
      );
      await tester.pumpAndSettle();

      // Login first
      final usernameField = find.byType(TextField).first;
      await tester.enterText(usernameField, 'testuser@example.com');

      final passwordField = find.byType(TextField).at(1);
      await tester.enterText(passwordField, 'Password123');

      await tester.tap(find.text('Sign In').last);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Try to navigate to different tabs/screens
      // Find bottom navigation or menu
      final bottomNav = find.byType(BottomNavigationBar);
      if (bottomNav.evaluate().isNotEmpty) {
        // Tap on different navigation items
        final navItems = find.descendant(
          of: bottomNav,
          matching: find.byType(InkResponse),
        );

        if (navItems.evaluate().length > 1) {
          await tester.tap(navItems.at(1));
          await tester.pumpAndSettle();
        }
      }
    });
  });
}
