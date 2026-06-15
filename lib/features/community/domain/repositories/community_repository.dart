import '../entities/community_entity.dart';

abstract class CommunityRepository {
  Stream<List<CommunityPostEntity>> watchPosts({int limit = 20});

  Future<List<CommunityPostEntity>> fetchMorePosts({
    required DateTime startAfter,
    int limit = 20,
  });

  Future<void> createPost({
    required String authorId,
    required String authorName,
    String? authorPhoto,
    required String brand,
    required String title,
    required String content,
    List<String> photoUrls,
  });

  Future<void> toggleLike(String postId, String userId, List<String> likedBy);

  Future<void> addComment({
    required String postId,
    required String authorId,
    required String authorName,
    required String content,
  });

  Stream<List<CommentEntity>> watchComments(String postId);
}
