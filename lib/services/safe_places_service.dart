import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mappls_gl/mappls_gl.dart' as mappls;
import '../models/safe_place_model.dart';

/// Service providing nearby verified safe places around the user's live coordinates
/// using real Mappls (MapmyIndia) Nearby POI API and OpenStreetMap Overpass API.
/// Never uses hardcoded mock locations.
class SafePlacesService {
  // In-memory cache keyed by rounded coordinates bucket (~500m) and category
  static final Map<String, (DateTime, List<SafePlaceModel>)> _cache = {};

  /// Asynchronously fetch real nearby emergency hubs via Mappls Nearby API
  /// with OpenStreetMap Overpass real data fallback. Returns empty list if none found.
  Future<List<SafePlaceModel>> fetchRealMapplsSafePlaces({
    required double userLat,
    required double userLng,
    SafePlaceType? filterType,
  }) async {
    final coordKey = '${(userLat * 200).round() / 200}_${(userLng * 200).round() / 200}';
    final allBucketKey = '${coordKey}_all';
    final bucketKey = '${coordKey}_${filterType?.name ?? 'all'}';

    // 1. Direct bucket cache hit
    if (_cache.containsKey(bucketKey)) {
      final (cachedAt, places) = _cache[bucketKey]!;
      if (DateTime.now().difference(cachedAt).inMinutes < 10 && places.isNotEmpty) {
        return places;
      }
    }

    // 2. Cascading cache hit: If 'all' bucket is already cached, filter from it immediately (0ms latency)
    if (filterType != null && _cache.containsKey(allBucketKey)) {
      final (cachedAt, allPlaces) = _cache[allBucketKey]!;
      if (DateTime.now().difference(cachedAt).inMinutes < 10 && allPlaces.isNotEmpty) {
        final filtered = allPlaces.where((p) => p.type == filterType).toList();
        if (filtered.isNotEmpty) {
          _cache[bucketKey] = (cachedAt, filtered);
          return filtered;
        }
      }
    }

    try {
      final List<SafePlaceModel> fetchedPlaces = [];

      if (filterType != null) {
        final keyword = _keywordForType(filterType);
        final results = await _queryMapplsCategory(keyword, filterType, userLat, userLng);
        if (results.isNotEmpty) {
          fetchedPlaces.addAll(results);
        } else {
          // Secondary real query via OpenStreetMap Overpass API
          final osmResults = await _queryOverpassCategory(filterType, userLat, userLng);
          fetchedPlaces.addAll(osmResults);
        }
      } else {
        // Fetch all 4 emergency types concurrently via Mappls
        final futurePolice = _queryMapplsCategory('police', SafePlaceType.police, userLat, userLng);
        final futureHospital = _queryMapplsCategory('hospital', SafePlaceType.hospital, userLat, userLng);
        final futureFire = _queryMapplsCategory('fire station', SafePlaceType.fireStation, userLat, userLng);
        final futureShelter = _queryMapplsCategory('shelter', SafePlaceType.safeShelter, userLat, userLng);

        final results = await Future.wait([futurePolice, futureHospital, futureFire, futureShelter]);
        for (final list in results) {
          fetchedPlaces.addAll(list);
        }

        // If Mappls returns empty, query real OpenStreetMap Overpass API
        if (fetchedPlaces.isEmpty) {
          final osmPolice = _queryOverpassCategory(SafePlaceType.police, userLat, userLng);
          final osmHospital = _queryOverpassCategory(SafePlaceType.hospital, userLat, userLng);
          final osmFire = _queryOverpassCategory(SafePlaceType.fireStation, userLat, userLng);
          final osmShelter = _queryOverpassCategory(SafePlaceType.safeShelter, userLat, userLng);

          final osmResults = await Future.wait([osmPolice, osmHospital, osmFire, osmShelter]);
          for (final list in osmResults) {
            fetchedPlaces.addAll(list);
          }
        }
      }

      if (fetchedPlaces.isNotEmpty) {
        // Deduplicate places by ID and spatial coordinates (~10m)
        final seenIds = <String>{};
        final seenCoords = <String>{};
        final List<SafePlaceModel> uniquePlaces = [];

        for (final p in fetchedPlaces) {
          final coordHash = '${(p.latitude * 1000).round()}_${(p.longitude * 1000).round()}';
          if (!seenIds.contains(p.id) && !seenCoords.contains(coordHash)) {
            seenIds.add(p.id);
            seenCoords.add(coordHash);
            uniquePlaces.add(p);
          }
        }

        // Sort closest to user first
        uniquePlaces.sort((a, b) {
          final distA = Geolocator.distanceBetween(userLat, userLng, a.latitude, a.longitude);
          final distB = Geolocator.distanceBetween(userLat, userLng, b.latitude, b.longitude);
          return distA.compareTo(distB);
        });

        _cache[bucketKey] = (DateTime.now(), uniquePlaces);
        return uniquePlaces;
      }
    } catch (e) {
      debugPrint('SafePlacesService: Real safe places fetch error: $e');
    }

    // Return empty list if no real places found. NEVER return hardcoded mock points!
    return <SafePlaceModel>[];
  }

