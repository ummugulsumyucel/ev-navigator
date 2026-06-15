import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/community_entity.dart';

class PostModel {
  const PostModel({
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

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      authorId: data['authorId'] as String,
      authorName: data['authorName'] as String? ?? '',
      authorPhoto: data['authorPhoto'] as String?,
      brand: data['brand'] as String? ?? 'Genel',
      title: data['title'] as String? ?? '',
      content: data['content'] as String? ?? '',
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      likeCount: data['likeCount'] as int? ?? 0,
      commentCount: data['commentCount'] as int? ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'authorId': authorId,
        'authorName': authorName,
        if (authorPhoto != null) 'authorPhoto': authorPhoto,
        'brand': brand,
        'title': title,
        'content': content,
        'photoUrls': photoUrls,
        'likeCount': likeCount,
        'commentCount': commentCount,
        'likedBy': likedBy,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  CommunityPostEntity toEntity() => CommunityPostEntity(
        id: id,
        authorId: authorId,
        authorName: authorName,
        authorPhoto: authorPhoto,
        brand: brand,
        title: title,
        content: content,
        photoUrls: photoUrls,
        likeCount: likeCount,
        commentCount: commentCount,
        likedBy: likedBy,
        createdAt: createdAt,
      );
}

class CommentModel {
  const CommentModel({
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

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      postId: data['postId'] as String,
      authorId: data['authorId'] as String,
      authorName: data['authorName'] as String? ?? '',
      content: data['content'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'postId': postId,
        'authorId': authorId,
        'authorName': authorName,
        'content': content,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  CommentEntity toEntity() => CommentEntity(
        id: id,
        postId: postId,
        authorId: authorId,
        authorName: authorName,
        content: content,
        createdAt: createdAt,
      );
}
