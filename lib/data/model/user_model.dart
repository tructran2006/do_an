class UserModel {
  int? id;
  String username;
  String password;
  String fullName;
  String phone;
  String role; // "USER" hoặc "ADMIN"
  String email;   // THÊM MỚI
  String avatar;
  String address;

  UserModel({
    this.id,
    required this.username,
    required this.password,
    required this.fullName,
    required this.phone,
    required this.role,
    this.email = '',    // Mặc định trống
    this.avatar = '',
    this.address = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'fullname': fullName,
      'phone': phone,
      'role': role,
      'email': email,
      'avatar': avatar,
      'address': address,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      fullName: map['fullname'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'USER',
      email: map['email'] ?? '',
      avatar: map['avatar'] ?? '',
      address: map['address'] ?? '',
    );
  }
}