  /// Internal helper to invoke MapplsNearby for a single category
  Future<List<SafePlaceModel>> _queryMapplsCategory(
    String keyword,
    SafePlaceType type,
    double userLat,
    double userLng,
  ) async {
    try {
      final nearby = mappls.MapplsNearby(
        keyword: keyword,
        location: mappls.LatLng(userLat, userLng),
        radius: 10000, // 10km search perimeter
        sortBy: mappls.NearbyCriteria.DISTANCE_ASCENDING,
      );

      final res = await nearby.callNearby().timeout(const Duration(seconds: 4));
      if (res?.suggestedLocations != null && res!.suggestedLocations!.isNotEmpty) {
        return res.suggestedLocations!
            .where((loc) => loc.latitude != null && loc.longitude != null)
            .map((loc) {
          final phone = (loc.mobileNo != null && loc.mobileNo!.trim().isNotEmpty)
              ? loc.mobileNo!.trim()
              : (loc.landlineNo != null && loc.landlineNo!.trim().isNotEmpty)
                  ? loc.landlineNo!.trim()
                  : _defaultPhoneFor(type);

          return SafePlaceModel(
            id: loc.mapplsPin ?? 'mappls_${type.name}_${loc.latitude}_${loc.longitude}',
            name: (loc.placeName != null && loc.placeName!.trim().isNotEmpty)
                ? loc.placeName!.trim()
                : _defaultNameFor(type),
            type: type,
            latitude: loc.latitude!,
            longitude: loc.longitude!,
            phoneNumber: phone,
            address: (loc.placeAddress != null && loc.placeAddress!.trim().isNotEmpty)
                ? loc.placeAddress!.trim()
                : 'Near current location',
            statusText: loc.hourOfOperation?.isNotEmpty == true
                ? loc.hourOfOperation!
                : 'Verified Mappls Safety Point',
            is24x7: true,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('SafePlacesService: MapplsNearby query ($keyword) error: $e');
    }
    return [];
  }

  /// Real OpenStreetMap Overpass query for emergency POIs around user location
  Future<List<SafePlaceModel>> _queryOverpassCategory(
    SafePlaceType type,
    double userLat,
    double userLng,
  ) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 4);
    try {
      final tag = _osmTagForType(type);
      // Query nodes and ways within 10km radius (capped to 20 results for fast response)
      final query = '[out:json][timeout:4];(node[$tag](around:10000,$userLat,$userLng);way[$tag](around:10000,$userLat,$userLng););out center 20;';
      final uri = Uri.parse('https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(query)}');
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final jsonStr = await response.transform(utf8.decoder).join();
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        final elements = map['elements'] as List<dynamic>?;
        if (elements != null) {
          final List<SafePlaceModel> list = [];
          for (final el in elements) {
            final tags = el['tags'] as Map<String, dynamic>? ?? {};
            final lat = (el['lat'] ?? el['center']?['lat']) as num?;
            final lon = (el['lon'] ?? el['center']?['lon']) as num?;
            if (lat == null || lon == null) continue;

            final name = (tags['name'] as String?)?.trim() ??
                (tags['name:en'] as String?)?.trim() ??
                _defaultNameFor(type);
            final phone = (tags['phone'] as String?)?.trim() ??
                (tags['contact:phone'] as String?)?.trim() ??
                _defaultPhoneFor(type);
            final street = (tags['addr:street'] as String?)?.trim();
            final city = (tags['addr:city'] as String?)?.trim();
            final address = [?street, ?city].join(', ');

            list.add(
              SafePlaceModel(
                id: 'osm_${type.name}_${el['id']}',
                name: name,
                type: type,
                latitude: lat.toDouble(),
                longitude: lon.toDouble(),
                phoneNumber: phone,
                address: address.isNotEmpty ? address : 'Near current location',
                statusText: 'Verified OpenStreetMap POI',
                is24x7: true,
              ),
            );
          }
          return list;
        }
      }
    } catch (_) {
    } finally {
      client.close();
    }
    return [];
  }

  static String _keywordForType(SafePlaceType type) {
    switch (type) {
      case SafePlaceType.police:
        return 'police';
      case SafePlaceType.hospital:
        return 'hospital';
      case SafePlaceType.fireStation:
        return 'fire station';
      case SafePlaceType.safeShelter:
        return 'shelter';
    }
  }

  static String _osmTagForType(SafePlaceType type) {
    switch (type) {
      case SafePlaceType.police:
        return '"amenity"="police"';
      case SafePlaceType.hospital:
        return '"amenity"~"hospital|clinic"';
      case SafePlaceType.fireStation:
        return '"amenity"="fire_station"';
      case SafePlaceType.safeShelter:
        return '"social_facility"="shelter"';
    }
  }

  static String _defaultPhoneFor(SafePlaceType type) {
    switch (type) {
      case SafePlaceType.police:
        return '112';
      case SafePlaceType.hospital:
        return '108';
      case SafePlaceType.fireStation:
        return '101';
      case SafePlaceType.safeShelter:
        return '112';
    }
  }

  static String _defaultNameFor(SafePlaceType type) {
    switch (type) {
      case SafePlaceType.police:
        return 'Police Station';
      case SafePlaceType.hospital:
        return 'Emergency Care Hospital';
      case SafePlaceType.fireStation:
        return 'Fire & Rescue Station';
      case SafePlaceType.safeShelter:
        return 'Safe Shelter Haven';
    }
  }

  /// Format distance between user and place always in km (e.g. '0.4 km', '1.2 km')
  static String formatDistance(double meters) {
    final km = meters / 1000.0;
    if (km < 0.1) {
      return '0.1 km';
    } else {
      return '${km.toStringAsFixed(1)} km';
    }
  }
}
