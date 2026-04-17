// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/main.dart';
import 'package:my_app/pages/HomePage.dart';
import 'package:my_app/pages/ProfilePages/RiwayatData.dart';
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

  testWidgets('Home page loads sensor data and refreshes automatically', (WidgetTester tester) async {
    int callCount = 0;

    Future<List<dynamic>> fakeSensorSource() async {
      callCount++;

      if (callCount == 1) {
        return [
          {
            'temperature': 30.0,
            'turbidity': 42.0,
            'ph': 7.3,
            'do': 6.8,
            'ammonia': 0.15,
          }
        ];
      }

      return [
        {
          'temperature': 31.0,
          'turbidity': 45.0,
          'ph': 7.1,
          'do': 6.5,
          'ammonia': 0.22,
        }
      ];
    }

    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(fetchSensorData: fakeSensorSource),
      ),
    );

    await tester.pump();

    expect(find.text('30.0°C'), findsOneWidget);
    expect(find.text('42.0 NTU'), findsOneWidget);
    expect(find.text('7.30'), findsOneWidget);
    expect(find.text('6.8 mg/L'), findsOneWidget);
    expect(find.textContaining('0.15 mg/L'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump();

    expect(find.text('31.0°C'), findsOneWidget);
    expect(find.text('45.0 NTU'), findsOneWidget);
    expect(find.text('7.10'), findsOneWidget);
    expect(find.text('6.5 mg/L'), findsOneWidget);
    expect(find.textContaining('0.22 mg/L'), findsOneWidget);
    expect(callCount, greaterThanOrEqualTo(2));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('Riwayat chart uses metric keys from API response', (WidgetTester tester) async {
    Future<List<dynamic>> fakeSensorSource() async {
      return [
        {
          'temperature': 28.2,
          'ph': 7.10,
          'do': 6.7,
          'ammonia': 0.18,
        },
        {
          'temperature': 28.5,
          'ph': 7.22,
          'do': 6.9,
          'ammonia': 0.20,
        },
      ];
    }

    await tester.pumpWidget(
      MaterialApp(
        home: RiwayatDataPage(fetchSensorData: fakeSensorSource),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Parameter aktif:'), findsOneWidget);
    expect(find.text('Suhu'), findsWidgets);

    await tester.ensureVisible(find.text('Amonia').first);
    await tester.tap(find.text('Amonia').first);
    await tester.pumpAndSettle();

    expect(find.text('Parameter aktif: Amonia'), findsOneWidget);
    expect(find.textContaining('Nilai terbaru:'), findsOneWidget);
  });
}
