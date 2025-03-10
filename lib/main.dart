// lib/main.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:teammate/screens/login_page.dart';
import 'package:teammate/screens/register_page.dart';
import 'package:teammate/widgets/common/navbar.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeData _themeData = ThemeData.light();
  void _toggleTheme() {
    setState(() {
      _themeData =
          _themeData.brightness == Brightness.dark
              ? ThemeData.light()
              : ThemeData.dark();
    });
  }

  @override
  Widget build(BuildContext context) {
    // FirebaseAuth.instance.signOut();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TeamMate App',
      theme: _themeData.copyWith(
        textTheme: _themeData.textTheme.apply(fontFamily: 'Poppins'),
        colorScheme:
            _themeData.brightness == Brightness.dark
                ? const ColorScheme.dark(
                  primary: Colors.blue,
                  secondary: Colors.lightBlue,
                )
                : const ColorScheme.light(
                  primary: Colors.blue,
                  secondary: Colors.lightBlue,
                ),
      ),
      initialRoute:
          FirebaseAuth.instance.currentUser == null ? '/login' : '/navbar',
      routes: {
        '/login': (context) => LoginPage(),
        '/navbar': (context) => Navbar(),
        '/register': (context) => RegisterPage(),
      },
    );
  }
}
