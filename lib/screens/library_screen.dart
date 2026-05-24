import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/splat_capture.dart';
import '../widgets/glassmorphic_card.dart';
import '../widgets/status_badge.dart';
import 'viewer_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = false;
  List<SplatCapture> _allSplats = [];
  List<SplatCapture> _filteredSplats = [];

  // Search & Filtering States
  final TextEditingController _searchController = TextEditingController();
  String _activeTypeFilter = 'all';
  String _activeStatusFilter = 'all';

  final List<String> _types = ['all', 'landslide', 'flood', 'wildfire', 'earthquake', 'other'];
  final List<String> _statuses = ['all', 'completed', 'processing', 'pending', 'failed'];

  @override
  void initState() {
    super.initState();
    _fetchSplats();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSplats() async {
    setState(() => _isLoading = true);
    try {
      // Query globally (Kathmandu center with giant radius fetches all items)
      final results = await _api.searchSplatsByRadius(
        latitude: 27.7172,
        longitude: 85.3240,
        radiusKm: 20000.0,
      );

      // Sort by newest first
      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) {
        setState(() {
          _allSplats = results;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load captures: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();
    List<SplatCapture> workingList = List.from(_allSplats);

    // 1. Text Search Filter
    if (query.isNotEmpty) {
      workingList = workingList.where((splat) {
        final titleMatch = splat.title.toLowerCase().contains(query);
        final descMatch = splat.description?.toLowerCase().contains(query) ?? false;
        return titleMatch || descMatch;
      }).toList();
    }

    // 2. Disaster Type Filter
    if (_activeTypeFilter != 'all') {
      workingList = workingList.where((splat) => splat.disasterType.toLowerCase() == _activeTypeFilter).toList();
    }

    // 3. Status Filter
    if (_activeStatusFilter != 'all') {
      workingList = workingList.where((splat) => splat.status.toLowerCase() == _activeStatusFilter).toList();
    }

    setState(() {
      _filteredSplats = workingList;
    });
  }

  Future<void> _deleteSplat(SplatCapture splat) async {
    // Show a confirm Dialog first
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF131526),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white10, width: 1.2),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
              SizedBox(width: 10),
              Text(
                'Delete Capture Metadata?',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${splat.title}"? This will permanently erase coordinates, database attributes, and binary .splat files from server disk storage.',
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL', style: TextStyle(color: Colors.white38)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ERASE NOW', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _api.deleteSplatCapture(splat.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Splat capture deleted successfully'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      _fetchSplats(); // Reload
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete splat: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
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
              // Header Row
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
                          'Splat Library',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Review and manage registered 3D captures',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Colors.white30, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white30, size: 16),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    hintText: 'Search by title, location or keywords...',
                    hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                    filled: true,
                    fillColor: Colors.black26,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Colors.white10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF6366F1)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Filter Tabs (Type and Status)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    // Type Filter Chips
                    ..._types.map((type) {
                      final isActive = _activeTypeFilter == type;
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(type.toUpperCase()),
                          selected: isActive,
                          onSelected: (selected) {
                            setState(() => _activeTypeFilter = type);
                            _applyFilters();
                          },
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          selectedColor: const Color(0xFF6366F1).withValues(alpha: 0.2),
                          checkmarkColor: const Color(0xFFA5B4FC),
                          labelStyle: TextStyle(
                            color: isActive ? const Color(0xFFA5B4FC) : Colors.white60,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isActive ? const Color(0xFF6366F1) : Colors.white10,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 5),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    // Status Filter Chips
                    ..._statuses.map((status) {
                      final isActive = _activeStatusFilter == status;
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(status.toUpperCase()),
                          selected: isActive,
                          onSelected: (selected) {
                            setState(() => _activeStatusFilter = status);
                            _applyFilters();
                          },
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          selectedColor: const Color(0xFF10B981).withValues(alpha: 0.2),
                          checkmarkColor: const Color(0xFF34D399),
                          labelStyle: TextStyle(
                            color: isActive ? const Color(0xFF34D399) : Colors.white60,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isActive ? const Color(0xFF10B981) : Colors.white10,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              // Library list
              Expanded(
                child: _isLoading && _filteredSplats.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                      )
                    : _filteredSplats.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.folder_open_outlined, size: 48, color: Colors.white24),
                                const SizedBox(height: 12),
                                const Text(
                                  'No splats found',
                                  style: TextStyle(color: Colors.white60, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Refine filters or complete active training jobs.',
                                  style: TextStyle(color: Colors.white30, fontSize: 11),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchSplats,
                            color: const Color(0xFF6366F1),
                            backgroundColor: const Color(0xFF131526),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              itemCount: _filteredSplats.length,
                              itemBuilder: (context, index) {
                                final splat = _filteredSplats[index];
                                final isCompleted = splat.status == 'completed';
                                final accentColor = isCompleted ? const Color(0xFF6366F1) : const Color(0xFF9CA3AF);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: GlassmorphicCard(
                                    borderColor: accentColor.withValues(alpha: 0.2),
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Header Row: Title and status tags
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
                                            // Delete Trash button
                                            IconButton(
                                              onPressed: () => _deleteSplat(splat),
                                              icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                                              style: IconButton.styleFrom(
                                                backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.08),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),

                                        // Description text
                                        if (splat.description != null && splat.description!.isNotEmpty) ...[
                                          Text(
                                            splat.description!,
                                            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 14),
                                        ],

                                        // Geospatial indicators
                                        Row(
                                          children: [
                                            _buildMetaIndicator(Icons.location_on_outlined,
                                                '${splat.latitude.toStringAsFixed(4)}, ${splat.longitude.toStringAsFixed(4)}'),
                                            const SizedBox(width: 14),
                                            _buildMetaIndicator(Icons.terrain_outlined, '${splat.altitude.toStringAsFixed(0)} m'),
                                            const SizedBox(width: 14),
                                            _buildMetaIndicator(Icons.category_outlined, splat.disasterType.toUpperCase()),
                                          ],
                                        ),

                                        // Launch 3D button
                                        if (isCompleted && splat.fileUrl != null) ...[
                                          const SizedBox(height: 18),
                                          SizedBox(
                                            width: double.infinity,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(10),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF6366F1),
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                  elevation: 0,
                                                ),
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => ViewerScreen(splat: splat),
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(Icons.view_in_ar, size: 16, color: Colors.white),
                                                label: const Text(
                                                  'LAUNCH 3D SPLAT VIEWER',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                    letterSpacing: 0.05,
                                                  ),
                                                ),
                                              ),
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

  Widget _buildMetaIndicator(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white30, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
