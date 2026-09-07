import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sos_app/widgets/terms_and_conditions_dialog.dart';

void main() {
  testWidgets('TermsAndConditionsDialog renders both tabs and accept button',
      (WidgetTester tester) async {
    bool accepted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TermsAndConditionsDialog(
            initialTabIndex: 0,
            showAcceptButton: true,
            onAccepted: () {
              accepted = true;
            },
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify Title and Tabs
    expect(find.text('Legal & Policies'), findsOneWidget);
    expect(find.text('Terms of Service'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);

    // Verify Content
    expect(find.text('Emergency Service Disclaimer'), findsOneWidget);
    expect(find.text('1. Acceptance of Terms'), findsOneWidget);

    // Switch to Privacy Policy tab
    await tester.tap(find.text('Privacy Policy'));
    await tester.pumpAndSettle();

    expect(find.text('Zero Data Selling Guarantee'), findsOneWidget);
    expect(find.text('1. Information We Collect'), findsOneWidget);

    // Tap Accept button
    expect(find.text('I Accept & Continue'), findsOneWidget);
    await tester.tap(find.text('I Accept & Continue'));
    await tester.pump();

    expect(accepted, isTrue);
  });
}
