import 'package:flutter/material.dart';
import 'package:teammate/services/firestore_noti_service.dart';

import 'package:teammate/theme/app_colors.dart';

class NotificationBadge extends StatelessWidget {
  final Widget child;
  final double right;
  final double top;

  const NotificationBadge({
    Key? key,
    required this.child,
    this.right = 0,
    this.top = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FirestoreNotificationService _notificationService =
        FirestoreNotificationService();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,

        // Badge showing unread count
        Positioned(
          right: right,
          top: top,
          child: StreamBuilder<int>(
            stream: _notificationService.getUnreadNotificationCountStream(),
            builder: (context, snapshot) {
              // If there are no unread notifications, don't show the badge
              if (!snapshot.hasData || snapshot.data == 0) {
                return const SizedBox.shrink();
              }

              // Show the badge with the unread count
              final int count = snapshot.data ?? 0;

              return Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
