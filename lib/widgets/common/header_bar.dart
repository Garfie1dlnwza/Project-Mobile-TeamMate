import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:teammate/widgets/common/profile.dart';
import 'package:teammate/screens/noti_page.dart';

import 'package:teammate/widgets/notification_badge.dart';

class Headbar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  const Headbar({super.key, required this.title});

  @override
  State<Headbar> createState() => _HeadbarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _HeadbarState extends State<Headbar> {
  final String? _userName = FirebaseAuth.instance.currentUser?.displayName;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    return hour < 12 ? 'Good Morning' : 'Good Afternoon';
  }

  // Method to navigate to notification page
  void _goToNotificationPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotiPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String>? temp = _userName?.split(' ');
    String username = temp != null && temp.isNotEmpty ? temp[0] : 'User';

    if (widget.title == 'HOME') {
      return AppBar(
        title: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Hello, $username',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              Text(
                _getGreeting(),
                style: TextStyle(fontWeight: FontWeight.w300, fontSize: 16),
              ),
            ],
          ),
        ),
        leading: Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 0, 0),
          child: ProfileAvatar(name: _userName ?? 'Unknown'),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.fromLTRB(0, 0, 20, 0),
            child: GestureDetector(
              onTap: _goToNotificationPage,
              child: NotificationBadge(
                right: -2,
                top: -2,
                child: Image.asset(
                  'assets/images/noti.png',
                  width: 30,
                  height: 30,
                ),
              ),
            ),
          ),
        ],
      );
    } else if (widget.title == 'MY WORK') {
      return AppBar(
        centerTitle: true,
        title: Text(
          widget.title,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 0, 0),
          child: ProfileAvatar(name: _userName ?? 'Unknown'),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/create_project');
            },
            child: Image.asset('assets/images/plus_icon.png'),
          ),
          const SizedBox(width: 16.0),
          Padding(
            padding: EdgeInsets.fromLTRB(0, 0, 20, 0),
            child: GestureDetector(
              onTap: _goToNotificationPage,
              child: NotificationBadge(
                right: -2,
                top: -2,
                child: Image.asset(
                  'assets/images/noti.png',
                  width: 30,
                  height: 30,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return AppBar(
        title: Center(
          child: Text(
            widget.title,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        leading: Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 0, 0),
          child: ProfileAvatar(name: _userName ?? 'Unknown'),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.fromLTRB(0, 0, 20, 0),
            child: GestureDetector(
              onTap: _goToNotificationPage,
              child: NotificationBadge(
                right: -2,
                top: -2,
                child: Image.asset(
                  'assets/images/noti.png',
                  width: 30,
                  height: 30,
                ),
              ),
            ),
          ),
        ],
      );
    }
  }
}
