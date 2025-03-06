import 'package:flutter/material.dart';
import 'package:teammate/models/user_model.dart';

class WorkPage extends StatelessWidget {
  const WorkPage({super.key, required UserModel user});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Icon(Icons.work_outline),
    );
  }
}