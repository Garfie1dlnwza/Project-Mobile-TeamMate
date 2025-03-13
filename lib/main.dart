// lib/main.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teammate/screens/settings/changepassword_page.dart';
import 'package:teammate/screens/login_page.dart';
import 'package:teammate/screens/register_page.dart';

import 'package:teammate/screens/settings/edit_name.dart';
import 'package:teammate/widgets/common/navbar.dart';
import 'firebase_options.dart';

const supabaseUrl = 'https://pbmdxpblojftznnabrdl.supabase.co';
const supabaseKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBibWR4cGJsb2pmdHpubmFicmRsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE2NzU1NjYsImV4cCI6MjA1NzI1MTU2Nn0.0sHm8koN3Q7tJa-jMOSttq1GuF8NHtZpGmiO1h23ZKw';

void main() async {
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
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
                  primary: Color.fromARGB(255, 255, 255, 255),
                  secondary: Color.fromARGB(255, 255, 255, 255),
                ),
      ),
      initialRoute:
          FirebaseAuth.instance.currentUser == null ? '/login' : '/navbar',
      routes: {
        '/login': (context) => LoginPage(),
        '/navbar': (context) => Navbar(),
        '/register': (context) => RegisterPage(),
        '/changepassword': (context) => ChangePasswordPage(),
        '/editname': (context) => EditNamePage(),
      },
    );
  }
}
