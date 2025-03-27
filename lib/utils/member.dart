import 'package:flutter/material.dart';

class PeopleUtils {
  // Get initials from a user's name
  static String getInitials(String name) {
    return name
        .split(' ')
        .map((part) => part.isNotEmpty ? part[0].toUpperCase() : '')
        .join('');
  }

  // Generate a consistent color based on the user's name
  static Color getAvatarColor(String name) {
    final List<Color> colors = [
      Colors.blue,
      Colors.green.shade600,
      Colors.orange.shade700,
      Colors.purple.shade600,
      Colors.teal.shade600,
      Colors.pink.shade600,
      Colors.indigo.shade600,
      Colors.cyan.shade700,
    ];

    int hashCode = name.hashCode;
    return colors[hashCode.abs() % colors.length];
  }

  // Show a snackbar with a message
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }
}
