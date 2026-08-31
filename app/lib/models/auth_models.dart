/// Authentication wire models matching API_CONTRACT §2.

class UserModel {
  final String id;
  final String? phone;
  final String? email;
  final String role; // farmer | agronomist | official

  const UserModel({
    required this.id,
    this.phone,
    this.email,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String? ?? 'farmer',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        'role': role,
      };
}

class TokenPair {
  final String accessToken;
  final String refreshToken;
  final int? expiresIn;

  const TokenPair({
    required this.accessToken,
    required this.refreshToken,
    this.expiresIn,
  });

  factory TokenPair.fromJson(Map<String, dynamic> json) {
    return TokenPair(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresIn: json['expires_in'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        if (expiresIn != null) 'expires_in': expiresIn,
      };
}

class OtpRequestResponse {
  final String requestId;
  final int expiresIn;

  const OtpRequestResponse({
    required this.requestId,
    required this.expiresIn,
  });

  factory OtpRequestResponse.fromJson(Map<String, dynamic> json) {
    return OtpRequestResponse(
      requestId: json['request_id'] as String,
      expiresIn: json['expires_in'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'request_id': requestId,
        'expires_in': expiresIn,
      };
}

class OtpVerifyResponse {
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  const OtpVerifyResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory OtpVerifyResponse.fromJson(Map<String, dynamic> json) {
    return OtpVerifyResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'user': user.toJson(),
      };
}
