/// Presigned upload wire models matching API_CONTRACT §3.

class PresignRequest {
  final String kind; // image | audio
  final String contentType; // e.g. image/jpeg | audio/wav
  final String? farmId;

  const PresignRequest({
    required this.kind,
    required this.contentType,
    this.farmId,
  });

  Map<String, dynamic> toJson() => {
        'kind': kind,
        'content_type': contentType,
        if (farmId != null) 'farm_id': farmId,
      };
}

class PresignedAssetModel {
  final String assetId;
  final String uploadUrl;
  final String method; // PUT
  final int expiresIn;

  const PresignedAssetModel({
    required this.assetId,
    required this.uploadUrl,
    this.method = 'PUT',
    this.expiresIn = 600,
  });

  factory PresignedAssetModel.fromJson(Map<String, dynamic> json) {
    return PresignedAssetModel(
      assetId: json['asset_id'] as String,
      uploadUrl: json['upload_url'] as String,
      method: json['method'] as String? ?? 'PUT',
      expiresIn: json['expires_in'] as int? ?? 600,
    );
  }

  Map<String, dynamic> toJson() => {
        'asset_id': assetId,
        'upload_url': uploadUrl,
        'method': method,
        'expires_in': expiresIn,
      };
}
