// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:teammate/models/user_model.dart';
import 'package:teammate/screens/login_page.dart';
import 'package:teammate/services/auth_service.dart';
import 'package:teammate/widgets/navbar.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Check login state and get user data
  final authService = AuthService();
  final isLoggedIn = await authService.isLoggedIn();
  UserModel? loggedInUser;
  
  if (isLoggedIn) {
    loggedInUser = await authService.getCurrentUser();
    // If user data can't be retrieved, clear login state
    if (loggedInUser == null) {
      await authService.clearLoginState();
    }
  }
  
  runApp(MyApp(isLoggedIn: isLoggedIn && loggedInUser != null, user: loggedInUser));
}

class MyApp extends StatefulWidget {
  final bool isLoggedIn;
  final UserModel? user;
  
  const MyApp({super.key, required this.isLoggedIn, this.user});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeData _themeData = ThemeData.light();
  late UserModel? _user;
  late bool _isLoggedIn;
  final AuthService _authService = AuthService();
  
  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _isLoggedIn = widget.isLoggedIn;
  }
  
  // Toggle theme
  void _toggleTheme() {
    setState(() {
      _themeData = _themeData.brightness == Brightness.dark
          ? ThemeData.light()
          : ThemeData.dark();
    });
  }
  
  // Login function
  void login(UserModel user) {
    setState(() {
      _user = user;
      _isLoggedIn = true;
    });
  }
  
  // Logout function
  void logout() async {
    await _authService.clearLoginState();
    setState(() {
      _user = null;
      _isLoggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TeamMate App',
      theme: _themeData.copyWith(
        textTheme: _themeData.textTheme.apply(
          fontFamily: 'Poppins', 
        ),
        colorScheme: _themeData.brightness == Brightness.dark
            ? const ColorScheme.dark(
                primary: Colors.blue,
                secondary: Colors.lightBlue,
              )
            : const ColorScheme.light(
                primary: Colors.blue,
                secondary: Colors.lightBlue,
              ),
      ),
      home: _isLoggedIn && _user != null
          ? Navbar(
              user: _user!,
              onThemeToggle: _toggleTheme,
              onLogout: logout,
            )
          : LoginPage(
              onLogin: login,
              onThemeToggle: _toggleTheme,
            ),
    );
  }
}