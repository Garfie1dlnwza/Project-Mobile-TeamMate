import 'package:flutter/material.dart';
import 'package:teammate/models/user_model.dart';
import 'package:teammate/screens/home.dart';
import 'package:teammate/screens/work_page.dart';
import 'package:teammate/screens/calendar_page.dart';
import 'package:teammate/screens/settings_page.dart';

class Navbar extends StatefulWidget {
  final UserModel user;
  final VoidCallback? onThemeToggle;
  final VoidCallback? onLogout;

  const Navbar({
    Key? key,
    required this.user,
    this.onThemeToggle,
    this.onLogout,
  }) : super(key: key);

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  int currentIndex = 0;
  late List<Widget> pages;

  @override
  void initState() {
    super.initState();
    // Initialize pages with user data
    pages = [
      HomePage(user: widget.user),
      WorkPage(user: widget.user),
      CalendarPage(user: widget.user),
      SettingsPage(user: widget.user),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.black54
                  : Color(0xFF4A4A4A),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined),
              _buildNavItem(1, Icons.work_outline),
              _buildNavItem(2, Icons.calendar_today_outlined),
              _buildNavItem(3, Icons.tune),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final isSelected = currentIndex == index;

    return InkWell(
      onTap: () => setState(() => currentIndex = index),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.black : Colors.white,
          size: 35,
        ),
      ),
    );
  }
}
