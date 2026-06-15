import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/community_entity.dart';
import '../../domain/repositories/community_repository.dart';
import '../models/community_models.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  CommunityRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;
  static const _posts = 'community_posts';
  static const _comments = 'comments';

  @override
  Stream<List<CommunityPostEntity>> watchPosts({int limit = 20}) {
    return _firestore.collection(_posts).limit(limit).snapshots().map((s) {
      final list =
          s.docs.map(PostModel.fromFirestore).map((m) => m.toEntity()).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Future<List<CommunityPostEntity>> fetchMorePosts({
    required DateTime startAfter,
    int limit = 20,
  }) async {
    final snap = await _firestore
        .collection(_posts)
        .limit(limit * 3) // fazla çekip Dart tarafında filtrele
        .get();
    final all = snap.docs
        .map(PostModel.fromFirestore)
        .map((m) => m.toEntity())
        .toList();
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all
        .where((p) => p.createdAt.isBefore(startAfter))
        .take(limit)
        .toList();
  }

  @override
  Future<void> createPost({
    required String authorId,
    required String authorName,
    String? authorPhoto,
    required String brand,
    required String title,
    required String content,
    List<String> photoUrls = const [],
  }) async {
    final model = PostModel(
      id: const Uuid().v4(),
      authorId: authorId,
      authorName: authorName,
      authorPhoto: authorPhoto,
      brand: brand,
      title: title,
      content: content,
      photoUrls: photoUrls,
      likeCount: 0,
      commentCount: 0,
      likedBy: const [],
      createdAt: DateTime.now(),
    );
    await _firestore.collection(_posts).doc(model.id).set(model.toFirestore());
  }

  @override
  Future<void> toggleLike(
    String postId,
    String userId,
    List<String> likedBy,
  ) async {
    final ref = _firestore.collection(_posts).doc(postId);
    final liked = likedBy.contains(userId);
    if (liked) {
      await ref.update({
        'likedBy': FieldValue.arrayRemove([userId]),
        'likeCount': FieldValue.increment(-1),
      });
    } else {
      await ref.update({
        'likedBy': FieldValue.arrayUnion([userId]),
        'likeCount': FieldValue.increment(1),
      });
    }
  }

  @override
  Future<void> addComment({
    required String postId,
    required String authorId,
    required String authorName,
    required String content,
  }) async {
    final comment = CommentModel(
      id: const Uuid().v4(),
      postId: postId,
      authorId: authorId,
      authorName: authorName,
      content: content,
      createdAt: DateTime.now(),
    );
    await _firestore
        .collection(_comments)
        .doc(comment.id)
        .set(comment.toFirestore());
    await _firestore.collection(_posts).doc(postId).update({
      'commentCount': FieldValue.increment(1),
    });
  }

  @override
  Stream<List<CommentEntity>> watchComments(String postId) {
    return _firestore
        .collection(_comments)
        .where('postId', isEqualTo: postId)
        .snapshots()
        .map((s) {
      final list = s.docs
          .map(CommentModel.fromFirestore)
          .map((m) => m.toEntity())
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }
}
