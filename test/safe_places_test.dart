import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sos_app/models/safe_place_model.dart';
import 'package:sos_app/services/safe_places_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('SafePlaceModel & SafePlacesService Tests', () {
    const userLat = 28.6139;
    const userLng = 77.2090;

    test('SafePlacesService returns places sorted closest first', () {
      final service = SafePlacesService();
      final places = service.getNearbySafePlaces(userLat: userLat, userLng: userLng);

      expect(places.isNotEmpty, isTrue);
      expect(places.length, 7);

      // Verify sorted order by distance
      for (int i = 0; i < places.length - 1; i++) {
        final distCurrent = Geolocator.distanceBetween(
          userLat, userLng, places[i].latitude, places[i].longitude,
        );
        final distNext = Geolocator.distanceBetween(
          userLat, userLng, places[i + 1].latitude, places[i + 1].longitude,
        );
        expect(distCurrent <= distNext, isTrue);
      }
    });

    test('Filters by category correctly', () {
      final service = SafePlacesService();
      final policePlaces = service.getNearbySafePlaces(
        userLat: userLat,
        userLng: userLng,
        filterType: SafePlaceType.police,
      );

      expect(policePlaces.every((p) => p.type == SafePlaceType.police), isTrue);
      expect(policePlaces.length, 3);

      final hospitalPlaces = service.getNearbySafePlaces(
        userLat: userLat,
        userLng: userLng,
        filterType: SafePlaceType.hospital,
      );
      expect(hospitalPlaces.every((p) => p.type == SafePlaceType.hospital), isTrue);
      expect(hospitalPlaces.length, 2);
    });

    test('Format distance correctly in kilometers', () {
      expect(SafePlacesService.formatDistance(350), '0.3 km');
      expect(SafePlacesService.formatDistance(999), '1.0 km');
      expect(SafePlacesService.formatDistance(1000), '1.0 km');
      expect(SafePlacesService.formatDistance(2450), '2.5 km');
    });

    test('SafePlaceModel metadata and visual helpers return expected values', () {
      const place = SafePlaceModel(
        id: 'test_1',
        name: 'Test Police Station',
        type: SafePlaceType.police,
        latitude: 28.6,
        longitude: 77.2,
        phoneNumber: '112',
        address: 'Test Address',
      );

      expect(place.typeLabel, 'Police');
      expect(place.icon, isNotNull);
      expect(place.color, isNotNull);
      expect(place.is24x7, isTrue);
    });

    test('fetchRealMapplsSafePlaces falls back seamlessly to emergency points when offline', () async {
      final service = SafePlacesService();
      final places = await service.fetchRealMapplsSafePlaces(userLat: userLat, userLng: userLng);
      expect(places.isNotEmpty, isTrue);
      expect(places.length, 7);
    });
  });
}
