import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../widgets/glassmorphic_card.dart';
import 'camera_capture_screen.dart';
import 'jobs_screen.dart';
import 'library_screen.dart';

class UploadScreen extends StatefulWidget {
  /// Optional pre-captured video file (from camera FAB flow)
  final File? preCapturedVideo;

  const UploadScreen({super.key, this.preCapturedVideo});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();

  // Ingestion Modes
  int _activeTab = 0; // 0 = Stage 2 (Video), 1 = Stage 1 (Direct Splat)

  // Fields
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lonController = TextEditingController();
  final TextEditingController _altController = TextEditingController(text: '0.0');

  String _disasterType = 'landslide';
  String _severity = 'medium';
  File? _selectedFile;
  String? _selectedFileName;

  bool _isLocating = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  final List<String> _disasterTypes = ['landslide', 'flood', 'wildfire', 'earthquake', 'other'];
  final List<String> _severities = ['low', 'medium', 'high', 'critical'];

  @override
  void initState() {
    super.initState();
    // Handle pre-captured video from camera FAB flow
    if (widget.preCapturedVideo != null) {
      _selectedFile = widget.preCapturedVideo;
      _selectedFileName = widget.preCapturedVideo!.path.split('/').last;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _latController.dispose();
    _lonController.dispose();
    _altController.dispose();
    super.dispose();
  }

  // Uses geolocator to fetch device GPS sensors instantly
  Future<void> _fetchGPSCoordinates() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission was denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied, cannot request permissions.');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latController.text = position.latitude.toStringAsFixed(6);
        _lonController.text = position.longitude.toStringAsFixed(6);
        _altController.text = position.altitude.toStringAsFixed(1);
        _isLocating = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GPS coordinates loaded successfully'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      setState(() => _isLocating = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load GPS coordinates: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  /// Launch native camera for video recording
  Future<void> _captureFromCamera() async {
    final File? capturedFile = await Navigator.push<File>(
      context,
      MaterialPageRoute(builder: (context) => const CameraCaptureScreen()),
    );

    if (capturedFile != null && mounted) {
      setState(() {
        _selectedFile = capturedFile;
        _selectedFileName = capturedFile.path.split('/').last;
      });
    }
  }

  /// Pick file from gallery/filesystem
  Future<void> _pickAssetFile() async {
    try {
      final allowedExtensions = _activeTab == 0
          ? ['mp4', 'mov', 'avi']
          : ['ply', 'splat'];

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _selectedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to select file: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  // Form Submission
  Future<void> _submitIngestion() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_activeTab == 0 ? 'Please capture or select a video first' : 'Please select a .splat/.ply model first'),
          backgroundColor: const Color(0xFFF59E0B),
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.2;
    });

