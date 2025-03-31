// lib/screens/login_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:teammate/theme/app_colors.dart';
import 'package:teammate/theme/app_text_styles.dart';
import 'package:teammate/utils/validators.dart';
import 'package:teammate/widgets/auth/auth_button.dart';
import 'package:teammate/widgets/auth/auth_text_field.dart';
import 'package:teammate/widgets/common/app_logo.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  bool _isPasswordVisible = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      try {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });

        final UserCredential credential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );

        final user = credential.user;
        if (user != null) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            Navigator.pushReplacementNamed(context, '/navbar');
          }
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          _errorMessage = e.message ?? 'An error occurred during login';
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'An unexpected error occurred';
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryGradientStart,
              AppColors.primaryGradientEnd,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 45),
            const AppLogo(),
            const SizedBox(height: 15),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(100),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text(
                              "Welcome Back",
                              style: AppTextStyles.heading,
                            ),
                          ),
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(0, 2, 100, 20),
                              child: Text(
                                'Login to your account',
                                style: AppTextStyles.subheading,
                              ),
                            ),
                          ),
                          if (_errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AuthTextField(
                                  controller: _emailController,
                                  label: "Email",
                                  prefixIcon: Icons.email,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: Validators.validateEmail,
                                ),
                                const SizedBox(height: 20),
                                AuthTextField(
                                  controller: _passwordController,
                                  label: "Password",
                                  prefixIcon: Icons.lock,
                                  isPassword: true,
                                  isPasswordVisible: _isPasswordVisible,
                                  onTogglePassword: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                  validator: Validators.validatePassword,
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      // Handle forgot password
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                    ),
                                    child: const Text(
                                      'Forgot Password?',
                                      style: AppTextStyles.linkText,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 30),
                                AuthButton(text: 'Login', onPressed: _login),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      "Don't have an account? ",
                                      style: TextStyle(
                                        color: AppColors.labelText,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap:
                                          () => Navigator.pushNamed(
                                            context,
                                            '/register',
                                          ),
                                      child: const Text(
                                        'Register',
                                        style: TextStyle(
                                          color: AppColors.linkText,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
