/// System health and model environment wire model matching DESIGN.md §12.

class SystemHealthModel {
  final String status;
  final String? version;
  final String? visionModel; // real | stub
  final bool isStub;

  const SystemHealthModel({
    required this.status,
    this.version,
    this.visionModel,
    this.isStub = false,
  });

  factory SystemHealthModel.fromJson(Map<String, dynamic> json) {
    return SystemHealthModel(
      status: json['status'] as String? ?? 'unknown',
      version: json['version'] as String?,
      visionModel: json['vision_model'] as String?,
      isStub: json['is_stub'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        if (version != null) 'version': version,
        if (visionModel != null) 'vision_model': visionModel,
        'is_stub': isStub,
      };
}
