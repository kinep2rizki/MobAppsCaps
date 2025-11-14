// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Login page UI test when not logged in', (WidgetTester tester) async {
    // Set up mock SharedPreferences. For this test, we simulate that the user is not logged in.
    SharedPreferences.setMockInitialValues({'isLoggedIn': false});

    // Build our app and trigger a frame.
    // We pass isLoggedIn: false to ensure the app starts on the LoginPage.
    await tester.pumpWidget(const MyApp(isLoggedIn: false));

    // Verify that the login page shows the correct widgets.
    expect(find.text('Login'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2)); // Expect two text fields for email and password
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text('Not a member?'), findsOneWidget);
  });
}
