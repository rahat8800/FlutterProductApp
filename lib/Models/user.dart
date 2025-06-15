class User {
  final String id;
  final String email;
  final String name;
  final String? profilePicture;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.profilePicture,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      profilePicture: json['profilePicture'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'profilePicture': profilePicture,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? profilePicture,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      profilePicture: profilePicture ?? this.profilePicture,
    );
  }
} 