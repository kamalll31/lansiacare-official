class User {
  final int id;
  final String phone;
  final String? email;
  final String role;
  final String? fullName; // Tambahan: biar nama profil muncul
  final bool isVerified;

  User({
    required this.id,
    required this.phone,
    this.email,
    required this.role,
    this.fullName,
    required this.isVerified,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      // ID: Kalau null, ganti jadi 0
      id: json['id'] is int ? json['id'] : 0, 
      
      // Phone: Pastikan jadi String, kalau null jadi ""
      phone: json['phone']?.toString() ?? "", 
      
      // Email: Boleh null
      email: json['email']?.toString(),
      
      // Role: Default ke 'keluarga' jika kosong
      role: json['role']?.toString() ?? "keluarga",
      
      // FullName: Ambil dari full_name
      fullName: json['full_name']?.toString(),

      // isVerified: Handle null agar jadi false
      isVerified: json['is_verified'] == true, 
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
      // Token: Cek 'access_token', kalau gak ada cek 'token', kalau gak ada string kosong
      accessToken: json['access_token']?.toString() ?? json['token']?.toString() ?? "",
      
      // User: Pastikan ada data user-nya
      user: json['user'] != null 
          ? User.fromJson(json['user']) 
          : User(id: 0, phone: "", role: "guest", isVerified: false),
    );
  }
}

class RegisterResponse {
  final String message;
  final bool requiresOtp;
  final int userId; // Ubah jadi nullable jika perlu, tapi int aman untuk sekarang

  RegisterResponse({
    required this.message,
    required this.requiresOtp,
    required this.userId,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    // Kadang data ada di dalam object 'data', kadang di luar. Kita handle keduanya.
    final data = json['data'] is Map<String, dynamic> ? json['data'] : json;

    return RegisterResponse(
      message: json['message']?.toString() ?? "Success",
      requiresOtp: data['requires_otp'] == true,
      userId: int.tryParse(data['user_id'].toString()) ?? 0,
    );
  }
}