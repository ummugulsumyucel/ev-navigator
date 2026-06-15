import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user_entity.dart';

class UserModel {
  const UserModel({
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

  factory UserModel.fromFirebaseUser(
    User user, {
    String? displayName,
    bool? profileCompleted,
  }) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: displayName ?? user.displayName ?? 'Kullanıcı',
      photoUrl: user.photoURL,
      emailVerified: user.emailVerified,
      profileCompleted: profileCompleted ?? (user.displayName?.isNotEmpty ?? false),
      createdAt: DateTime.now(),
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    final statsData = data['stats'] as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      phone: data['phone'] as String?,
      role: data['role'] as String? ?? 'user',
      emailVerified: data['emailVerified'] as bool? ?? false,
      profileCompleted: data['profileCompleted'] as bool? ?? false,
      vehicleIds: List<String>.from(data['vehicleIds'] ?? []),
      stats: UserStats(
        totalCharges: statsData['totalCharges'] as int? ?? 0,
        totalKm: (statsData['totalKm'] as num?)?.toDouble() ?? 0,
        totalSavingsTl: (statsData['totalSavingsTl'] as num?)?.toDouble() ?? 0,
      ),
      fcmToken: data['fcmToken'] as String?,
      following: List<String>.from(data['following'] ?? []),
      followers: List<String>.from(data['followers'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (phone != null) 'phone': phone,
        'role': role,
        'emailVerified': emailVerified,
        'profileCompleted': profileCompleted,
        'vehicleIds': vehicleIds,
        'stats': {
          'totalCharges': stats.totalCharges,
          'totalKm': stats.totalKm,
          'totalSavingsTl': stats.totalSavingsTl,
        },
        if (fcmToken != null) 'fcmToken': fcmToken,
        'following': following,
        'followers': followers,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  UserEntity toEntity() => UserEntity(
        uid: uid,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        phone: phone,
        role: role,
        emailVerified: emailVerified,
        profileCompleted: profileCompleted,
        vehicleIds: vehicleIds,
        stats: stats,
        fcmToken: fcmToken,
        following: following,
        followers: followers,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
