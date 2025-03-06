import 'package:flutter/material.dart';
import 'package:teammate/models/user_model.dart';
import 'package:teammate/screens/home.dart';

class Navbar extends StatefulWidget {
  final UserModel user;

  const Navbar({super.key, required this.user});

  @override
  _NavbarState createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  int currentIndex = 0;
  List pageNavbar = [HomePage(),HomePage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: pageNavbar[currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home')
        ],
      ),
    );
  }
}
