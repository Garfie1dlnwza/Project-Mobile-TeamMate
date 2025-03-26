// lib/main.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:teammate/screens/creates/create_project_page.dart';
import 'package:teammate/screens/settings/changepassword_page.dart';
import 'package:teammate/screens/login_page.dart';
import 'package:teammate/screens/register_page.dart';
import 'package:teammate/screens/settings/edit_name.dart';
import 'package:teammate/screens/myworks/work_page2.dart';
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
  ThemeData _themeData = customLightTheme;

  void _toggleTheme() {
    setState(() {
      _themeData =
          _themeData.brightness == Brightness.dark
              ? customLightTheme
              : customDarkTheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TeamMate App',
      theme: _themeData,
      initialRoute:
          FirebaseAuth.instance.currentUser == null ? '/login' : '/navbar',
      routes: {
        '/login': (context) => LoginPage(),
        '/navbar': (context) => Navbar(),
        '/register': (context) => RegisterPage(),
        '/create_project': (context) => CreateProjectPage(),
        '/changepassword': (context) => ChangePasswordPage(),
        '/editname': (context) => EditNamePage(),
      },
    );
  }
}

ThemeData customLightTheme = ThemeData.light().copyWith(
  colorScheme: const ColorScheme.light(
    primary: Color.fromARGB(255, 255, 255, 255),
    secondary: Colors.indigoAccent,
    surface: Colors.white,
    onPrimary: Colors.white,
    onSecondary: Colors.black,
  ),
  scaffoldBackgroundColor: Colors.white,
  
  textTheme: ThemeData.light().textTheme.apply(fontFamily: 'Poppins'),
);

ThemeData customDarkTheme = ThemeData.dark().copyWith(
  colorScheme: const ColorScheme.dark(
    primary: Colors.blueGrey,
    secondary: Colors.tealAccent,
    surface: Colors.black,
    onPrimary: Colors.white,
    onSecondary: Colors.black,
  ),
  scaffoldBackgroundColor: Colors.black,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.blueGrey,
    foregroundColor: Colors.white,
  ),
  textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Poppins'),
);