    try {
      final lat = double.parse(_latController.text);
      final lon = double.parse(_lonController.text);
      final alt = double.parse(_altController.text);

      if (_activeTab == 0) {
        // --- STAGE 2: Video Reconstruction Ingestion ---
        final job = await _api.uploadDisasterVideo(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          disasterType: _disasterType,
          severity: _severity,
          latitude: lat,
          longitude: lon,
          altitude: alt,
          videoFile: _selectedFile!,
        );

        setState(() {
          _isUploading = false;
          _uploadProgress = 1.0;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video uploaded successfully. Job ID: ${job.id}'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const JobsScreen()),
        );
      } else {
        // --- STAGE 1: Direct Splat Ingestion ---
        final splat = await _api.createSplatMetadata(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          disasterType: _disasterType,
          severity: _severity,
          latitude: lat,
          longitude: lon,
          altitude: alt,
        );

        await _api.uploadDirectSplatFile(splat.id, _selectedFile!);

        setState(() {
          _isUploading = false;
          _uploadProgress = 1.0;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('3D model uploaded and registered successfully'),
            backgroundColor: Color(0xFF10B981),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LibraryScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ingestion failed: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _activeTab == 0 ? const Color(0xFF10B981) : const Color(0xFF6366F1);

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
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
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
                                'Capture & Upload',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Record video or upload 3D model',
                                style: TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Segmented Mode Selectors
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _activeTab = 0;
                                    _selectedFile = null;
                                    _selectedFileName = null;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _activeTab == 0 ? const Color(0xFF10B981).withValues(alpha: 0.15) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    border: _activeTab == 0 ? Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)) : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.videocam_rounded,
                                        size: 18,
                                        color: _activeTab == 0 ? const Color(0xFF34D399) : Colors.white60,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Video Capture',
                                        style: TextStyle(
                                          color: _activeTab == 0 ? Colors.white : Colors.white60,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _activeTab = 1;
                                    _selectedFile = null;
                                    _selectedFileName = null;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _activeTab == 1 ? const Color(0xFF6366F1).withValues(alpha: 0.15) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    border: _activeTab == 1 ? Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)) : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.view_in_ar,
                                        size: 18,
                                        color: _activeTab == 1 ? const Color(0xFFA5B4FC) : Colors.white60,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Direct PLY/SPLAT',
                                        style: TextStyle(
                                          color: _activeTab == 1 ? Colors.white : Colors.white60,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
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
                      const SizedBox(height: 24),

                      // ========== MEDIA CAPTURE SECTION (Camera-First) ==========
                      if (_activeTab == 0) ...[
                        _buildVideoMediaSection(accentColor),
                      ] else ...[
                        _buildDirectSplatSection(accentColor),
                      ],

                      const SizedBox(height: 24),

                      // ========== FORM FIELDS ==========
                      GlassmorphicCard(
                        borderColor: accentColor.withValues(alpha: 0.2),
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SPATIAL INCIDENT TAGS',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.1,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Title Field
                            _buildLabel('Incident Title / Location Name'),
                            TextFormField(
                              controller: _titleController,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: _buildInputDecoration('e.g. Kathmandu Mudslide Area A'),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
                            ),
                            const SizedBox(height: 16),

                            // Description Field
                            _buildLabel('Damage Description'),
                            TextFormField(
                              controller: _descController,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              maxLines: 3,
                              decoration: _buildInputDecoration('Describe the spatial scope / severeness...'),
                            ),
                            const SizedBox(height: 16),

                            // Disaster Type & Severity dropdowns
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('Disaster Type'),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.black26,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.white12),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            dropdownColor: const Color(0xFF131526),
                                            value: _disasterType,
                                            style: const TextStyle(color: Colors.white, fontSize: 13),
                                            icon: const Icon(Icons.arrow_drop_down, color: Colors.white38),
                                            isExpanded: true,
                                            items: _disasterTypes.map((type) {
                                              return DropdownMenuItem(
                                                value: type,
                                                child: Text(type.toUpperCase()),
                                              );
                                            }).toList(),
                                            onChanged: (val) {
                                              if (val != null) {
                                                setState(() => _disasterType = val);
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('Severity Level'),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.black26,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.white12),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            dropdownColor: const Color(0xFF131526),
                                            value: _severity,
                                            style: const TextStyle(color: Colors.white, fontSize: 13),
                                            icon: const Icon(Icons.arrow_drop_down, color: Colors.white38),
                                            isExpanded: true,
                                            items: _severities.map((sev) {
                                              return DropdownMenuItem(
                                                value: sev,
                                                child: Text(sev.toUpperCase()),
                                              );
                                            }).toList(),
                                            onChanged: (val) {
                                              if (val != null) {
                                                setState(() => _severity = val);
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 25),

                            const Divider(color: Colors.white10),
                            const SizedBox(height: 15),

                            // Geolocation
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'WGS84 COORDINATES',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFFA5B4FC),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                  onPressed: _isLocating ? null : _fetchGPSCoordinates,
                                  icon: _isLocating
                                      ? const SizedBox(
                                          width: 10,
                                          height: 10,
                                          child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFFA5B4FC)),
                                        )
                                      : const Icon(Icons.my_location, size: 12),
                                  label: const Text('GET GPS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('Latitude'),
                                      TextFormField(
                                        controller: _latController,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
                                        decoration: _buildInputDecoration('27.7172'),
                                        validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Required';
                                          final d = double.tryParse(val);
                                          if (d == null || d < -90.0 || d > 90.0) return 'Invalid';
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('Longitude'),
                                      TextFormField(
                                        controller: _lonController,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
                                        decoration: _buildInputDecoration('85.3240'),
                                        validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Required';
                                          final d = double.tryParse(val);
                                          if (d == null || d < -180.0 || d > 180.0) return 'Invalid';
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('Altitude (m)'),
                                      TextFormField(
                                        controller: _altController,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
                                        decoration: _buildInputDecoration('1400.0'),
                                        validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Required';
                                          if (double.tryParse(val) == null) return 'Invalid';
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            onPressed: _isUploading ? null : _submitIngestion,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _activeTab == 0 ? Icons.cloud_upload_outlined : Icons.add_circle_outline,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _activeTab == 0 ? 'TRIGGER AI RECONSTRUCTION' : 'INGEST & SAVE 3D SPLAT',
                                  style: const TextStyle(
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
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // Uploading overlay panel
              if (_isUploading)
                BackdropFilter(
                  filter: const ColorFilter.mode(Colors.black87, BlendMode.darken),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: GlassmorphicCard(
                        borderColor: accentColor.withValues(alpha: 0.3),
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'TRANSMITTING MULTIPART CHUNKS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.05,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Pushing binary arrays to FastAPI backend. Keep the app open.',
                              style: TextStyle(color: Colors.white54, fontSize: 11),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            LinearProgressIndicator(
                              value: _uploadProgress,
                              color: accentColor,
                              backgroundColor: Colors.white10,
                              minHeight: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Camera-first video media source section
  Widget _buildVideoMediaSection(Color accentColor) {
    return GlassmorphicCard(
      borderColor: accentColor.withValues(alpha: 0.2),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'VIDEO SOURCE',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 16),

          // Primary CTA: Camera Record Button
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A2E),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                  ),
                  elevation: 0,
                ),
                onPressed: _captureFromCamera,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                      child: Center(
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Record Video',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Use camera to capture disaster footage',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Secondary: Gallery Picker
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: const BorderSide(color: Colors.white12),
              ),
              onPressed: _pickAssetFile,
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: const Text(
                'Choose from Gallery',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Selected File Preview
          if (_selectedFile != null) _buildFilePreview(accentColor),
        ],
      ),
    );
  }

  /// Direct PLY/SPLAT file selection section
  Widget _buildDirectSplatSection(Color accentColor) {
    return GlassmorphicCard(
      borderColor: accentColor.withValues(alpha: 0.2),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BINARY INGESTION ASSET',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickAssetFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accentColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.view_in_ar_outlined,
                    size: 32,
                    color: accentColor,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _selectedFileName ?? 'Click to select .splat or .ply file',
                    style: TextStyle(
                      color: _selectedFileName != null ? Colors.white : Colors.white38,
                      fontSize: 12,
                      fontWeight: _selectedFileName != null ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_selectedFile != null) ...[
                    const SizedBox(height: 6),
                    FutureBuilder<int>(
                      future: _selectedFile!.length(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final mb = snapshot.data! / (1024 * 1024);
                          return Text(
                            'Size: ${mb.toStringAsFixed(2)} MB',
                            style: const TextStyle(color: Colors.white30, fontSize: 11),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// File preview widget showing selected/captured file info
  Widget _buildFilePreview(Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.videocam_rounded, color: accentColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedFileName ?? 'Unknown',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                FutureBuilder<int>(
                  future: _selectedFile!.length(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final mb = snapshot.data! / (1024 * 1024);
                      return Text(
                        '${mb.toStringAsFixed(2)} MB • Ready to upload',
                        style: TextStyle(color: accentColor, fontSize: 11),
                      );
                    }
                    return const Text(
                      'Calculating size...',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    );
                  },
                ),
              ],
            ),
          ),
          // Remove file button
          IconButton(
            onPressed: () {
              setState(() {
                _selectedFile = null;
                _selectedFileName = null;
              });
            },
            icon: const Icon(Icons.close, color: Colors.white38, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              padding: const EdgeInsets.all(6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
      filled: true,
      fillColor: Colors.black12,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white24),
      ),
    );
  }
}
