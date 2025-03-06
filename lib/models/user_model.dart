class UserModel {
  final String id;
  final String name;
  final String password; // Changed to String
  final String email;
  final String? profileImage;
  final String? phoneNumber;
  final List<String>? projects;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    this.profileImage,
    this.phoneNumber,
    this.projects,
  });

  // Method to convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImage': profileImage ?? '',
      'phoneNumber': phoneNumber ?? '',
      'projects': projects ?? [],
      // Note: We don't store the password in Firestore for security reasons
    };
  }

  // Factory method to create UserModel from Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      password: '', // Password is not stored in Firestore
      profileImage: map['profileImage'],
      phoneNumber: map['phoneNumber'],
      projects: List<String>.from(map['projects'] ?? []),
    );
  }

  // Method to create a copy of UserModel with updated fields
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    String? profileImage,
    String? phoneNumber,
    List<String>? projects,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      profileImage: profileImage ?? this.profileImage,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      projects: projects ?? this.projects,
    );
  }
}
