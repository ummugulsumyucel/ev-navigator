class UserEntity {
  const UserEntity({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.phone,
    this.role = 'user',
    this.emailVerified = false,
    this.profileCompleted = false,
    this.vehicleIds = const [],
    this.stats = const UserStats(),
    this.fcmToken,
    this.following = const [],
    this.followers = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? phone;
  final String role;
  final bool emailVerified;
  final bool profileCompleted;
  final List<String> vehicleIds;
  final UserStats stats;
  final String? fcmToken;
  final List<String> following;
  final List<String> followers;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isAdmin => role == 'admin';
  bool get needsProfileCompletion => !profileCompleted;
  bool get needsEmailVerification => !emailVerified;

  UserEntity copyWith({
    String? displayName,
    String? photoUrl,
    String? phone,
    bool? profileCompleted,
    bool? emailVerified,
    UserStats? stats,
  }) {
    return UserEntity(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      role: role,
      emailVerified: emailVerified ?? this.emailVerified,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      vehicleIds: vehicleIds,
      stats: stats ?? this.stats,
      fcmToken: fcmToken,
      following: following,
      followers: followers,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class UserStats {
  const UserStats({
    this.totalCharges = 0,
    this.totalKm = 0,
    this.totalSavingsTl = 0,
  });

  final int totalCharges;
  final double totalKm;
  final double totalSavingsTl;
}
