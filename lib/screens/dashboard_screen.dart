import 'dart:io';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/glassmorphic_card.dart';
import 'camera_capture_screen.dart';
import 'map_screen.dart';
import 'upload_screen.dart';
import 'jobs_screen.dart';
import 'library_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = false;
  int _totalSplats = 0;
  int _completedSplats = 0;
  int _failedSplats = 0;
  int _processingJobs = 0;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    try {
      // Query completed splats around Kathmandu center (with huge radius to get all models)
      final allSplats = await _api.searchSplatsByRadius(
        latitude: 27.7172,
        longitude: 85.3240,
        radiusKm: 20000.0, // Large radius to cover everything
      );

      int completed = 0;
      int failed = 0;
      int pendingOrProcessing = 0;

      for (var splat in allSplats) {
        if (splat.status == 'completed') {
          completed++;
        } else if (splat.status == 'failed') {
          failed++;
        } else {
          pendingOrProcessing++;
        }
      }

      setState(() {
        _totalSplats = allSplats.length;
        _completedSplats = completed;
        _failedSplats = failed;
        _processingJobs = pendingOrProcessing;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Fail silently or show error in debug console
      debugPrint('Failed to load stats: $e');
    }
  }

  void _showApiSettingsDialog() {
    final TextEditingController controller = TextEditingController(text: _api.baseUrl);

    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: const ColorFilter.mode(Colors.black54, BlendMode.darken),
          child: AlertDialog(
            backgroundColor: const Color(0xFF131526),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.white10, width: 1.2),
            ),
            title: const Row(
              children: [
                Icon(Icons.settings, color: Color(0xFF6366F1)),
                SizedBox(width: 10),
                Text(
                  'Server Configuration',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set the backend API host address:',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.link, color: Colors.white30),
                    hintText: 'http://127.0.0.1:8000',
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF6366F1)),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL', style: TextStyle(color: Colors.white38)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  setState(() {
                    _api.baseUrl = controller.text.trim();
                  });
                  Navigator.pop(context);
                  _fetchStats();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('API Base URL updated: ${_api.baseUrl}'),
                      backgroundColor: const Color(0xFF6366F1),
                    ),
                  );
                },
                child: const Text('SAVE CONFIG', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0C16), Color(0xFF121424)],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _fetchStats,
            color: const Color(0xFF6366F1),
            backgroundColor: const Color(0xFF131526),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Block
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF10B981),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'ONLINE AI ENGINE',
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Splatting Hub',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: _showApiSettingsDialog,
                        icon: const Icon(Icons.settings, color: Colors.white70),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          padding: const EdgeInsets.all(12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // API Address Chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.dns_outlined, size: 14, color: Color(0xFFA5B4FC)),
                        const SizedBox(width: 6),
                        Text(
                          'HOST: ${_api.baseUrl}',
                          style: const TextStyle(
                            color: Color(0xFFA5B4FC),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Metrics Title
                  const Text(
                    'Spatial Network Metrics',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.05,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Glowing Statistics Grid
                  GridView.count(
                    crossAxisCount: width > 600 ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.3,
                    children: [
                      _buildMetricCard(
                        'Total Captures',
                        '$_totalSplats',
                        const Color(0xFF6366F1),
                        Icons.satellite_alt,
                      ),
                      _buildMetricCard(
                        'Active Splats',
                        '$_completedSplats',
                        const Color(0xFF10B981),
                        Icons.layers,
                      ),
                      _buildMetricCard(
                        'Training Queue',
                        '$_processingJobs',
                        const Color(0xFFF59E0B),
                        Icons.pending_actions,
                      ),
                      _buildMetricCard(
                        'Failed Jobs',
                        '$_failedSplats',
                        const Color(0xFFEF4444),
                        Icons.error_outline,
                      ),
                    ],
                  ),
                  const SizedBox(height: 35),

                  // Quick Launchpad
                  const Text(
                    'Task Navigation Launchpad',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.05,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Dynamic Custom Navigation Buttons
                  _buildNavCard(
                    context,
                    title: 'Geospatial Radar Map',
                    subtitle: 'Locate completed 3D splats in a Radius',
                    color: const Color(0xFF6366F1),
                    icon: Icons.map_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MapScreen()),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildNavCard(
                    context,
                    title: 'Upload & Trigger Reconstruction',
                    subtitle: 'Direct splat files or drone video clips',
                    color: const Color(0xFF10B981),
                    icon: Icons.video_call_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UploadScreen()),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildNavCard(
                    context,
                    title: 'Active Reconstruction Queue',
                    subtitle: 'Monitor background Celery model outputs',
                    color: const Color(0xFFF59E0B),
                    icon: Icons.cloud_sync_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const JobsScreen()),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildNavCard(
                    context,
                    title: 'Splat Capture Library',
                    subtitle: 'Manage spatial tags and downloaded .ply',
                    color: const Color(0xFF8B5CF6),
                    icon: Icons.folder_open_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LibraryScreen()),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final navigator = Navigator.of(context);
          final File? video = await Navigator.push<File>(
            context,
            MaterialPageRoute(builder: (context) => const CameraCaptureScreen()),
          );
          if (video != null && mounted) {
            navigator.push(
              MaterialPageRoute(
                builder: (context) => UploadScreen(preCapturedVideo: video),
              ),
            );
          }
        },
        backgroundColor: const Color(0xFFEF4444),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.videocam_rounded),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color accentColor, IconData icon) {
    return GlassmorphicCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderColor: accentColor.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.white30, size: 20),
              if (_isLoading)
                const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white24),
                )
              else
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: GlassmorphicCard(
            blur: 15,
            opacity: 0.05,
            borderColor: color.withValues(alpha: 0.25),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                // Glowing Icon container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.3), width: 1.2),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
