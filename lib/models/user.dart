class User {
  final String id;
  final String name;
  final String studentId;
  final String email;
  final bool isAdmin;
  final bool isBlocked;
  final bool isFirstLogin;

  User({
    required this.id,
    required this.name,
    required this.studentId,
    required this.email,
    this.isAdmin = false,
    this.isBlocked = false,
    this.isFirstLogin = false,
  });

  factory User.fromFirestore(Map<String, dynamic> json, String id) {
    return User(
      id: id,
      name: json['name'] ?? '',
      studentId: json['studentId'] ?? '',
      email: json['email'] ?? '',
      isAdmin: json['isAdmin'] ?? false,
      isBlocked: json['isBlocked'] ?? false,
      isFirstLogin: json['isFirstLogin'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'studentId': studentId,
      'email': email,
      'isAdmin': isAdmin,
      'isBlocked': isBlocked,
      'isFirstLogin': isFirstLogin,
    };
  }
}
