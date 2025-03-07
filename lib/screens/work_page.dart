import 'package:flutter/material.dart';
import 'package:teammate/models/user_model.dart';
import 'package:teammate/widgets/common/header_bar.dart';

class WorkPage extends StatelessWidget {
  final String title;
  const WorkPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: Headbar(title: title));
  }
}
