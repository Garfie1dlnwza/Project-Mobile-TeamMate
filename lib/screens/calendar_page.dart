import 'package:flutter/material.dart';
import 'package:teammate/widgets/common/header_bar.dart';

class CalendarPage extends StatelessWidget {
  final String title;
  const CalendarPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: Headbar(title: title));
  }
}
