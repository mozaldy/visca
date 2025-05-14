class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final bool isAdmin;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.isAdmin,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      uid: id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      isAdmin: data['isAdmin'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {'fullName': fullName, 'email': email, 'isAdmin': isAdmin};
  }
}
