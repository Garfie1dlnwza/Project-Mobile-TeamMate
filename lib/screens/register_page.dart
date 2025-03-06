// lib/screens/register_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:teammate/models/user_model.dart';
import 'package:teammate/screens/login_page.dart';
import 'package:teammate/services/auth_service.dart';
import 'package:teammate/theme/app_colors.dart';
import 'package:teammate/theme/app_text_styles.dart';
import 'package:teammate/widgets/navbar.dart';
import 'package:teammate/widgets/auth/auth_button.dart';
import 'package:teammate/widgets/auth/auth_text_field.dart';

class RegisterPage extends StatefulWidget {
  final Function(UserModel) onRegister;
  final VoidCallback onThemeToggle;

  const RegisterPage({
    Key? key, 
    required this.onRegister, 
    required this.onThemeToggle
  }) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String fullName =
          "${_nameController.text.trim()} ${_surnameController.text.trim()}";

      // Create UserModel object
      UserModel newUser = UserModel(
        id: "", // Temporary placeholder, will be updated in AuthService
        name: fullName,
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(), // Will not be stored in Firestore
        phoneNumber: _phoneNumberController.text.trim(),
        profileImage: 'assets/images/default.png',
        projects: [],
      );

      // Register account using AuthService
      UserModel? user = await _authService.registerUser(userModel: newUser);

      if (user != null && mounted) {
        // Call the onRegister callback
        widget.onRegister(user);
        
        // Navigate to Navbar
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Navbar(
              user: user,
              onThemeToggle: widget.onThemeToggle,
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'An error occurred during registration.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
      debugPrint("Error in _register: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    // Add your border radius here if needed
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 65),
                      const Center(
                        child: Text(
                          "Register",
                          style: AppTextStyles.heading,
                        ),
                      ),
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(0, 2, 0, 20),
                          child: Text(
                            'Create your new account',
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
                            // Name and Surname in one row
                            Row(
                              children: [
                                Expanded(
                                  child: AuthTextField(
                                    controller: _nameController,
                                    label: "Name",
                                    prefixIcon: Icons.person,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your name';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: AuthTextField(
                                    controller: _surnameController,
                                    label: "Surname",
                                    prefixIcon: Icons.person_outline,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your surname';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Phone Number Field
                            AuthTextField(
                              controller: _phoneNumberController,
                              label: "Phone Number",
                              prefixIcon: Icons.phone,
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your phone number';
                                }
                                // Basic phone number validation
                                if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                                  return 'Please enter a valid 10-digit phone number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Email Field
                            AuthTextField(
                              controller: _emailController,
                              label: "Email",
                              prefixIcon: Icons.email,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter an email';
                                }
                                // Basic email validation
                                if (!RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                ).hasMatch(value)) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Password Field
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
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a password';
                                } else if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Confirm Password Field
                            AuthTextField(
                              controller: _confirmPasswordController,
                              label: "Confirm Password",
                              prefixIcon: Icons.lock,
                              isPassword: true,
                              isPasswordVisible: _isPasswordVisible,
                              onTogglePassword: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password';
                                } else if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Password Visibility Toggle
                            Row(
                              children: [
                                Checkbox(
                                  value: _isPasswordVisible,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      _isPasswordVisible = value ?? false;
                                    });
                                  },
                                ),
                                const Text('Show Password'),
                              ],
                            ),

                            const SizedBox(height: 30),
                            AuthButton(
                              text: 'Register',
                              onPressed: _register,
                              isLoading: _isLoading,
                            ),
                            const SizedBox(height: 20),

                            // Back to Sign In Button
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LoginPage(
                                      onLogin: widget.onRegister,
                                      onThemeToggle: widget.onThemeToggle,
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                'Already have an account? Sign In',
                                style: TextStyle(
                                  color: AppColors.linkText,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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