class SplatCapture {
  final String id;
  final String title;
  final String? description;
  final String disasterType;
  final String severity;
  final String status;
  final String? fileUrl;
  final String? thumbnailUrl;
  final double latitude;
  final double longitude;
  final double altitude;
  final double roll;
  final double pitch;
  final double yaw;
  final double scaleX;
  final double scaleY;
  final double scaleZ;
  final DateTime createdAt;
  final DateTime updatedAt;

  SplatCapture({
    required this.id,
    required this.title,
    this.description,
    required this.disasterType,
    required this.severity,
    required this.status,
    this.fileUrl,
    this.thumbnailUrl,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.roll,
    required this.pitch,
    required this.yaw,
    required this.scaleX,
    required this.scaleY,
    required this.scaleZ,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SplatCapture.fromJson(Map<String, dynamic> json) {
    return SplatCapture(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      disasterType: json['disaster_type'] as String,
      severity: json['severity'] as String,
      status: json['status'] as String,
      fileUrl: json['file_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      altitude: (json['altitude'] as num).toDouble(),
      roll: (json['roll'] as num).toDouble(),
      pitch: (json['pitch'] as num).toDouble(),
      yaw: (json['yaw'] as num).toDouble(),
      scaleX: (json['scale_x'] as num).toDouble(),
      scaleY: (json['scale_y'] as num).toDouble(),
      scaleZ: (json['scale_z'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'disaster_type': disasterType,
      'severity': severity,
      'status': status,
      'file_url': fileUrl,
      'thumbnail_url': thumbnailUrl,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'roll': roll,
      'pitch': pitch,
      'yaw': yaw,
      'scale_x': scaleX,
      'scale_y': scaleY,
      'scale_z': scaleZ,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
