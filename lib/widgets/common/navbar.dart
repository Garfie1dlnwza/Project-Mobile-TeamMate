import 'package:flutter/material.dart';
import 'package:teammate/screens/home.dart';
import 'package:teammate/screens/work_page.dart';
import 'package:teammate/screens/calendar_page.dart';
import 'package:teammate/screens/settings_page.dart';

class Navbar extends StatefulWidget {
  const Navbar({Key? key}) : super(key: key);

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
      HomePage(title: 'HOME'),
      WorkPage(title: 'WORKPAGE'),
      CalendarPage(title: 'CALENDAR'),
      SettingsPage(title: 'SETTING'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
        child: Container(
          decoration: BoxDecoration(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.black54
                    : const Color(0xFF4A4A4A),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, 'assets/images/icon_home_.png'),
                _buildNavItem(1, 'assets/images/Business.png'),
                _buildNavItem(2, 'assets/images/Calendar.png'),
                _buildNavItem(3, 'assets/images/Setting.png'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String imagePath) {
    final isSelected = currentIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          currentIndex = index;
        });
      },
      child: Container(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Image.asset(
          imagePath,
          color: isSelected ? Colors.black : Colors.white,
          width: 35,
          height: 35,
        ),
      ),
    );
  }
}
