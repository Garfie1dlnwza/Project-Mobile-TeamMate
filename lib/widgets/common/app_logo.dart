import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double height;
  final double? width;

  const AppLogo({super.key, this.height = 200, this.width});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'app_logo',
      child: Image.asset(
        'assets/images/logoTeamMate.png',
        height: height,
        width: width ?? double.infinity,
        fit: BoxFit.contain,
      ),
    );
  }
}
