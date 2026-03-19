class User {
  final String id;
  final String fullName;
  final String email;
  final bool membershipVerified;

  const User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.membershipVerified,
  });

  User copyWith({
    String? id,
    String? fullName,
    String? email,
    bool? membershipVerified,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      membershipVerified: membershipVerified ?? this.membershipVerified,
    );
  }
}
