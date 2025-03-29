import 'package:flutter/material.dart';
import 'package:teammate/widgets/common/header_bar.dart';

class HomePage extends StatelessWidget {
  final String title;
  const HomePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: Headbar(title: title));
  }
}
