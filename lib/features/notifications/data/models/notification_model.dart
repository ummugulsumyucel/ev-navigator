import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
    this.data = const {},
  });

  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;
  final Map<String, dynamic> data;

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: d['userId'] as String,
      type: d['type'] as String? ?? 'unknown',
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      read: d['read'] as bool? ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      data: Map<String, dynamic>.from(d['data'] as Map? ?? {}),
    );
  }

  NotificationType _parseType(String t) => switch (t) {
        'station_outage' => NotificationType.stationOutage,
        'charge_complete' => NotificationType.chargeComplete,
        'new_comment' => NotificationType.newComment,
        'new_follower' => NotificationType.newFollower,
        'news' => NotificationType.news,
        'appointment' => NotificationType.appointment,
        _ => NotificationType.unknown,
      };

  AppNotificationEntity toEntity() => AppNotificationEntity(
        id: id,
        userId: userId,
        type: _parseType(type),
        title: title,
        body: body,
        read: read,
        createdAt: createdAt,
        data: data,
      );
}
