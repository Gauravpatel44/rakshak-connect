import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' as osm;
import 'package:sos_app/services/routing_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('RoutingResult Model Tests', () {
    test('Formats distance always in kilometers', () {
      const resultMeters = RoutingResult(
        points: [osm.LatLng(28.6, 77.2), osm.LatLng(28.61, 77.21)],
        distanceMeters: 650.0,
        durationSeconds: 120.0,
        isFromRoadNetwork: true,
      );
      expect(resultMeters.distanceText, '0.7 km');

      const resultKm = RoutingResult(
        points: [osm.LatLng(28.6, 77.2), osm.LatLng(28.65, 77.25)],
        distanceMeters: 3450.0,
        durationSeconds: 600.0,
        isFromRoadNetwork: true,
      );
      expect(resultKm.distanceText, '3.5 km');
    });

    test('Formats duration correctly across minute and hour thresholds', () {
      const shortTrip = RoutingResult(
        points: [],
        distanceMeters: 200,
        durationSeconds: 45,
        isFromRoadNetwork: true,
      );
      expect(shortTrip.durationText, '~1 min');

      const mediumTrip = RoutingResult(
        points: [],
        distanceMeters: 4000,
        durationSeconds: 540, // 9 mins
        isFromRoadNetwork: true,
      );
      expect(mediumTrip.durationText, '~9 mins');

      const longTrip = RoutingResult(
        points: [],
        distanceMeters: 60000,
        durationSeconds: 4500, // 1h 15m
        isFromRoadNetwork: true,
      );
      expect(longTrip.durationText, '~1h 15m');
    });
  });

  group('RoutingService Tests', () {
    test('Synthesizes valid multi-waypoint road route for start and destination', () async {
      final service = RoutingService();
      const startLat = 28.6139;
      const startLng = 77.2090;
      const destLat = 28.6250;
      const destLng = 77.2180;

      final route = await service.getRoadRoute(
        startLat: startLat,
        startLng: startLng,
        destLat: destLat,
        destLng: destLng,
      );

      expect(route.points.length, greaterThanOrEqualTo(2));
      expect(route.distanceMeters, greaterThan(0));
      expect(route.durationSeconds, greaterThan(0));

      // Verify route connects start to destination
      final firstPoint = route.points.first;
      final lastPoint = route.points.last;

      expect(firstPoint.latitude, closeTo(startLat, 0.005));
      expect(firstPoint.longitude, closeTo(startLng, 0.005));
      expect(lastPoint.latitude, closeTo(destLat, 0.005));
      expect(lastPoint.longitude, closeTo(destLng, 0.005));
    });

    test('Decodes polyline strings accurately', () {
      // Standard Google/Mappls Polyline sample: (38.5, -120.2), (40.7, -120.95), (43.252, -126.453)
      const poly5 = '_p~iF~ps|U_ulLnnqC_mqNvxq`@';
      final decoded5 = RoutingService.decodePolyline(poly5, precision: 5);
      expect(decoded5.length, 3);
      expect(decoded5[0].latitude, closeTo(38.5, 0.001));
      expect(decoded5[0].longitude, closeTo(-120.2, 0.001));
      expect(decoded5[1].latitude, closeTo(40.7, 0.001));
      expect(decoded5[1].longitude, closeTo(-120.95, 0.001));
      expect(decoded5[2].latitude, closeTo(43.252, 0.001));
      expect(decoded5[2].longitude, closeTo(-126.453, 0.001));
    });
  });
}

