import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../../core/utils/auth_error_formatter.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = firebaseAuth,
        _firestore = firestore,
        _googleSignIn = googleSignIn;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn? _googleSignIn;

  GoogleSignIn get _googleSignInInstance =>
      _googleSignIn ?? GoogleSignIn();

  static const _usersCollection = 'users';

  @override
  Stream<UserEntity?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      try {
        final profile = await getUserProfile(user.uid);
        if (user.emailVerified && !profile.emailVerified) {
          await _firestore.collection(_usersCollection).doc(user.uid).update({
            'emailVerified': true,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          return profile.copyWith(emailVerified: true);
        }
        return profile.copyWith(emailVerified: user.emailVerified);
      } catch (_) {
        return _mapFirebaseUser(user);
      }
    });
  }

  @override
  UserEntity? get currentUser {
    final user = _auth.currentUser;
    return user != null ? _mapFirebaseUser(user) : null;
  }

  @override
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return await _ensureUserDocument(credential.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapAuthError(e));
    }
  }

  @override
  Future<UserEntity> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user!.updateDisplayName(displayName.trim());
      final entity = UserModel.fromFirebaseUser(
        credential.user!,
        displayName: displayName.trim(),
        profileCompleted: false,
      );
      await _firestore
          .collection(_usersCollection)
          .doc(credential.user!.uid)
          .set(entity.toFirestore());
      await sendEmailVerification();
      // Kayıt sonrası otomatik giriş yapma — kullanıcı önce e-postasını doğrulasın
      await _auth.signOut();
      return entity.toEntity();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapAuthError(e));
    } on FirebaseException catch (e) {
      throw AuthFailure(
        e.message ?? 'Veritabanı hatası. Firestore kurallarını kontrol edin.',
      );
    } catch (e) {
      throw AuthFailure('Kayıt başarısız: $e');
    }
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignInInstance.signIn();
      if (googleUser == null) throw const AuthFailure('Giriş iptal edildi');

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result = await _auth.signInWithCredential(credential);
      return await _ensureUserDocument(result.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapAuthError(e));
    }
  }

  @override
  Future<UserEntity> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      final result = await _auth.signInWithCredential(oauthCredential);
      final name = [
        appleCredential.givenName,
        appleCredential.familyName,
      ].where((n) => n != null).join(' ');
      return await _ensureUserDocument(
        result.user!,
        displayName: name.isNotEmpty ? name : null,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapAuthError(e));
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapAuthError(e));
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    if (_googleSignIn != null) {
      await _googleSignIn.signOut();
    }
  }

  @override
  Future<UserEntity> completeProfile({
    required String displayName,
    String? phone,
    String? photoUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure('Oturum bulunamadı');

    await user.updateDisplayName(displayName);
    await _firestore.collection(_usersCollection).doc(user.uid).update({
      'displayName': displayName,
      if (phone != null) 'phone': phone,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'profileCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return getUserProfile(user.uid);
  }

  @override
  Future<UserEntity> updateProfile({
    required String displayName,
    String? phone,
    String? photoUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure('Oturum bulunamadı');

    await user.updateDisplayName(displayName);
    await _firestore.collection(_usersCollection).doc(user.uid).update({
      'displayName': displayName,
      'phone': phone,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return getUserProfile(user.uid);
  }

  @override
  Future<UserEntity> syncEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure('Oturum bulunamadı');

    await user.reload();
    final refreshed = _auth.currentUser!;
    if (refreshed.emailVerified) {
      await _firestore.collection(_usersCollection).doc(refreshed.uid).update({
        'emailVerified': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    return getUserProfile(refreshed.uid);
  }

  @override
  Future<UserEntity> getUserProfile(String uid) async {
    final doc = await _firestore.collection(_usersCollection).doc(uid).get();
    if (!doc.exists) {
      final user = _auth.currentUser;
      if (user != null && user.uid == uid) {
        return _mapFirebaseUser(user);
      }
      throw const AuthFailure('Kullanıcı profili bulunamadı');
    }
    final entity = UserModel.fromFirestore(doc).toEntity();
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null && firebaseUser.uid == uid) {
      return entity.copyWith(emailVerified: firebaseUser.emailVerified);
    }
    return entity;
  }

  @override
  Future<void> updateFcmToken(String token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection(_usersCollection).doc(uid).update({
      'fcmToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<UserEntity> _ensureUserDocument(
    User user, {
    String? displayName,
  }) async {
    final doc = await _firestore.collection(_usersCollection).doc(user.uid).get();
    if (!doc.exists) {
      final model = UserModel.fromFirebaseUser(
        user,
        displayName: displayName ?? user.displayName ?? 'Kullanıcı',
        profileCompleted: user.displayName != null && user.displayName!.isNotEmpty,
      );
      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .set(model.toFirestore());
      return model.toEntity();
    }
    return UserModel.fromFirestore(doc).toEntity().copyWith(
          emailVerified: user.emailVerified,
        );
  }

  UserEntity _mapFirebaseUser(User user) {
    return UserModel.fromFirebaseUser(user).toEntity();
  }

  String _mapAuthError(FirebaseAuthException e) =>
      formatAuthError(e);
}
