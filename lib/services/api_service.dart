import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import '../models/splat_capture.dart';
import '../models/processing_job.dart';

class ApiService {
  // Singleton Pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Dynamic Base URL Configuration
  String _baseUrl = 'http://127.0.0.1:8000';

  String get baseUrl => _baseUrl;
  set baseUrl(String url) {
    // Remove trailing slash if present
    if (url.endsWith('/')) {
      _baseUrl = url.substring(0, url.length - 1);
    } else {
      _baseUrl = url;
    }
  }

  // --- STAGE 1: Direct Splat Ingestion ---

  /// Registers a georeferenced Splat Capture shell.
  Future<SplatCapture> createSplatMetadata({
    required String title,
    String? description,
    required String disasterType,
    required String severity,
    required double latitude,
    required double longitude,
    double altitude = 0.0,
    double roll = 0.0,
    double pitch = 0.0,
    double yaw = 0.0,
    double scaleX = 1.0,
    double scaleY = 1.0,
    double scaleZ = 1.0,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/splats/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'description': description,
        'disaster_type': disasterType,
        'severity': severity,
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'roll': roll,
        'pitch': pitch,
        'yaw': yaw,
        'scale_x': scaleX,
        'scale_y': scaleY,
        'scale_z': scaleZ,
      }),
    );

    if (response.statusCode == 201) {
      return SplatCapture.fromJson(jsonDecode(response.body));
    } else {
      throw HttpException(
        'Failed to register splat metadata: ${response.statusCode}\n${response.body}',
      );
    }
  }

  /// Uploads a pre-processed 3D Gaussian Splat (.splat / .ply) directly to a registered capture shell.
  Future<SplatCapture> uploadDirectSplatFile(String splatId, File file) async {
    final uri = Uri.parse('$baseUrl/api/v1/splats/$splatId/upload-asset');
    final request = http.MultipartRequest('POST', uri);

    // Determine extension
    final ext = p.extension(file.path).toLowerCase();
    if (ext != '.ply' && ext != '.splat') {
      throw ArgumentError('Invalid file format. Only .ply and .splat files are allowed');
    }

    final mimeType = ext == '.ply' ? 'application/octet-stream' : 'application/octet-stream';

    // Add multipart file
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType.parse(mimeType),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return SplatCapture.fromJson(jsonDecode(response.body));
    } else {
      throw HttpException(
        'Failed to upload 3D asset file: ${response.statusCode}\n${response.body}',
      );
    }
  }

  // --- STAGE 2: Video Ingestion & Reconstruction Pipeline ---

  /// Uploads a drone/smartphone disaster video and triggers the async Celery pre-processing pipeline.
  Future<ProcessingJob> uploadDisasterVideo({
    required String title,
    String? description,
    required String disasterType,
    required String severity,
    required double latitude,
    required double longitude,
    double altitude = 0.0,
    required File videoFile,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/jobs/upload-video');
    final request = http.MultipartRequest('POST', uri);

    // Add form data fields
    request.fields['title'] = title;
    if (description != null) request.fields['description'] = description;
    request.fields['disaster_type'] = disasterType;
    request.fields['severity'] = severity;
    request.fields['latitude'] = latitude.toString();
    request.fields['longitude'] = longitude.toString();
    request.fields['altitude'] = altitude.toString();

    // Determine video format
    final ext = p.extension(videoFile.path).toLowerCase();
    if (ext != '.mp4' && ext != '.mov' && ext != '.avi') {
      throw ArgumentError('Invalid video format. Supported formats: .mp4, .mov, .avi');
    }

    final mediaType = ext == '.mp4' ? 'video/mp4' : (ext == '.mov' ? 'video/quicktime' : 'video/x-msvideo');

    // Add multipart file
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        videoFile.path,
        contentType: MediaType.parse(mediaType),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 202) {
      return ProcessingJob.fromJson(jsonDecode(response.body));
    } else {
      throw HttpException(
        'Failed to upload disaster video: ${response.statusCode}\n${response.body}',
      );
    }
  }

  /// Retrieves the active state and training progression of a reconstruction job (polls 0 - 100%).
  Future<ProcessingJob> getJobStatus(String jobId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/v1/jobs/$jobId'));

    if (response.statusCode == 200) {
      return ProcessingJob.fromJson(jsonDecode(response.body));
    } else {
      throw HttpException(
        'Failed to query reconstruction job progress: ${response.statusCode}\n${response.body}',
      );
    }
  }

  /// Retrieves the reconstruction job associated with a specific Splat Capture.
  Future<ProcessingJob> getJobByCapture(String captureId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/v1/jobs/capture/$captureId'));

    if (response.statusCode == 200) {
      return ProcessingJob.fromJson(jsonDecode(response.body));
    } else {
      throw HttpException(
        'Failed to query job by capture ID: ${response.statusCode}\n${response.body}',
      );
    }
  }

  // --- STAGE 3: Client Spatial Integration & Searching ---

  /// Performs spatial radius search (in km) to query completed Splat captures.
  Future<List<SplatCapture>> searchSplatsByRadius({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/splats/search?lat=$latitude&lon=$longitude&radius_km=$radiusKm'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => SplatCapture.fromJson(json)).toList();
    } else {
      throw HttpException(
        'Failed to perform spatial splat query: ${response.statusCode}\n${response.body}',
      );
    }
  }

  /// Serves geospatial radius search matching GeoJSON FeatureCollection structures (ideal for Flutter Maps).
  Future<Map<String, dynamic>> searchSplatsGeoJSON({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/splats/search/geojson?lat=$latitude&lon=$longitude&radius_km=$radiusKm'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw HttpException(
        'Failed to fetch GeoJSON FeatureCollection: ${response.statusCode}\n${response.body}',
      );
    }
  }

  /// Retrieves full details of a specific Splat Capture.
  Future<SplatCapture> getSplatDetails(String splatId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/v1/splats/$splatId'));

    if (response.statusCode == 200) {
      return SplatCapture.fromJson(jsonDecode(response.body));
    } else {
      throw HttpException(
        'Failed to query splat capture details: ${response.statusCode}\n${response.body}',
      );
    }
  }

  /// Calibrates active alignment orientation variables or scaling factors for a splat capture.
  Future<SplatCapture> updateSplatCalibration(
    String splatId, {
    String? title,
    String? description,
    double? roll,
    double? pitch,
    double? yaw,
    double? scaleX,
    double? scaleY,
    double? scaleZ,
  }) async {
    final Map<String, dynamic> body = {};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (roll != null) body['roll'] = roll;
    if (pitch != null) body['pitch'] = pitch;
    if (yaw != null) body['yaw'] = yaw;
    if (scaleX != null) body['scale_x'] = scaleX;
    if (scaleY != null) body['scale_y'] = scaleY;
    if (scaleZ != null) body['scale_z'] = scaleZ;

    final response = await http.patch(
      Uri.parse('$baseUrl/api/v1/splats/$splatId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return SplatCapture.fromJson(jsonDecode(response.body));
    } else {
      throw HttpException(
        'Failed to update splat metadata/calibration: ${response.statusCode}\n${response.body}',
      );
    }
  }

  /// Deletes a georeferenced splat capture from database and disk.
  Future<void> deleteSplatCapture(String splatId) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/v1/splats/$splatId'));

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw HttpException(
        'Failed to delete splat capture: ${response.statusCode}\n${response.body}',
      );
    }
  }
}
