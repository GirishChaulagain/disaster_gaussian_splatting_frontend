import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/splat_capture.dart';
import '../models/processing_job.dart';
import '../widgets/glassmorphic_card.dart';
import '../widgets/status_badge.dart';
import 'viewer_screen.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _activeJobsData = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchJobs();
    // Auto-refresh queue list every 4 seconds to observe real-time progression
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) => _fetchJobs(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchJobs({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }
    try {
      // 1. Fetch all georeferenced records globally
      final allSplats = await _api.searchSplatsByRadius(
        latitude: 27.7172,
        longitude: 85.3240,
        radiusKm: 20000.0,
      );

      // 2. Filter down to pending, processing, or failed records
      final activeSplats = allSplats.where((s) => s.status != 'completed').toList();

      final List<Map<String, dynamic>> jobsAccumulator = [];

      for (var splat in activeSplats) {
        try {
          final job = await _api.getJobByCapture(splat.id);
          jobsAccumulator.add({
            'splat': splat,
            'job': job,
          });
        } catch (e) {
          // If no job was created yet, create a dummy local job shell
          jobsAccumulator.add({
            'splat': splat,
            'job': ProcessingJob(
              id: 'dummy',
              captureId: splat.id,
              progress: splat.status == 'failed' ? 0 : 5,
              statusMessage: splat.status == 'failed' ? 'Job aborted due to errors' : 'Awaiting worker handoff...',
              createdAt: splat.createdAt,
              updatedAt: splat.updatedAt,
            ),
          });
        }
      }

      // Sort by creation time desc
      jobsAccumulator.sort((a, b) => (b['splat'] as SplatCapture).createdAt.compareTo((a['splat'] as SplatCapture).createdAt));

      if (mounted) {
        setState(() {
          _activeJobsData = jobsAccumulator;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reload queue: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _showLogsDialog(String captureTitle, String? errorLog) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0A0C16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white10, width: 1.2),
          ),
          title: Row(
            children: [
              const Icon(Icons.terminal, color: Color(0xFFEF4444)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'CLI Log: $captureTitle',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            height: 300,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: SingleChildScrollView(
              child: Text(
                errorLog ?? 'No debug logging was output by the celery tasks worker.',
                style: const TextStyle(
                  color: Color(0xFFFCA5A5), // Light red
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('DISMISS', style: TextStyle(color: Colors.white54)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        padding: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reconstruction Queue',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Asynchronous background Celery worker jobs',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Subtext warning about polling
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.autorenew, size: 14, color: Color(0xFFFBBF24)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Auto-refreshing progress parameters in 4s loops...',
                          style: TextStyle(color: Color(0xFFFBBF24), fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Queue List
              Expanded(
                child: _isLoading && _activeJobsData.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                      )
                    : _activeJobsData.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.cloud_done_outlined, size: 48, color: Colors.white24),
                                const SizedBox(height: 12),
                                const Text(
                                  'Queue is Empty',
                                  style: TextStyle(color: Colors.white60, fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'All 3D Gaussian Splats are active and fully built.',
                                  style: TextStyle(color: Colors.white30, fontSize: 12),
                                ),
                                const SizedBox(height: 15),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () => _fetchJobs(),
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text('CHECK AGAIN'),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _fetchJobs(),
                            color: const Color(0xFF6366F1),
                            backgroundColor: const Color(0xFF131526),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              itemCount: _activeJobsData.length,
                              itemBuilder: (context, index) {
                                final data = _activeJobsData[index];
                                final SplatCapture splat = data['splat'];
                                final ProcessingJob job = data['job'];
                                final accentColor = splat.status == 'failed' ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: GlassmorphicCard(
                                    borderColor: accentColor.withValues(alpha: 0.2),
                                    padding: const EdgeInsets.all(18),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Header: Title and Type
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
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        splat.disasterType.toUpperCase(),
                                                        style: const TextStyle(
                                                          color: Colors.white38,
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        width: 4,
                                                        height: 4,
                                                        decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'Severity: ${splat.severity}',
                                                        style: const TextStyle(
                                                          color: Colors.white38,
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            StatusBadge(status: splat.status),
                                          ],
                                        ),
                                        const SizedBox(height: 20),

                                        // Progress Loader
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'PROGRESS STATUS: ${job.progress}%',
                                              style: TextStyle(
                                                color: accentColor,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'Anchor: ${splat.latitude.toStringAsFixed(4)}, ${splat.longitude.toStringAsFixed(4)}',
                                              style: const TextStyle(
                                                color: Colors.white30,
                                                fontFamily: 'monospace',
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        LinearProgressIndicator(
                                          value: job.progress / 100.0,
                                          color: accentColor,
                                          backgroundColor: Colors.white10,
                                          minHeight: 4,
                                        ),
                                        const SizedBox(height: 12),

                                        // Live Status Message from FastAPI task context
                                        Row(
                                          children: [
                                            Icon(
                                              splat.status == 'failed' ? Icons.error_outline : Icons.slow_motion_video,
                                              size: 14,
                                              color: Colors.white54,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                job.statusMessage,
                                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                                              ),
                                            ),
                                          ],
                                        ),

                                        // Action CTAs (Logs or Launch)
                                        if (splat.status == 'failed' && job.errorLog != null) ...[
                                          const SizedBox(height: 15),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                                foregroundColor: const Color(0xFFF87171),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                  side: const BorderSide(color: Color(0x3DF87171)),
                                                ),
                                              ),
                                              onPressed: () => _showLogsDialog(splat.title, job.errorLog),
                                              icon: const Icon(Icons.bug_report_outlined, size: 16),
                                              label: const Text('INSPECT PIPELINE EXCEPTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                        ],

                                        // If dynamically finished during current viewport session
                                        if (splat.status == 'completed' && splat.fileUrl != null) ...[
                                          const SizedBox(height: 15),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF10B981),
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => ViewerScreen(splat: splat),
                                                  ),
                                                );
                                              },
                                              icon: const Icon(Icons.view_in_ar, size: 16),
                                              label: const Text('LAUNCH 3D VIEWER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
