import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as osm;
import 'package:mappls_gl/mappls_gl.dart' as mappls;
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;
import '../../constants/app_colors.dart';
import '../../models/breadcrumb_model.dart';
import '../../models/safe_place_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../services/routing_service.dart';
import '../../services/safe_places_service.dart';
import '../../services/sms_service.dart';

/// Live location screen with Mappls (MapmyIndia) Vector Map & OpenStreetMap fallback,
/// Real-Time Breadcrumb Trail, and Speed Telemetry HUD
class LiveLocationScreen extends StatefulWidget {
  const LiveLocationScreen({super.key});

  @override
  State<LiveLocationScreen> createState() => _LiveLocationScreenState();
}

class _LiveLocationScreenState extends State<LiveLocationScreen>
    with SingleTickerProviderStateMixin {
  static const _mapplsStatusChannel =
      MethodChannel('com.gaurav.rakshak_connect/mappls_status');

  final MapController _osmMapController = MapController();
  final SmsService _smsService = SmsService();
  late AnimationController _pulseController;

  // Map state (OpenStreetMap safe default, instant toggle to Mappls Map)
  mappls.MapplsMapController? _mapplsController;
  bool _useMappls = false;
  bool _isMapplsStyleLoaded = false;
  mappls.Line? _mapplsLine;
  mappls.Circle? _mapplsStartCircle;
  String? _mapplsError;

  // Mappls SDK status from native Android layer
  bool _isMapplsInitialized = false;

  bool _autoFollow = true;
  osm.LatLng? _lastCenteredPoint;

  // Nearby safe places & collapsible drawer state (Google Maps UX)
  final SafePlacesService _safePlacesService = SafePlacesService();
  final RoutingService _routingService = RoutingService();
  bool _isDrawerExpanded = true;
  final bool _showSafePlaces = true;
  SafePlaceType? _selectedCategory;
  SafePlaceModel? _selectedSafePlace;
  SafePlaceModel? _activeNavigationDestination;
  List<osm.LatLng> _activeRoutePoints = [];
  RoutingResult? _activeRoutingResult;
  bool _isLoadingRoute = false;
  mappls.Line? _mapplsRouteLine;
  final List<mappls.Symbol> _mapplsSafePlaceSymbols = [];
  bool _mapplsPinsRegistered = false;
  String _lastMapplsSafePlacesKey = '';

  // Real Mappls nearby safe places state
  List<SafePlaceModel> _realSafePlaces = [];
  bool _isLoadingPlaces = false;
  double? _lastFetchedLat;
  double? _lastFetchedLng;
  SafePlaceType? _lastFetchedCategory;
  int _placesRequestId = 0;

  /// Returns currently resolved safe places (prioritizing real Mappls POIs, falling back if loading)
  List<SafePlaceModel> _getCurrentSafePlaces(LocationProvider location) {
    if (_realSafePlaces.isNotEmpty) {
      return _selectedCategory == null
          ? _realSafePlaces
          : _realSafePlaces.where((p) => p.type == _selectedCategory).toList();
    }
    return location.hasLocation
        ? _safePlacesService.getNearbySafePlaces(
            userLat: location.latitude!,
            userLng: location.longitude!,
            filterType: _selectedCategory,
          )
        : <SafePlaceModel>[];
  }

  /// Asynchronously fetch real POIs from Mappls Map API
  Future<void> _fetchRealSafePlaces(double lat, double lng, {bool force = false}) async {
    if (!mounted) return;
    if (!force &&
        _lastFetchedLat != null &&
        _lastFetchedLng != null &&
        _lastFetchedCategory == _selectedCategory) {
      final dist = Geolocator.distanceBetween(_lastFetchedLat!, _lastFetchedLng!, lat, lng);
      if (dist < 250 && _realSafePlaces.isNotEmpty) {
        return;
      }
    }

    _lastFetchedLat = lat;
    _lastFetchedLng = lng;
    _lastFetchedCategory = _selectedCategory;
    final currentRequestId = ++_placesRequestId;

    if (mounted) {
      setState(() => _isLoadingPlaces = true);
    }

    try {
      final places = await _safePlacesService.fetchRealMapplsSafePlaces(
        userLat: lat,
        userLng: lng,
        filterType: _selectedCategory,
      );
      if (currentRequestId == _placesRequestId && mounted) {
        setState(() {
          _realSafePlaces = places;
          _isLoadingPlaces = false;
        });
      }
    } catch (_) {
      if (currentRequestId == _placesRequestId && mounted) {
        setState(() => _isLoadingPlaces = false);
      }
    }
  }

  void _onCategoryFilterSelected(SafePlaceType? type) {
    setState(() {
      _selectedCategory = type;
      _selectedSafePlace = null;
    });
    final location = context.read<LocationProvider>();
    if (location.hasLocation) {
      _fetchRealSafePlaces(location.latitude!, location.longitude!, force: true);
    }
  }

  @override
  void initState() {
    super.initState();
    mappls.MapplsMap.useHybridComposition = true;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _checkMapplsStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLocation());
  }

  Future<void> _checkMapplsStatus() async {
    try {
      final res =
          await _mapplsStatusChannel.invokeMethod<Map>('getMapplsStatus');
      if (res != null && mounted) {
        setState(() {
          _isMapplsInitialized = res['isInitialized'] == true;
          if (_isMapplsInitialized) {
            _useMappls = true;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pulseController.dispose();
    if (_mapplsController != null) {
      try {
        _mapplsController?.onSymbolTapped.remove(_handleMapplsSymbolTap);
      } catch (_) {}
    }
    _mapplsSafePlaceSymbols.clear();
    _lastMapplsSafePlacesKey = '';
    _mapplsPinsRegistered = false;
    _mapplsController = null;
    _isMapplsStyleLoaded = false;
    _mapplsLine = null;
    _mapplsStartCircle = null;
    _mapplsRouteLine = null;
    super.dispose();
  }

  Future<void> _initLocation() async {
    final locationProvider = context.read<LocationProvider>();
    final authProvider = context.read<AppAuthProvider>();

    await locationProvider.fetchCurrentLocation();
    if (locationProvider.hasLocation) {
      _centerMap();
      _fetchRealSafePlaces(
        locationProvider.latitude!,
        locationProvider.longitude!,
        force: true,
      );
      // Auto-start live breadcrumbs tracking for all users (including guests)
      final userId = authProvider.user?.uid ?? '';
      if (!locationProvider.isTracking) {
        locationProvider.startLiveTracking(userId: userId);
      }
    }
  }

  void _centerMap() {
    final provider = context.read<LocationProvider>();
    if (!provider.hasLocation) return;
    final lat = provider.latitude!;
    final lng = provider.longitude!;

    if (_useMappls && _isMapplsInitialized && _isMapplsStyleLoaded && _mapplsController != null) {
      try {
        _mapplsController?.animateCamera(
          mappls.CameraUpdate.newLatLngZoom(
            mappls.LatLng(lat, lng),
            16.5,
          ),
        );
      } catch (e) {
        debugPrint('Mappls animateCamera error: $e');
      }
    } else {
      try {
        _osmMapController.move(
          osm.LatLng(lat, lng),
          16.5,
        );
      } catch (e) {
        debugPrint('OSM move error: $e');
      }
    }
  }

  void _updateMapplsBreadcrumbs(List<BreadcrumbModel> breadcrumbs) {
    if (!_isMapplsStyleLoaded || _mapplsController == null || !mounted) return;
    try {
      final points = breadcrumbs
          .map((b) => mappls.LatLng(b.latitude, b.longitude))
          .toList();

      if (points.length < 2) {
        if (_mapplsLine != null) {
          _mapplsController?.removeLine(_mapplsLine!).catchError((_) => null);
          _mapplsLine = null;
        }
        if (_mapplsStartCircle != null) {
          _mapplsController?.removeCircle(_mapplsStartCircle!).catchError((_) => null);
          _mapplsStartCircle = null;
        }
        return;
      }

      // 1. Draw or update starting point pin circle
      if (_mapplsStartCircle == null && points.isNotEmpty) {
        _mapplsController?.addCircle(
          mappls.CircleOptions(
            geometry: points.first,
            circleColor: '#388E3C',
            circleRadius: 8.0,
            circleStrokeColor: '#FFFFFF',
            circleStrokeWidth: 2.5,
          ),
        ).then((circle) {
          if (mounted && _isMapplsStyleLoaded) {
            _mapplsStartCircle = circle;
          }
        }).catchError((_) => null);
      }

      // 2. Draw or update breadcrumbs trail line
      if (_mapplsLine == null) {
        _mapplsController?.addLine(
          mappls.LineOptions(
            geometry: points,
            lineColor: '#D32F2F',
            lineWidth: 5.0,
            lineOpacity: 0.9,
            lineJoin: 'round',
          ),
        ).then((line) {
          if (mounted && _isMapplsStyleLoaded) {
            _mapplsLine = line;
          }
        }).catchError((_) => null);
      } else {
        _mapplsController?.updateLine(
          _mapplsLine!,
          mappls.LineOptions(geometry: points),
        ).catchError((_) => null);
      }
    } catch (e) {
      debugPrint('Mappls breadcrumbs error: $e');
    }
  }

  void _clearTrail(LocationProvider location) {
    if (_mapplsLine != null) {
      _mapplsController?.removeLine(_mapplsLine!);
      _mapplsLine = null;
    }
    if (_mapplsStartCircle != null) {
      _mapplsController?.removeCircle(_mapplsStartCircle!);
      _mapplsStartCircle = null;
    }
    location.clearBreadcrumbs();
  }

  void _toggleTracking() {
    final locationProvider = context.read<LocationProvider>();
    final authProvider = context.read<AppAuthProvider>();
    final userId = authProvider.user?.uid ?? '';

    if (locationProvider.isTracking) {
      locationProvider.stopLiveTracking();
    } else {
      locationProvider.startLiveTracking(userId: userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Auto-center map if user enabled autoFollow and position has changed
    if (_autoFollow && location.hasLocation) {
      final lat = location.latitude!;
      final lng = location.longitude!;
      if (_lastCenteredPoint == null ||
          _lastCenteredPoint!.latitude != lat ||
          _lastCenteredPoint!.longitude != lng) {
        _lastCenteredPoint = osm.LatLng(lat, lng);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_useMappls && _mapplsController != null && _isMapplsStyleLoaded) {
            try {
              _mapplsController?.animateCamera(
                mappls.CameraUpdate.newLatLng(mappls.LatLng(lat, lng)),
              );
            } catch (e) {
              debugPrint('Auto-follow Mappls camera error: $e');
            }
          } else if (!_useMappls) {
            try {
              _osmMapController.move(
                _lastCenteredPoint!,
                _osmMapController.camera.zoom,
              );
            } catch (e) {
              debugPrint('Auto-follow OSM move error: $e');
            }
          }
        });
      }
    }

    // Sync Mappls breadcrumbs if Mappls map is active and initialized
    if (_useMappls && _isMapplsInitialized && _isMapplsStyleLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateMapplsBreadcrumbs(location.breadcrumbs);
        }
      });
    }

    final polylinePoints = location.polylinePoints;
    final startPoint = polylinePoints.isNotEmpty ? polylinePoints.first : null;
    final currentPoint = location.hasLocation
        ? osm.LatLng(location.latitude!, location.longitude!)
        : null;

    final safePlaces = _getCurrentSafePlaces(location);

    // Trigger initial real Mappls places fetch once GPS is locked
    if (location.hasLocation && _realSafePlaces.isEmpty && !_isLoadingPlaces && _lastFetchedLat == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && location.hasLocation) {
          _fetchRealSafePlaces(location.latitude!, location.longitude!);
        }
      });
    }

    // Sync Mappls safe places symbols when Mappls map is active and initialized
    if (_useMappls && _isMapplsInitialized && _isMapplsStyleLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _syncMapplsSafePlacesIfNeeded(safePlaces);
        }
      });
    }

    final showHorizontalCarousel = _selectedSafePlace == null && safePlaces.isNotEmpty;
    final drawerBase = _selectedSafePlace != null
        ? 210.0
        : (_isDrawerExpanded ? 245.0 : 85.0);
    final fabBottom = drawerBase + (showHorizontalCarousel ? 86.0 : 0.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Live GPS Tracking',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 0.2,
          ),
        ),
        actions: [
          if (polylinePoints.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Clear Trail',
              onPressed: () => _clearTrail(location),
            ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share Live Location Link',
            onPressed: location.hasLocation
                ? () => _smsService.shareLocationLink(
                      location.latitude!,
                      location.longitude!,
                    )
                : null,
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Map View (Mappls / OpenStreetMap) ───────────────────
          location.isLoading && !location.hasLocation
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : location.error != null && !location.hasLocation
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_off_rounded,
                              size: 48, color: AppColors.textSecondary),
                          const SizedBox(height: 12),
                          Text(
                            location.error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _initLocation,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : (_useMappls && _isMapplsInitialized)
                      ? _buildMapplsMap(currentPoint, location, safePlaces)
                      : _buildOsmMap(
                          currentPoint,
                          polylinePoints,
                          startPoint,
                          location,
                          safePlaces,
                        ),

          // ── Mappls Auth/Loading Notice (if error occurs when initialized) ─
          if (_useMappls && _isMapplsInitialized && _mapplsError != null)
            Positioned(
              top: 76,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade900.withAlpha(230),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 6),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mappls notice: $_mapplsError',
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _useMappls = false),
                      child: const Text('USE OSM',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ),

          // ── Top Live Tracking Status Badge ─────────────────────
          Positioned(
            top: 14,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B).withAlpha(240)
                    : Colors.white.withAlpha(240),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: location.isTracking
                          ? const Color(0xFF4CAF50)
                          : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    location.isTracking ? 'LIVE TRACKING' : 'PAUSED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                      color: location.isTracking
                          ? const Color(0xFF388E3C)
                          : AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  // ── Map Engine Switcher Pill ──
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        if (!_useMappls && !_isMapplsInitialized) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Mappls Map is unavailable. Displaying OpenStreetMap.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }
                        setState(() {
                          _useMappls = !_useMappls;
                          if (!_useMappls) {
                            _isMapplsStyleLoaded = false;
                            _mapplsPinsRegistered = false;
                            _lastMapplsSafePlacesKey = '';
                            _mapplsSafePlaceSymbols.clear();
                            _mapplsController = null;
                            _mapplsLine = null;
                            _mapplsStartCircle = null;
                            _mapplsRouteLine = null;
                          }
                        });
                        WidgetsBinding.instance.addPostFrameCallback((_) => _centerMap());
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: _useMappls
                              ? const Color(0xFF0288D1).withAlpha(25)
                              : Colors.grey.withAlpha(30),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _useMappls
                                ? const Color(0xFF0288D1)
                                : Colors.grey.shade400,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _useMappls ? Icons.layers_rounded : Icons.map_outlined,
                              size: 13,
                              color: _useMappls ? const Color(0xFF0288D1) : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _useMappls ? 'MAPPLS' : 'OSM',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                                color: _useMappls
                                    ? const Color(0xFF0288D1)
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Icon(
                              Icons.sync_alt_rounded,
                              size: 11,
                              color: _useMappls ? const Color(0xFF0288D1) : AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Movement Mode Chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      location.movementMode,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Top Category Filter Row (Directly below Live Tracking Bar) ──
          if (location.hasLocation)
            Positioned(
              top: 58,
              left: 0,
              right: 0,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildCategoryChip(
                      label: _isLoadingPlaces ? 'Loading...' : 'All (${safePlaces.length})',
                      isSelected: _selectedCategory == null,
                      onTap: () => _onCategoryFilterSelected(null),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildCategoryChip(
                      label: '🚓 Police',
                      isSelected: _selectedCategory == SafePlaceType.police,
                      onTap: () => _onCategoryFilterSelected(
                          _selectedCategory == SafePlaceType.police
                              ? null
                              : SafePlaceType.police),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildCategoryChip(
                      label: '🏥 Hospitals',
                      isSelected: _selectedCategory == SafePlaceType.hospital,
                      onTap: () => _onCategoryFilterSelected(
                          _selectedCategory == SafePlaceType.hospital
                              ? null
                              : SafePlaceType.hospital),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildCategoryChip(
                      label: '🚒 Fire Stations',
                      isSelected: _selectedCategory == SafePlaceType.fireStation,
                      onTap: () => _onCategoryFilterSelected(
                          _selectedCategory == SafePlaceType.fireStation
                              ? null
                              : SafePlaceType.fireStation),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildCategoryChip(
                      label: '🛡️ Shelters',
                      isSelected: _selectedCategory == SafePlaceType.safeShelter,
                      onTap: () => _onCategoryFilterSelected(
                          _selectedCategory == SafePlaceType.safeShelter
                              ? null
                              : SafePlaceType.safeShelter),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),

          // ── Active In-App Navigation Route Guidance Banner ──────
          if (_activeNavigationDestination != null && location.hasLocation)
            Positioned(
              top: 98,
              left: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withAlpha(245),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: const Color(0xFF00E5FF), width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    _isLoadingRoute
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF00E5FF),
                            ),
                          )
                        : const Icon(Icons.alt_route_rounded,
                            color: Color(0xFF00E5FF), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isLoadingRoute
                                ? 'Calculating road route to ${_activeNavigationDestination!.name}...'
                                : 'Navigating to ${_activeNavigationDestination!.name}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _isLoadingRoute
                                ? 'Following real street network...'
                                : '${_activeRoutingResult?.distanceText ?? SafePlacesService.formatDistance(Geolocator.distanceBetween(location.latitude!, location.longitude!, _activeNavigationDestination!.latitude, _activeNavigationDestination!.longitude))} via road • ${_activeRoutingResult?.durationText ?? "~3 mins"}',
                            style: const TextStyle(
                              color: Color(0xFF80DEEA),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 18),
                      tooltip: 'Cancel Route',
                      onPressed: _clearInAppNavigation,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    ),
                  ],
                ),
              ),
            ),

          // ── Map Floating Action Controls (Dynamically positioned above drawer) ──
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            right: 16,
            bottom: fabBottom,
            child: Column(
              children: [
                // Layer switch shortcut FAB
                FloatingActionButton.small(
                  heroTag: 'map_type_btn',
                  onPressed: () {
                    if (!_useMappls && !_isMapplsInitialized) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Mappls Map is unavailable. Displaying OpenStreetMap.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }
                    setState(() {
                      _useMappls = !_useMappls;
                      if (!_useMappls) {
                        _isMapplsStyleLoaded = false;
                        _mapplsPinsRegistered = false;
                        _lastMapplsSafePlacesKey = '';
                        _mapplsSafePlaceSymbols.clear();
                        _mapplsController = null;
                        _mapplsLine = null;
                        _mapplsStartCircle = null;
                        _mapplsRouteLine = null;
                      }
                    });
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => _centerMap());
                  },
                  backgroundColor:
                      isDark ? const Color(0xFF1E293B) : Colors.white,
                  foregroundColor: _useMappls
                      ? const Color(0xFF0288D1)
                      : AppColors.primary,
                  tooltip: _useMappls
                      ? 'Mappls Active (Tap for OSM)'
                      : 'OSM Active (Tap for Mappls)',
                  child: Icon(_useMappls
                      ? Icons.layers_rounded
                      : Icons.map_rounded),
                ),
                const SizedBox(height: 10),
                // Auto-Follow / Recenter Button
                FloatingActionButton.small(
                  heroTag: 'recenter_btn',
                  onPressed: () {
                    setState(() {
                      _autoFollow = true;
                    });
                    _centerMap();
                  },
                  backgroundColor: _autoFollow
                      ? AppColors.primary
                      : (isDark ? const Color(0xFF1E293B) : Colors.white),
                  foregroundColor:
                      _autoFollow ? Colors.white : AppColors.primary,
                  child: const Icon(Icons.my_location_rounded),
                ),
              ],
            ),
          ),

          // ── Floating Horizontal Safe Places Carousel (Google Maps Style) ──
          if (showHorizontalCarousel)
            Positioned(
              left: 0,
              right: 0,
              bottom: drawerBase + 6,
              child: _buildHorizontalSafePlacesBar(safePlaces, location, isDark),
            ),

          // ── Bottom Sheet Layer: Collapsible Telemetry or Selected Place Card ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildCollapsibleTrackingDrawer(location, isDark),
          ),
        ],
      ),
    );
  }



  // ── Mappls (MapmyIndia) Map Builder ─────────────────────────
  Widget _buildMapplsMap(
    osm.LatLng? currentPoint,
    LocationProvider location,
    List<SafePlaceModel> safePlaces,
  ) {
    final mapplsTarget = currentPoint != null
        ? mappls.LatLng(currentPoint.latitude, currentPoint.longitude)
        : const mappls.LatLng(20.5937, 78.9629);

    return mappls.MapplsMap(
      initialCameraPosition: mappls.CameraPosition(
        target: mapplsTarget,
        zoom: currentPoint != null ? 16.5 : 5.0,
      ),
      myLocationEnabled: location.hasLocation,
      myLocationTrackingMode: _autoFollow
          ? mappls.MyLocationTrackingMode.tracking
          : mappls.MyLocationTrackingMode.none,
      myLocationRenderMode: mappls.MyLocationRenderMode.compass,
      compassEnabled: true,
      onUserLocationUpdated: (mappls.UserLocation userLoc) {
        if (mounted && _autoFollow) {
          _lastCenteredPoint = osm.LatLng(userLoc.position.latitude, userLoc.position.longitude);
        }
      },
      onMapCreated: (controller) {
        _mapplsController = controller;
      },
      onStyleLoadedCallback: () async {
        _isMapplsStyleLoaded = true;
        _updateMapplsBreadcrumbs(location.breadcrumbs);
        await _registerMapplsPinImages();
        _mapplsController?.onSymbolTapped.remove(_handleMapplsSymbolTap);
        _mapplsController?.onSymbolTapped.add(_handleMapplsSymbolTap);
        if (mounted) {
          _syncMapplsSafePlacesIfNeeded(safePlaces);
        }
        if (location.hasLocation) {
          try {
            _mapplsController?.animateCamera(
              mappls.CameraUpdate.newLatLngZoom(
                mappls.LatLng(location.latitude!, location.longitude!),
                16.5,
              ),
            );
          } catch (e) {
            debugPrint('Mappls style loaded camera error: $e');
          }
        }
      },
      onMapError: (code, message) {
        debugPrint('Mappls Map Error: code=$code, message=$message');
        if (mounted) {
          setState(() {
            _mapplsError = message;
          });
        }
      },
      onCameraTrackingDismissed: () {
        if (_autoFollow) {
          setState(() => _autoFollow = false);
        }
      },
    );
  }

  // ── OpenStreetMap (OSM) Fallback Map Builder ─────────────────
  Widget _buildOsmMap(
    osm.LatLng? currentPoint,
    List<osm.LatLng> polylinePoints,
    osm.LatLng? startPoint,
    LocationProvider location,
    List<SafePlaceModel> safePlaces,
  ) {
    return FlutterMap(
      mapController: _osmMapController,
      options: MapOptions(
        initialCenter: currentPoint ?? const osm.LatLng(20.5937, 78.9629),
        initialZoom: currentPoint != null ? 16.5 : 5.0,
        onPositionChanged: (pos, hasGesture) {
          if (hasGesture && _autoFollow) {
            setState(() => _autoFollow = false);
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.gaurav.rakshak_connect',
        ),

        // ── Glowing Breadcrumbs Polyline Trail ────────
        if (polylinePoints.length > 1)
          PolylineLayer(
            polylines: [
              // Outer glow
              Polyline(
                points: polylinePoints,
                color: const Color(0xFFD32F2F).withAlpha(100),
                strokeWidth: 8.0,
              ),
              // Inner solid line
              Polyline(
                points: polylinePoints,
                color: const Color(0xFFD32F2F),
                strokeWidth: 4.0,
              ),
            ],
          ),

        // ── In-App Directions Navigation Polyline ─────────
        if (_activeRoutePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              // Outer cyan glow
              Polyline(
                points: _activeRoutePoints,
                color: const Color(0xFF00E5FF).withAlpha(100),
                strokeWidth: 9.0,
              ),
              // Inner solid cyan navigation line
              Polyline(
                points: _activeRoutePoints,
                color: const Color(0xFF00E5FF),
                strokeWidth: 5.0,
              ),
            ],
          ),

        // ── Markers (Safe Places, Start Pin & Moving Radar) ─────────
        MarkerLayer(
          markers: [
            // 0. Nearby Safe Place Pins
            if (location.hasLocation && _showSafePlaces)
              ..._buildSafePlaceMarkers(safePlaces),

            // 1. Initial Start Point Pin
            if (startPoint != null && polylinePoints.length > 1)
              Marker(
                point: startPoint,
                width: 36,
                height: 36,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF388E3C),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.flag_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),

            // 2. Live Moving Dot with Compass Arrow & Radar Pulse
            if (currentPoint != null)
              Marker(
                point: currentPoint,
                width: 60,
                height: 60,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final pulseScale = 1.0 + (_pulseController.value * 0.4);
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer pulsing radar circle
                        Transform.scale(
                          scale: pulseScale,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFD32F2F).withAlpha(
                                (80 * (1.0 - _pulseController.value)).toInt(),
                              ),
                            ),
                          ),
                        ),
                        // Inner Solid Marker with Heading Angle
                        Transform.rotate(
                          angle: (location.currentHeading * math.pi) / 180.0,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD32F2F),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black38,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.navigation_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ── Safe Places Map Markers & In-App Navigation ──────────────

  List<Marker> _buildSafePlaceMarkers(List<SafePlaceModel> safePlaces) {
    return safePlaces.map((place) {
      final isSelected = _selectedSafePlace?.id == place.id;
      final isDestination = _activeNavigationDestination?.id == place.id;
      return Marker(
        point: osm.LatLng(place.latitude, place.longitude),
        width: (isSelected || isDestination) ? 48 : 38,
        height: (isSelected || isDestination) ? 48 : 38,
        child: GestureDetector(
          onTap: () => _onSelectSafePlace(place),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isDestination ? const Color(0xFF00E5FF) : place.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: (isSelected || isDestination) ? 3.0 : 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDestination ? const Color(0xFF00E5FF) : place.color)
                      .withAlpha((isSelected || isDestination) ? 190 : 110),
                  blurRadius: (isSelected || isDestination) ? 14 : 6,
                  spreadRadius: (isSelected || isDestination) ? 3 : 0,
                ),
              ],
            ),
            child: Icon(
              isDestination ? Icons.flag_rounded : place.icon,
              color: isDestination ? Colors.black87 : Colors.white,
              size: (isSelected || isDestination) ? 24 : 18,
            ),
          ),
        ),
      );
    }).toList();
  }

  void _onSelectSafePlace(SafePlaceModel place) {
    setState(() {
      _selectedSafePlace = place;
      _isDrawerExpanded = true;
      _autoFollow = false;
    });
    if (_useMappls && _mapplsController != null && _isMapplsStyleLoaded) {
      try {
        _mapplsController?.animateCamera(
          mappls.CameraUpdate.newLatLngZoom(
            mappls.LatLng(place.latitude, place.longitude),
            16.0,
          ),
        );
      } catch (_) {}
    } else {
      try {
        _osmMapController.move(
          osm.LatLng(place.latitude, place.longitude),
          16.0,
        );
      } catch (_) {}
    }
  }

  void _syncMapplsSafePlacesIfNeeded(List<SafePlaceModel> safePlaces) {
    if (!_useMappls || !_isMapplsInitialized || !_isMapplsStyleLoaded || _mapplsController == null) return;
    final key = '${_selectedCategory?.name}_${_activeNavigationDestination?.id}_${safePlaces.map((p) => p.id).join(',')}';
    if (key != _lastMapplsSafePlacesKey) {
      _lastMapplsSafePlacesKey = key;
      _updateMapplsSafePlaces(safePlaces);
    }
  }

  Future<void> _registerMapplsPinImages() async {
    if (_mapplsPinsRegistered || _mapplsController == null) return;
    try {
      final pinConfigs = <String, (Color, IconData, bool)>{
        'pin_police': (const Color(0xFF1E88E5), Icons.local_police_rounded, false),
        'pin_hospital': (const Color(0xFFE53935), Icons.local_hospital_rounded, false),
        'pin_fireStation': (const Color(0xFFFB8C00), Icons.local_fire_department_rounded, false),
        'pin_safeShelter': (const Color(0xFF8E24AA), Icons.shield_rounded, false),
        'pin_flag': (const Color(0xFF00E5FF), Icons.flag_rounded, true),
      };

      for (final entry in pinConfigs.entries) {
        final bytes = await _createOsmStylePinBitmap(
          color: entry.value.$1,
          icon: entry.value.$2,
          isDestination: entry.value.$3,
        );
        await _mapplsController?.addImage(entry.key, bytes);
      }
      _mapplsPinsRegistered = true;
    } catch (e) {
      debugPrint('Error registering Mappls pin images: $e');
    }
  }

  Future<Uint8List> _createOsmStylePinBitmap({
    required Color color,
    required IconData icon,
    bool isDestination = false,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = 96.0;
    const center = Offset(48, 48);
    const radius = 38.0;

    // 1. Glowing outer drop shadow matching place color (just like OSM)
    final shadowPaint = Paint()
      ..color = (isDestination ? const Color(0xFF00E5FF) : color).withAlpha(160)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, radius + 2, shadowPaint);

    // 2. White outer circular border (3.5px thickness, identical to OSM border)
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, borderPaint);

    // 3. Inner solid colored circle (identical to OSM background color)
    final fillPaint = Paint()
      ..color = isDestination ? const Color(0xFF00E5FF) : color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 4.5, fillPaint);

    // 4. Draw exact Material Icon (identical to OSM Icon(place.icon))
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 38.0,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: isDestination ? Colors.black87 : Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _updateMapplsSafePlaces(List<SafePlaceModel> safePlaces) async {
    if (!_isMapplsStyleLoaded || _mapplsController == null || !mounted) return;
    try {
      if (!_mapplsPinsRegistered) {
        await _registerMapplsPinImages();
      }

      // Batch remove existing symbols in one platform call
      await _mapplsController?.clearSymbols();
      _mapplsSafePlaceSymbols.clear();

      if (safePlaces.isEmpty) return;

      final optionsList = <mappls.SymbolOptions>[];
      final dataList = <Map<String, dynamic>>[];

      for (final place in safePlaces) {
        final isSelected = _selectedSafePlace?.id == place.id;
        final isDestination = _activeNavigationDestination?.id == place.id;
        final iconName = isDestination ? 'pin_flag' : 'pin_${place.type.name}';

        optionsList.add(
          mappls.SymbolOptions(
            geometry: mappls.LatLng(place.latitude, place.longitude),
            iconImage: iconName,
            iconSize: (isSelected || isDestination) ? 0.82 : 0.68,
            iconAnchor: 'center',
            textField: place.name,
            textSize: 11.0,
            textOffset: const Offset(0, 1.6),
            textColor: '#FFFFFF',
            textHaloColor: '#000000',
            textHaloWidth: 1.8,
          ),
        );
        dataList.add({'placeId': place.id});
      }

      // Batch add all symbols in a single platform-channel call
      final added = await _mapplsController?.addSymbols(optionsList, dataList);
      if (added != null && mounted) {
        _mapplsSafePlaceSymbols.addAll(added);
      }
    } catch (e) {
      debugPrint('Mappls safe places update error: $e');
    }
  }

  void _handleMapplsSymbolTap(mappls.Symbol symbol) {
    final placeId = symbol.data?['placeId'];
    if (placeId != null) {
      final location = context.read<LocationProvider>();
      final safePlaces = _getCurrentSafePlaces(location);
      final place = safePlaces.where((p) => p.id == placeId).firstOrNull;
      if (place != null) {
        _onSelectSafePlace(place);
      }
    }
  }

  /// Start In-App Map Navigation: Fetches real turn-by-turn road route and plots road polyline
  Future<void> _startInAppNavigation(SafePlaceModel place) async {
    final location = context.read<LocationProvider>();
    if (!location.hasLocation) return;

    setState(() {
      _activeNavigationDestination = place;
      _isLoadingRoute = true;
      _autoFollow = false;
    });

    final startLat = location.latitude!;
    final startLng = location.longitude!;

    final result = await _routingService.getRoadRoute(
      startLat: startLat,
      startLng: startLng,
      destLat: place.latitude,
      destLng: place.longitude,
    );

    if (!mounted || _activeNavigationDestination?.id != place.id) return;

    setState(() {
      _activeRoutePoints = result.points;
      _activeRoutingResult = result;
      _isLoadingRoute = false;
    });

    // Draw real road route on Mappls if active
    if (_useMappls && _mapplsController != null && _isMapplsStyleLoaded) {
      try {
        if (_mapplsRouteLine != null) {
          await _mapplsController?.removeLine(_mapplsRouteLine!);
          _mapplsRouteLine = null;
        }
        final mapplsCoords = result.points
            .map((p) => mappls.LatLng(p.latitude, p.longitude))
            .toList();
        _mapplsRouteLine = await _mapplsController?.addLine(
          mappls.LineOptions(
            geometry: mapplsCoords,
            lineColor: '#00E5FF',
            lineWidth: 5.5,
            lineOpacity: 0.95,
            lineJoin: 'round',
          ),
        );
      } catch (_) {}
    }

    // Refresh Mappls symbols to show destination flag
    if (_useMappls && _isMapplsStyleLoaded) {
      _lastMapplsSafePlacesKey = '';
      final safePlaces = _getCurrentSafePlaces(location);
      _updateMapplsSafePlaces(safePlaces);
    }

    // Center map camera to fit entire route smoothly
    if (result.points.isNotEmpty) {
      double minLat = result.points.first.latitude;
      double maxLat = result.points.first.latitude;
      double minLng = result.points.first.longitude;
      double maxLng = result.points.first.longitude;

      for (final pt in result.points) {
        if (pt.latitude < minLat) minLat = pt.latitude;
        if (pt.latitude > maxLat) maxLat = pt.latitude;
        if (pt.longitude < minLng) minLng = pt.longitude;
        if (pt.longitude > maxLng) maxLng = pt.longitude;
      }

      if (_useMappls && _mapplsController != null && _isMapplsStyleLoaded) {
        try {
          final bounds = mappls.LatLngBounds(
            southwest: mappls.LatLng(minLat, minLng),
            northeast: mappls.LatLng(maxLat, maxLng),
          );
          _mapplsController?.animateCamera(
            mappls.CameraUpdate.newLatLngBounds(
              bounds,
              top: 80,
              left: 40,
              bottom: 240,
              right: 40,
            ),
          );
        } catch (_) {}
      } else {
        try {
          _osmMapController.fitCamera(
            CameraFit.bounds(
              bounds: LatLngBounds(
                osm.LatLng(minLat, minLng),
                osm.LatLng(maxLat, maxLng),
              ),
              padding: const EdgeInsets.fromLTRB(40, 80, 40, 240),
            ),
          );
        } catch (_) {}
      }
    }
  }

  /// Cancel In-App Navigation and clear road polyline
  void _clearInAppNavigation() {
    if (_mapplsRouteLine != null) {
      _mapplsController?.removeLine(_mapplsRouteLine!).catchError((_) => null);
      _mapplsRouteLine = null;
    }
    setState(() {
      _activeNavigationDestination = null;
      _activeRoutePoints = [];
      _activeRoutingResult = null;
      _isLoadingRoute = false;
    });

    if (_useMappls && _isMapplsStyleLoaded) {
      _lastMapplsSafePlacesKey = '';
      final location = context.read<LocationProvider>();
      final safePlaces = _getCurrentSafePlaces(location);
      _updateMapplsSafePlaces(safePlaces);
    }
  }

  Future<void> _callSafePlace(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark
                  ? const Color(0xFF1E293B).withAlpha(240)
                  : Colors.white.withAlpha(240)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? Colors.white24 : Colors.black12),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(80),
                    blurRadius: 6,
                  )
                ]
              : const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  // ── Floating Horizontal Safe Places Carousel (Google Maps Style) ─

  Widget _buildHorizontalSafePlacesBar(
    List<SafePlaceModel> safePlaces,
    LocationProvider location,
    bool isDark,
  ) {
    return SizedBox(
      height: 74,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: safePlaces.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final place = safePlaces[index];
          final distanceMeters = location.hasLocation
              ? Geolocator.distanceBetween(
                  location.latitude!,
                  location.longitude!,
                  place.latitude,
                  place.longitude,
                )
              : 0.0;
          final distStr = SafePlacesService.formatDistance(distanceMeters);

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _onSelectSafePlace(place),
              child: Container(
                width: 230,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B).withAlpha(240)
                      : Colors.white.withAlpha(245),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black12,
                    width: 1,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: place.color.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(place.icon, color: place.color, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            place.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                distStr,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0097A7),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  place.address,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _startInAppNavigation(place),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E5FF).withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.directions_rounded,
                            size: 16,
                            color: Color(0xFF0097A7),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Bottom Drawer (Collapsible: Selected Place Card OR Telemetry) ─

  Widget _buildCollapsibleTrackingDrawer(
    LocationProvider location,
    bool isDark,
  ) {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! > 200) {
            setState(() => _isDrawerExpanded = false);
          } else if (details.primaryVelocity! < -200) {
            setState(() => _isDrawerExpanded = true);
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: _selectedSafePlace != null
            ? _buildSelectedPlaceDrawerCard(_selectedSafePlace!, location, isDark)
            : _buildTelemetryDrawerContent(location, isDark),
      ),
    );
  }

  /// Detailed Card inside Drawer when a Safe Place is selected
  Widget _buildSelectedPlaceDrawerCard(
    SafePlaceModel place,
    LocationProvider location,
    bool isDark,
  ) {
    final distanceMeters = location.hasLocation
        ? Geolocator.distanceBetween(
            location.latitude!,
            location.longitude!,
            place.latitude,
            place.longitude,
          )
        : 0.0;
    final distanceStr = SafePlacesService.formatDistance(distanceMeters);
    final isNavigatingToThis = _activeNavigationDestination?.id == place.id;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(100),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Category Badge, Distance & Close button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: place.color.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(place.icon, size: 13, color: place.color),
                    const SizedBox(width: 4),
                    Text(
                      place.typeLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: place.color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.near_me_rounded,
                        size: 12, color: Colors.grey),
                    const SizedBox(width: 3),
                    Text(
                      '$distanceStr away',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Close / Deselect button
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    size: 20, color: Colors.grey),
                tooltip: 'Back to Live Telemetry',
                onPressed: () {
                  setState(() => _selectedSafePlace = null);
                },
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Place Name
          Text(
            place.name,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 3),

          // Address & Status
          Text(
            '${place.address} • ${place.statusText}',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons: In-App Directions & Call
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (isNavigatingToThis) {
                      _clearInAppNavigation();
                    } else {
                      _startInAppNavigation(place);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isNavigatingToThis
                        ? const Color(0xFFD32F2F)
                        : const Color(0xFF0097A7),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _isLoadingRoute && isNavigatingToThis
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          isNavigatingToThis
                              ? Icons.close_rounded
                              : Icons.alt_route_rounded,
                          color: Colors.white,
                        ),
                  label: Text(
                    _isLoadingRoute && isNavigatingToThis
                        ? 'CALCULATING ROAD...'
                        : isNavigatingToThis
                            ? 'CANCEL ROUTE'
                            : 'IN-APP DIRECTIONS',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  onPressed: () => _callSafePlace(place.phoneNumber),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: const BorderSide(
                        color: Color(0xFF388E3C), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.phone_rounded,
                      color: Color(0xFF388E3C), size: 18),
                  label: const Text(
                    'CALL',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF388E3C),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Live Telemetry Content shown when no safe place is selected
  Widget _buildTelemetryDrawerContent(
    LocationProvider location,
    bool isDark,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Drag Handle & Mini-HUD Header ──
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() => _isDrawerExpanded = !_isDrawerExpanded);
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
            child: Column(
              children: [
                // Grab Handle
                Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(100),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),

                // Collapsed Bar (Google Maps style Mini-HUD)
                if (!_isDrawerExpanded)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 8),
                    child: Row(
                      children: [
                        // Live Status Indicator
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: location.isTracking
                                ? const Color(0xFF43A047)
                                : const Color(0xFFE53935),
                            boxShadow: [
                              BoxShadow(
                                color: (location.isTracking
                                        ? const Color(0xFF43A047)
                                        : const Color(0xFFE53935))
                                    .withAlpha(120),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          location.isTracking
                              ? 'Tracking Active'
                              : 'Tracking Paused',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        // Speed & Distance mini pill badges
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E88E5).withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${location.currentSpeedKmh.toStringAsFixed(1)} km/h',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E88E5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935).withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            location.totalDistanceString,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE53935),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.keyboard_arrow_up_rounded,
                          size: 22,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ── Expanded Content (Telemetry Grid & Primary Action Buttons) ──
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOutCubic,
          child: _isDrawerExpanded
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header title with minimize chevron
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TELEMETRY & CONTROLS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color:
                                  isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 22,
                              color: Colors.grey,
                            ),
                            tooltip: 'Hide Tracking Info',
                            onPressed: () {
                              setState(() => _isDrawerExpanded = false);
                            },
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Telemetry Grid
                      Row(
                        children: [
                          Expanded(
                            child: _TelemetryCard(
                              label: 'SPEED',
                              value:
                                  '${location.currentSpeedKmh.toStringAsFixed(1)} km/h',
                              icon: Icons.speed_rounded,
                              accentColor: const Color(0xFF1E88E5),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _TelemetryCard(
                              label: 'DISTANCE',
                              value: location.totalDistanceString,
                              icon: Icons.route_rounded,
                              accentColor: const Color(0xFFE53935),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _TelemetryCard(
                              label: 'ACCURACY',
                              value:
                                  '±${location.currentAccuracy.toStringAsFixed(0)}m',
                              icon: Icons.gps_fixed_rounded,
                              accentColor: const Color(0xFF43A047),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: _toggleTracking,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: location.isTracking
                                    ? const Color(0xFFD32F2F)
                                    : const Color(0xFF388E3C),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: Icon(
                                location.isTracking
                                    ? Icons.stop_rounded
                                    : Icons.play_arrow_rounded,
                              ),
                              label: Text(
                                location.isTracking
                                    ? 'PAUSE TRACKING'
                                    : 'START LIVE TRACKING',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: OutlinedButton.icon(
                              onPressed: location.hasLocation
                                  ? () => _smsService.shareLocationLink(
                                        location.latitude!,
                                        location.longitude!,
                                      )
                                  : null,
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.share_rounded, size: 18),
                              label: const Text('SHARE'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _TelemetryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;

  const _TelemetryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: accentColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(140),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
