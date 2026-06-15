import '../entities/user_entity.dart';

abstract class AuthRepository {
  Stream<UserEntity?> get authStateChanges;
  UserEntity? get currentUser;

  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  });

  Future<UserEntity> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  Future<UserEntity> signInWithGoogle();
  Future<UserEntity> signInWithApple();

  Future<void> sendPasswordResetEmail(String email);
  Future<void> sendEmailVerification();
  Future<void> signOut();

  Future<UserEntity> completeProfile({
    required String displayName,
    String? phone,
    String? photoUrl,
  });

  Future<UserEntity> updateProfile({
    required String displayName,
    String? phone,
    String? photoUrl,
  });

  Future<UserEntity> syncEmailVerification();

  Future<UserEntity> getUserProfile(String uid);
  Future<void> updateFcmToken(String token);
}
