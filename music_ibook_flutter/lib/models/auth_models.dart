class AuthResponse {
  final String accessToken;
  final String role;
  final String fullName;

  AuthResponse({
    required this.accessToken,
    required this.role,
    required this.fullName,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] ?? '',
      role: json['role'] ?? '',
      fullName: json['fullName'] ?? '',
    );
  }
}
