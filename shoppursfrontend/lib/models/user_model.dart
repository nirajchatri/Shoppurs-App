class User {
  final int id;
  final String username;
  final String email;
  final int mobile;
  final String role;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.mobile,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      mobile: json['mobile'],
      role: json['role'] ?? 'customer', // Default to customer if role is not provided
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'mobile': mobile,
      'role': role,
    };
  }
} 