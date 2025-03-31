import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const TextStyle heading = TextStyle(
    fontFamily: 'Poppins',
    fontWeight: FontWeight.bold,
    fontSize: 33,
    letterSpacing: 3.5,
    color: AppColors.primary,
  );

  static const TextStyle subheading = TextStyle(
    color: AppColors.hintText,
    fontSize: 16,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.buttonText,
  );

  static const TextStyle linkText = TextStyle(
    color: AppColors.secondary,
    decoration: TextDecoration.underline,
  );

  static const TextStyle inputLabel = TextStyle(
    color: AppColors.labelText,
    fontSize: 14,
  );

  static const TextStyle errorText = TextStyle(
    color: AppColors.errorText,
    fontSize: 12,
  );
}
