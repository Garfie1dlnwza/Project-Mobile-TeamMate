import 'package:flutter/material.dart';
import 'package:teammate/models/user_model.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required UserModel user});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Icon(Icons.tune),
    );
  }
}