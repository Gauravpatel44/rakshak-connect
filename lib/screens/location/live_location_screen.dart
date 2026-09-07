import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../services/sms_service.dart';

/// Live location screen with OpenStreetMap, Real-Time Breadcrumb Trail, and Speed Telemetry HUD
class LiveLocationScreen extends StatefulWidget {
  const LiveLocationScreen({super.key});

  @override
  State<LiveLocationScreen> createState() => _LiveLocationScreenState();
}

class _LiveLocationScreenState extends State<LiveLocationScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final SmsService _smsService = SmsService();
  late AnimationController _pulseController;
  bool _autoFollow = true;
  LatLng? _lastCenteredPoint;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) => _initLocation());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final locationProvider = context.read<LocationProvider>();
    final authProvider = context.read<AppAuthProvider>();

    await locationProvider.fetchCurrentLocation();
    if (locationProvider.hasLocation) {
      _centerMap();
      // Auto-start live breadcrumbs tracking
      final userId = authProvider.user?.uid ?? '';
      if (userId.isNotEmpty && !locationProvider.isTracking) {
        locationProvider.startLiveTracking(userId: userId);
      }
    }
  }

  void _centerMap() {
    final provider = context.read<LocationProvider>();
    if (!provider.hasLocation) return;
    _mapController.move(
      LatLng(provider.latitude!, provider.longitude!),
      16.5,
    );
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

    // Auto-center map if user enabled autoFollow and position has actually changed
    if (_autoFollow && location.hasLocation) {
      final lat = location.latitude!;
      final lng = location.longitude!;
      if (_lastCenteredPoint == null ||
          _lastCenteredPoint!.latitude != lat ||
          _lastCenteredPoint!.longitude != lng) {
        _lastCenteredPoint = LatLng(lat, lng);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _mapController.move(
              _lastCenteredPoint!,
              _mapController.camera.zoom,
            );
          }
        });
      }
    }

    final polylinePoints = location.polylinePoints;
    final startPoint = polylinePoints.isNotEmpty ? polylinePoints.first : null;
    final currentPoint = location.hasLocation
        ? LatLng(location.latitude!, location.longitude!)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live GPS Tracking'),
        actions: [
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
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Clear Trail',
            onPressed: polylinePoints.isNotEmpty
                ? () => location.clearBreadcrumbs()
                : null,
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── OpenStreetMap ─────────────────────────────────────
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
                  : FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: currentPoint ??
                            const LatLng(20.5937, 78.9629), // India center
                        initialZoom: currentPoint != null ? 16.5 : 5.0,
                        onPositionChanged: (pos, hasGesture) {
                          if (hasGesture && _autoFollow) {
                            setState(() => _autoFollow = false);
                          }
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName:
                              'com.gaurav.rakshak_connect',
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

                        // ── Markers (Start Pin & Moving Radar) ─────────
                        MarkerLayer(
                          markers: [
                            // 1. Initial Start Point Pin
                            if (startPoint != null &&
                                polylinePoints.length > 1)
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
                                    final pulseScale =
                                        1.0 + (_pulseController.value * 0.4);
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
                                              color: const Color(0xFFD32F2F)
                                                  .withAlpha(
                                                (80 *
                                                        (1.0 -
                                                            _pulseController
                                                                .value))
                                                    .toInt(),
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Inner Solid Marker with Heading Angle
                                        Transform.rotate(
                                          angle: (location.currentHeading *
                                                  math.pi) /
                                              180.0,
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
                    ),

          // ── Top Live Tracking Status Badge ─────────────────────
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B).withAlpha(230)
                    : Colors.white.withAlpha(230),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: location.isTracking
                          ? const Color(0xFF4CAF50)
                          : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      location.isTracking
                          ? 'LIVE GPS TRACKING ACTIVE'
                          : 'TRACKING PAUSED',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: location.isTracking
                            ? const Color(0xFF388E3C)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    location.movementMode,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Map Floating Action Controls ────────────────────────
          Positioned(
            right: 16,
            bottom: 240,
            child: Column(
              children: [
                // Auto-Follow / Recenter Button
                FloatingActionButton.small(
                  heroTag: 'recenter_btn',
                  onPressed: () {
                    setState(() => _autoFollow = true);
                    _centerMap();
                  },
                  backgroundColor: _autoFollow
                      ? AppColors.primary
                      : (isDark ? const Color(0xFF1E293B) : Colors.white),
                  foregroundColor: _autoFollow ? Colors.white : AppColors.primary,
                  child: const Icon(Icons.my_location_rounded),
                ),
              ],
            ),
          ),

          // ── Bottom Telemetry & Controls Drawer ──────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(80),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // ── Telemetry Grid ──────────────────────────
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

                  // ── Action Buttons ──────────────────────────
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
                            padding: const EdgeInsets.symmetric(vertical: 14),
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
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
                            padding: const EdgeInsets.symmetric(vertical: 14),
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
            ),
          ),
        ],
      ),
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
