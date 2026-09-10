import 'package:flutter_test/flutter_test.dart';
import 'package:sos_app/models/breadcrumb_model.dart';

void main() {
  group('BreadcrumbModel Persistence Tests', () {
    test('Serializes to JSON and deserializes back correctly', () {
      final now = DateTime.now();
      final original = BreadcrumbModel(
        latitude: 28.6139,
        longitude: 77.2090,
        altitude: 215.5,
        speed: 3.2,
        heading: 180.0,
        accuracy: 4.5,
        timestamp: now,
      );

      final jsonStr = original.toJson();
      final restored = BreadcrumbModel.fromJson(jsonStr);

      expect(restored.latitude, closeTo(28.6139, 0.0001));
      expect(restored.longitude, closeTo(77.2090, 0.0001));
      expect(restored.altitude, closeTo(215.5, 0.0001));
      expect(restored.speed, closeTo(3.2, 0.0001));
      expect(restored.heading, closeTo(180.0, 0.0001));
      expect(restored.accuracy, closeTo(4.5, 0.0001));
      expect(restored.timestamp.millisecondsSinceEpoch,
          closeTo(now.millisecondsSinceEpoch, 1000));
    });

    test('Speed and movement mode computed properly after restoration', () {
      final model = BreadcrumbModel(
        latitude: 12.9716,
        longitude: 77.5946,
        speed: 5.0, // 5 m/s = 18 km/h -> Running / Cycling
        timestamp: DateTime.now(),
      );

      final jsonStr = model.toJson();
      final restored = BreadcrumbModel.fromJson(jsonStr);

      expect(restored.speedKmh, closeTo(18.0, 0.1));
      expect(restored.movementMode, 'Running / Cycling');
    });
  });
}
