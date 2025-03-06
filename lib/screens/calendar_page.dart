import 'package:flutter/material.dart';
import 'package:teammate/models/user_model.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key, required UserModel user});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Icon(Icons.calendar_today_outlined),
    );
  }
}