import 'package:flutter/material.dart';
import 'package:teammate/models/user_model.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required UserModel user});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Icon(Icons.home_outlined),
    );
  }
}