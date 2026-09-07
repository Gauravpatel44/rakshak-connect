import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sos_app/screens/fake_call/fake_incoming_call_screen.dart';
import 'package:sos_app/services/fake_call_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FakeCallNotificationService Tests', () {
    test('Consumes pending launch payload cleanly', () {
      expect(FakeCallNotificationService.consumePendingLaunchPayload(), isNull);
    });

    test('Schedule state is initially idle', () {
      expect(FakeCallNotificationService.isCallScheduled, isFalse);
      expect(FakeCallNotificationService.scheduledSecondsRemaining, equals(0));
    });
  });

  group('FakeIncomingCallScreen Widget Tests', () {
    testWidgets('Renders Incoming Call UI in default mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FakeIncomingCallScreen(
            callerName: 'Police Control 🚓',
            callerNumber: '112',
            initialAnswered: false,
          ),
        ),
      );

      // Verify incoming call UI elements
      expect(find.text('INCOMING CALL'), findsOneWidget);
      expect(find.text('Police Control 🚓'), findsOneWidget);
      expect(find.text('112'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
      expect(find.byIcon(Icons.call_rounded), findsOneWidget);
      expect(find.byIcon(Icons.call_end_rounded), findsOneWidget);

      // Screen should be marked active
      expect(FakeIncomingCallScreen.isScreenActive, isTrue);
    });

    testWidgets('Renders Active Call UI directly when initialAnswered is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FakeIncomingCallScreen(
            callerName: 'Mom ❤️',
            callerNumber: '+91 98765 43210',
            initialAnswered: true,
          ),
        ),
      );

      // Incoming call elements should NOT appear
      expect(find.text('INCOMING CALL'), findsNothing);
      expect(find.text('Accept'), findsNothing);

      // Active call elements should appear
      expect(find.text('Mom ❤️'), findsOneWidget);
      expect(find.text('Mute'), findsOneWidget);
      expect(find.text('Keypad'), findsOneWidget);
      expect(find.text('Speaker'), findsOneWidget);
      expect(find.text('Hold'), findsOneWidget);
      expect(find.text('Add Call'), findsOneWidget);
      expect(find.text('Video'), findsOneWidget);

      // Verify Mute button toggles
      await tester.tap(find.text('Mute'));
      await tester.pump();
      expect(find.byIcon(Icons.mic_off_rounded), findsOneWidget);

      // Verify Speaker button toggles
      await tester.tap(find.text('Speaker'));
      await tester.pump();
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);

      // Verify Hold button toggles
      await tester.tap(find.text('Hold'));
      await tester.pump();
      expect(find.text('Call on hold'), findsOneWidget);
    });
  });
}
