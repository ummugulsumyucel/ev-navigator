import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/loading_widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/notification_entity.dart';
import '../providers/notification_providers.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('tr', timeago.TrMessages());
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(userNotificationsProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          TextButton(
            onPressed: user == null
                ? null
                : () => ref
                    .read(notificationRepositoryProvider)
                    .markAllAsRead(user.uid),
            child: const Text('Tümünü Okundu İşaretle'),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const AppLoadingIndicator(),
        error: (e, _) => AppErrorView(message: e.toString()),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Text('Henüz bildirim yok'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, i) {
              final n = notifications[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  onTap: () {
                    if (!n.read) {
                      ref
                          .read(notificationRepositoryProvider)
                          .markAsRead(n.id);
                    }
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _iconForType(n.type),
                        color: n.read ? AppColors.textMuted : AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.title,
                              style: TextStyle(
                                fontWeight: n.read
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              n.body,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeago.format(n.createdAt, locale: 'tr'),
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!n.read)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconForType(NotificationType type) => switch (type) {
        NotificationType.stationOutage => Icons.warning_amber,
        NotificationType.chargeComplete => Icons.ev_station,
        NotificationType.newComment => Icons.chat_bubble_outline,
        NotificationType.newFollower => Icons.person_add,
        NotificationType.news => Icons.newspaper,
        NotificationType.appointment => Icons.build,
        NotificationType.unknown => Icons.notifications,
      };
}
