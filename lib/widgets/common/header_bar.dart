import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:teammate/services/user_service.dart';

class Headbar extends StatefulWidget implements PreferredSizeWidget {
  final String title;

  const Headbar({super.key, required this.title});

  @override
  State<Headbar> createState() => _HeadbarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _HeadbarState extends State<Headbar> {
  final UserService _userService = UserService();
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    await _userService.fetchUserName();
    setState(() {
      String name = _userService.getUserName;
      List<String> word = name.split(" ");
      _userName = word[0];
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    return hour < 12 ? 'Good Morning' : 'Good Afternoon';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.title == 'HOME') {
      return AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Hello, ${_userName}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              _getGreeting(),
              style: TextStyle(fontWeight: FontWeight.w300, fontSize: 16),
            ),
          ],
        ),
        leading: Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 0, 0),
          child: Image.asset('assets/images/default.png'),
        ),
        actions: [Image.asset('assets/images/noti.png')],
        actionsPadding: EdgeInsets.fromLTRB(0, 0, 20, 0),
      );
    } else {
      return AppBar(
        title: Text(
          widget.title,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 0, 0),
          child: Image.asset('assets/images/default.png'),
        ),
        actions: [Image.asset('assets/images/noti.png')],
        actionsPadding: EdgeInsets.fromLTRB(0, 0, 20, 0),
      );
    }
  }
}
