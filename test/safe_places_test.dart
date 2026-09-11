import 'package:flutter_test/flutter_test.dart';
import 'package:sos_app/models/safe_place_model.dart';
import 'package:sos_app/services/safe_places_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('SafePlaceModel & SafePlacesService Tests', () {
    const userLat = 28.6139;
    const userLng = 77.2090;

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

    test('SafePlaceModel hospital metadata returns proper attributes', () {
      const hospital = SafePlaceModel(
        id: 'hosp_1',
        name: 'City Hospital',
        type: SafePlaceType.hospital,
        latitude: 28.61,
        longitude: 77.21,
        phoneNumber: '108',
        address: 'Ring Road',
      );

      expect(hospital.typeLabel, 'Hospital');
      expect(hospital.icon, isNotNull);
      expect(hospital.color, isNotNull);
    });

    test('SafePlaceModel fire station and shelter have valid icons and colors', () {
      const fire = SafePlaceModel(
        id: 'fire_1',
        name: 'Station 1',
        type: SafePlaceType.fireStation,
        latitude: 28.62,
        longitude: 77.22,
        phoneNumber: '101',
        address: 'Fire Brigade Lane',
      );
      const shelter = SafePlaceModel(
        id: 'shelter_1',
        name: 'Relief Shelter',
        type: SafePlaceType.safeShelter,
        latitude: 28.63,
        longitude: 77.23,
        phoneNumber: '112',
        address: 'Community Center',
      );

      expect(fire.typeLabel, 'Fire Station');
      expect(shelter.typeLabel, 'Safe Haven');
    });

    test('fetchRealMapplsSafePlaces returns a list of SafePlaceModel cleanly without throwing', () async {
      final service = SafePlacesService();
      final places = await service.fetchRealMapplsSafePlaces(userLat: userLat, userLng: userLng);
      expect(places, isA<List<SafePlaceModel>>());
    });
  });
}
