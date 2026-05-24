class ProcessingJob {
  final String id;
  final String captureId;
  final String? videoUrl;
  final String? taskId;
  final int progress;
  final String statusMessage;
  final String? errorLog;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProcessingJob({
    required this.id,
    required this.captureId,
    this.videoUrl,
    this.taskId,
    required this.progress,
    required this.statusMessage,
    this.errorLog,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProcessingJob.fromJson(Map<String, dynamic> json) {
    return ProcessingJob(
      id: json['id'] as String,
      captureId: json['capture_id'] as String,
      videoUrl: json['video_url'] as String?,
      taskId: json['task_id'] as String?,
      progress: json['progress'] as int,
      statusMessage: json['status_message'] as String,
      errorLog: json['error_log'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'capture_id': captureId,
      'video_url': videoUrl,
      'task_id': taskId,
      'progress': progress,
      'status_message': statusMessage,
      'error_log': errorLog,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
