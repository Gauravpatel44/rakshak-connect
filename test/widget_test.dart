// Basic Flutter widget test for RakshakConnect SOS app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:sos_app/main.dart';

void main() {
  testWidgets('App smoke test - RakshakConnectApp renders', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RakshakConnectApp());

    // Allow async initialization (e.g. providers) to settle.
    await tester.pumpAndSettle();

    // Verify the app renders at least one widget.
    expect(find.byType(RakshakConnectApp), findsOneWidget);
  });
}
