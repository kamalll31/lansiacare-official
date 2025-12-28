class User {
  final int id;
  final String phone;
  final String? email;
  final String role;
  final bool isVerified;
  
  User({
    required this.id,
    required this.phone,
    this.email,
    required this.role,
    required this.isVerified,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      phone: json['phone'],
      email: json['email'],
      role: json['role'],
      isVerified: json['is_verified'],
    );
  }
}

class AuthResponse {
  final String accessToken;
  final User user;
  
  AuthResponse({
    required this.accessToken,
    required this.user,
  });
  
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'],
      user: User.fromJson(json['user']),
    );
  }
}

class RegisterResponse {
  final String message;
  final bool requiresOtp;
  final int userId;
  
  RegisterResponse({
    required this.message,
    required this.requiresOtp,
    required this.userId,
  });
  
  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      message: json['message'],
      requiresOtp: json['requires_otp'],
      userId: json['user_id'],
    );
  }
}