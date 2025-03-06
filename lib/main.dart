import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:teammate/models/user_model.dart';
import 'package:teammate/screens/login_page.dart';
import 'package:teammate/widgets/navbar.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeData _themeData = ThemeData.light();
  void _toggleTheme() {
    setState(() {
      _themeData =
          _themeData.brightness == Brightness.dark
              ? ThemeData.light() // เปลี่ยนไปใช้ ThemeData.light()
              : ThemeData.dark(); // เปลี่ยนไปใช้ ThemeData.dark()
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // ซ่อน Debug Banner
      title: 'TeamMate App',
      theme: _themeData.copyWith(
        textTheme: _themeData.textTheme.apply(
          fontFamily: 'Poppins', 
        ),
      ),
      home: LoginPage(),
    );
  }
}
