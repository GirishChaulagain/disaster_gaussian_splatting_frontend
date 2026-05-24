import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';
import '../services/api_service.dart';
import '../models/splat_capture.dart';
import '../widgets/glassmorphic_card.dart';

class ViewerScreen extends StatefulWidget {
  final SplatCapture splat;

  const ViewerScreen({super.key, required this.splat});

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  final ApiService _api = ApiService();
  late final WebViewController _webViewController;
  bool _isWebViewLoading = true;
  bool _isSaving = false;

  // Calibration Slider States
  double _roll = 0.0;
  double _pitch = 0.0;
  double _yaw = 0.0;
  double _scaleX = 1.0;
  double _scaleY = 1.0;
  double _scaleZ = 1.0;

  bool _showCalibrationPanel = false;

  @override
  void initState() {
    super.initState();
    // Initialize orientation parameters
    _roll = widget.splat.roll;
    _pitch = widget.splat.pitch;
    _yaw = widget.splat.yaw;
    _scaleX = widget.splat.scaleX;
    _scaleY = widget.splat.scaleY;
    _scaleZ = widget.splat.scaleZ;

    _initWebViewController();
  }

  Future<void> _initWebViewController() async {
    // 1. Build full URL to serve splat file packets
    // If the splat file URL is relative, prepend baseUrl
    final splatFileUrl = widget.splat.fileUrl!.startsWith('http')
        ? widget.splat.fileUrl!
        : '${_api.baseUrl}${widget.splat.fileUrl}';

    // 2. Load the HTML source code from assets folder
    String htmlContent = await rootBundle.loadString('assets/viewer/index.html');

    // 3. Inject parameters directly into query arguments or data parameters
    final Map<String, String> queryParams = {
      'url': splatFileUrl,
      'title': widget.splat.title,
      'roll': _roll.toString(),
      'pitch': _pitch.toString(),
      'yaw': _yaw.toString(),
      'scale_x': _scaleX.toString(),
      'scale_y': _scaleY.toString(),
      'scale_z': _scaleZ.toString(),
    };

    final uri = Uri.dataFromString(
      htmlContent,
      mimeType: 'text/html',
      encoding: utf8,
    ).replace(queryParameters: queryParams);

    // 4. Configure native webview controller
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0A0C16))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isWebViewLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isWebViewLoading = false);
            _updateWebGLCalibration();
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebGL WebView resource error: ${error.description}');
          },
        ),
      )
      ..loadRequest(uri);
  }

  // Evaluates Javascript inside the WebGL context to shift matrix orientations instantly
  void _updateWebGLCalibration() {
    if (_isWebViewLoading) return;
    
    _webViewController.runJavaScript(
      'if (window.updateCalibration) { window.updateCalibration($_roll, $_pitch, $_yaw, $_scaleX, $_scaleY, $_scaleZ); }',
    );
  }

  // Commits the current Pitch, Yaw, Roll and Scale parameters to the FastAPI SQL DB
  Future<void> _saveCalibration() async {
    setState(() => _isSaving = true);
    try {
      await _api.updateSplatCalibration(
        widget.splat.id,
        roll: _roll,
        pitch: _pitch,
        yaw: _yaw,
        scaleX: _scaleX,
        scaleY: _scaleY,
        scaleZ: _scaleZ,
      );

      setState(() {
        _isSaving = false;
        _showCalibrationPanel = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('3D orientation calibration saved successfully'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save calibration: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C16),
      body: SafeArea(
        child: Stack(
          children: [
            // Embedded 3D WebGL Canvas
            WebViewWidget(controller: _webViewController),

            // Top Overlay Control Bar
            Positioned(
              top: 15,
              left: 15,
              right: 15,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  Row(
                    children: [
                      // Calibration Toggle Button
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _showCalibrationPanel = !_showCalibrationPanel;
                          });
                        },
                        icon: Icon(
                          _showCalibrationPanel ? Icons.tune : Icons.tune_outlined,
                          color: _showCalibrationPanel ? const Color(0xFFA5B4FC) : Colors.white70,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: _showCalibrationPanel ? const Color(0xFF6366F1).withValues(alpha: 0.3) : Colors.black54,
                          padding: const EdgeInsets.all(12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: _showCalibrationPanel ? const BorderSide(color: Color(0xFF6366F1), width: 1.2) : BorderSide.none,
                          ),
                        ),
                      ),
                      if (_showCalibrationPanel) ...[
                        const SizedBox(width: 8),
                        // Save Button
                        IconButton(
                          onPressed: _isSaving ? null : _saveCalibration,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.save_outlined, color: Color(0xFF34D399)),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.2),
                            padding: const EdgeInsets.all(12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFF10B981), width: 1.2),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Sliding Calibration Settings Slider Sheet
            if (_showCalibrationPanel)
              Positioned(
                bottom: 20,
                left: 15,
                right: 15,
                child: GlassmorphicCard(
                  blur: 20,
                  opacity: 0.85,
                  borderColor: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '3D CALIBRATION ENGINE',
                            style: TextStyle(
                              color: Color(0xFFA5B4FC),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.05,
                            ),
                          ),
                          Text(
                            'Scale: ${_scaleX.toStringAsFixed(1)}x',
                            style: const TextStyle(color: Colors.white60, fontSize: 10, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Pitch Slider
                      _buildCalibrationSlider(
                        label: 'PITCH (X-Axis)',
                        value: _pitch,
                        min: -180.0,
                        max: 180.0,
                        onChanged: (val) {
                          setState(() => _pitch = val);
                          _updateWebGLCalibration();
                        },
                      ),

                      // Yaw Slider
                      _buildCalibrationSlider(
                        label: 'YAW (Y-Axis)',
                        value: _yaw,
                        min: -180.0,
                        max: 180.0,
                        onChanged: (val) {
                          setState(() => _yaw = val);
                          _updateWebGLCalibration();
                        },
                      ),

                      // Roll Slider
                      _buildCalibrationSlider(
                        label: 'ROLL (Z-Axis)',
                        value: _roll,
                        min: -180.0,
                        max: 180.0,
                        onChanged: (val) {
                          setState(() => _roll = val);
                          _updateWebGLCalibration();
                        },
                      ),

                      // Scale Slider (Uniform scaling for all axes X, Y, Z)
                      _buildCalibrationSlider(
                        label: 'UNIFORM SCALE',
                        value: _scaleX,
                        min: 0.1,
                        max: 5.0,
                        activeColor: const Color(0xFF10B981),
                        onChanged: (val) {
                          setState(() {
                            _scaleX = val;
                            _scaleY = val;
                            _scaleZ = val;
                          });
                          _updateWebGLCalibration();
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalibrationSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    Color activeColor = const Color(0xFF6366F1),
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold),
            ),
            Text(
              value.toStringAsFixed(1),
              style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace'),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 1.5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
            activeTrackColor: activeColor,
            inactiveTrackColor: Colors.white10,
            thumbColor: activeColor,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
