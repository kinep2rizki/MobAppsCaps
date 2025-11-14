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

    // Verify that the localized login page shows the correct widgets.
    expect(find.text('Selamat datang'), findsOneWidget);
    expect(find.text('Masuk ke akun anda untuk Melanjutkan'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2)); // Email and password fields
    expect(find.widgetWithText(ElevatedButton, 'Masuk'), findsOneWidget);
    expect(find.text('Lupa Password?'), findsOneWidget);
    expect(find.textContaining('Belum punya akun?'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Daftar Sekarang!'), findsOneWidget);
  });
}
