import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/station_entity.dart';

class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.stationId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.photoUrls,
    required this.createdAt,
  });

  final String id;
  final String stationId;
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final List<String> photoUrls;
  final DateTime createdAt;

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      stationId: data['stationId'] as String,
      userId: data['userId'] as String,
      userName: data['userName'] as String? ?? '',
      rating: (data['rating'] as num).toDouble(),
      comment: data['comment'] as String? ?? '',
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory ReviewModel.fromEntity(StationReviewEntity entity) => ReviewModel(
        id: entity.id,
        stationId: entity.stationId,
        userId: entity.userId,
        userName: entity.userName,
        rating: entity.rating,
        comment: entity.comment,
        photoUrls: entity.photoUrls,
        createdAt: entity.createdAt,
      );

  Map<String, dynamic> toFirestore() => {
        'stationId': stationId,
        'userId': userId,
        'userName': userName,
        'rating': rating,
        'comment': comment,
        'photoUrls': photoUrls,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  StationReviewEntity toEntity() => StationReviewEntity(
        id: id,
        stationId: stationId,
        userId: userId,
        userName: userName,
        rating: rating,
        comment: comment,
        photoUrls: photoUrls,
        createdAt: createdAt,
      );
}
