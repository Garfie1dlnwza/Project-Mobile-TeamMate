import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:teammate/services/firestore_user_service.dart';

class NotificationBadge extends StatefulWidget {
  final Widget child;
  final double? right;
  final double? top;
  final double badgeSize;
  final Color badgeColor;

  const NotificationBadge({
    super.key,
    required this.child,
    this.right = 0,
    this.top = 0,
    this.badgeSize = 8.0,
    this.badgeColor = Colors.red,
  });

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  final FirestoreUserService _userService = FirestoreUserService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return widget.child;
    }

    return StreamBuilder<bool>(
      stream: _userService.getUserUnreadNotificationStatus(user.uid),
      builder: (context, snapshot) {
        final bool hasUnread = snapshot.data ?? false;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            widget.child,
            if (hasUnread)
              Positioned(
                right: widget.right,
                top: widget.top,
                child: Container(
                  width: widget.badgeSize,
                  height: widget.badgeSize,
                  decoration: BoxDecoration(
                    color: widget.badgeColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// สำหรับใช้งานกับ BottomNavigationBar
class NotificationTabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;

  const NotificationTabItem({
    super.key,
    required this.icon,
    required this.label,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final FirestoreUserService userService = FirestoreUserService();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );
    }

    return StreamBuilder<bool>(
      stream: userService.getUserUnreadNotificationStatus(user.uid),
      builder: (context, snapshot) {
        final bool hasUnread = snapshot.data ?? false;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon),
                const SizedBox(height: 4),
                Text(label, style: const TextStyle(fontSize: 12)),
              ],
            ),
            if (hasUnread)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 10,
                    minHeight: 10,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
