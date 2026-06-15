class CommunityPostEntity {
  const CommunityPostEntity({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhoto,
    required this.brand,
    required this.title,
    required this.content,
    required this.photoUrls,
    required this.likeCount,
    required this.commentCount,
    required this.likedBy,
    required this.createdAt,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhoto;
  final String brand;
  final String title;
  final String content;
  final List<String> photoUrls;
  final int likeCount;
  final int commentCount;
  final List<String> likedBy;
  final DateTime createdAt;

  bool isLikedBy(String uid) => likedBy.contains(uid);
}

class CommentEntity {
  const CommentEntity({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;
}
