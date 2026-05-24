import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import '../models/splat_capture.dart';
import '../widgets/glassmorphic_card.dart';
import '../widgets/status_badge.dart';
import 'viewer_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final ApiService _api = ApiService();
  final MapController _mapController = MapController();

  // Search Parameters
  LatLng _searchCenter = const LatLng(27.7172, 85.3240); // Default to Kathmandu
  double _radiusKm = 10.0;
  bool _isSearching = false;
  List<SplatCapture> _matchingSplats = [];

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  Future<void> _performSearch() async {
    setState(() => _isSearching = true);
    try {
      final results = await _api.searchSplatsByRadius(
        latitude: _searchCenter.latitude,
        longitude: _searchCenter.longitude,
        radiusKm: _radiusKm,
      );
      setState(() {
        _matchingSplats = results;
        _isSearching = false;
      });
      if (results.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No active splats found within search radius'),
            backgroundColor: Color(0xFFF59E0B),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _showSplatDetailsSheet(SplatCapture splat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black45,
      isScrollControlled: true,
      builder: (context) {
        return BackdropFilter(
          filter: const ColorFilter.mode(Colors.black38, BlendMode.darken),
          child: Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF0E101F),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: Colors.white10, width: 1.5)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handlebar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title and Badges
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                splat.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  SeverityBadge(severity: splat.severity),
                                  const SizedBox(width: 8),
                                  StatusBadge(status: splat.status),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Mini Disaster Icon
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                          ),
                          child: Icon(
                            _getDisasterIcon(splat.disasterType),
                            color: const Color(0xFF6366F1),
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Description
                    if (splat.description != null && splat.description!.isNotEmpty) ...[
                      const Text(
                        'DAMAGE REPORT / METADATA',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        splat.description!,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.84), fontSize: 14, height: 1.4),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Coordinates & Metrics Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetaField(
                            'COORDINATES (LAT, LON)',
                            '${splat.latitude.toStringAsFixed(5)}, ${splat.longitude.toStringAsFixed(5)}',
                          ),
                        ),
                        Expanded(
                          child: _buildMetaField(
                            'ELEVATION/ALTITUDE',
                            '${splat.altitude.toStringAsFixed(1)} m',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetaField(
                            'ORIENTATION (P, Y, R)',
                            '${splat.pitch.toStringAsFixed(1)}°, ${splat.yaw.toStringAsFixed(1)}°, ${splat.roll.toStringAsFixed(1)}°',
                          ),
                        ),
                        Expanded(
                          child: _buildMetaField(
                            'SCALE FACTOR (X, Y, Z)',
                            '${splat.scaleX.toStringAsFixed(1)}x, ${splat.scaleY.toStringAsFixed(1)}x, ${splat.scaleZ.toStringAsFixed(1)}x',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Launch CTA Button
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.pop(context); // Close sheet
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ViewerScreen(splat: splat),
                              ),
                            );
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.view_in_ar, color: Colors.white),
                              SizedBox(width: 10),
                              Text(
                                'LAUNCH 3D GAUSSIAN SPLAT VIEWER',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.05,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetaField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.05,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  IconData _getDisasterIcon(String type) {
    switch (type.toLowerCase()) {
      case 'wildfire':
        return Icons.local_fire_department;
      case 'flood':
        return Icons.water_damage;
      case 'landslide':
        return Icons.terrain;
      case 'earthquake':
        return Icons.grid_goldenratio;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return const Color(0xFFEF4444); // Crimson red
      case 'high':
        return const Color(0xFFF59E0B); // Amber
      case 'medium':
        return const Color(0xFF3B82F6); // Blue
      default:
        return const Color(0xFF10B981); // Emerald
    }
  }

  @override
  Widget build(BuildContext context) {
    // Generate map markers
    final List<Marker> markers = [];

    // 1. Search Center anchor marker
    markers.add(
      Marker(
        point: _searchCenter,
        width: 60,
        height: 60,
        alignment: Alignment.center,
        child: Container(
          decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.2),
            shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF6366F1), width: 2),
          ),
          child: const Center(
            child: Icon(Icons.gps_fixed, color: Color(0xFF6366F1), size: 20),
          ),
        ),
      ),
    );

    // 2. Splat asset markers
    for (var splat in _matchingSplats) {
      final color = _getSeverityColor(splat.severity);
      markers.add(
        Marker(
          point: LatLng(splat.latitude, splat.longitude),
          width: 45,
          height: 45,
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () => _showSplatDetailsSheet(splat),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0E101F),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  _getDisasterIcon(splat.disasterType),
                  color: color,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Flutter Map Canvas
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _searchCenter,
              initialZoom: 13.0,
              maxZoom: 18.0,
              minZoom: 2.0,
              onTap: (tapPosition, latLng) {
                setState(() {
                  _searchCenter = latLng;
                });
              },
            ),
            children: [
              // Premium Dark Mode Cartography Tiles
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.disastersplatting.frontend',
              ),

              // Radius Translucent Circle Overlay
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _searchCenter,
                    radius: _radiusKm * 1000, // Convert km to meters
                    useRadiusInMeter: true,
                    color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                    borderColor: const Color(0xFF6366F1).withValues(alpha: 0.35),
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),

              // Markers layer
              MarkerLayer(markers: markers),
            ],
          ),

          // Floating Top Bar with sliders (Radius Config)
          Positioned(
            top: 50,
            left: 15,
            right: 15,
            child: GlassmorphicCard(
              blur: 15,
              opacity: 0.7,
              borderColor: Colors.white10,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Back button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      padding: const EdgeInsets.all(10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'SPATIAL RADAR QUERY',
                          style: TextStyle(
                            color: Color(0xFFA5B4FC),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.05,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'Radius: ${_radiusKm.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              ' (Tap map to move origin)',
                              style: TextStyle(color: Colors.white38, fontSize: 10),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2.0,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                            activeTrackColor: const Color(0xFF6366F1),
                            inactiveTrackColor: Colors.white10,
                            thumbColor: const Color(0xFF6366F1),
                          ),
                          child: Slider(
                            value: _radiusKm,
                            min: 1.0,
                            max: 100.0,
                            onChanged: (val) {
                              setState(() {
                                _radiusKm = val;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Search Trigger Button
                  IconButton(
                    onPressed: _isSearching ? null : _performSearch,
                    icon: _isSearching
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.search, color: Colors.white, size: 22),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      disabledBackgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.5),
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
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
