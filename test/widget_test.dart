// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:netzlingo/main.dart';

void main() {
  testWidgets('NetzLingo app initialization test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NetzLingoApp());

    // Verifikasi bahwa aplikasi dimulai dengan benar
    expect(find.text('NetzLingo'), findsOneWidget);

    // Verifikasi bahwa tab Frasa ada
    expect(find.text('Frasa'), findsOneWidget);

    // Verifikasi bahwa tab Belajar ada
    expect(find.text('Belajar'), findsOneWidget);

    // Verifikasi bahwa tab Statistik ada
    expect(find.text('Statistik'), findsOneWidget);

    // Verifikasi bahwa tab Pengaturan ada
    expect(find.text('Pengaturan'), findsOneWidget);
  });
}
