import 'package:flutter/material.dart';
import 'package:teammate/theme/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;
  final String? profileImageUrl;

  const ProfileAvatar({
    Key? key,
    required this.name,
    this.size = 36.0,
    this.backgroundColor,
    this.textColor,
    this.profileImageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String initial = _getInitial(name);
    final Color borderColor = backgroundColor ?? AppColors.primary;

    // Get a unique color based on the user's name
    final Color avatarColor = backgroundColor ?? _getColorFromName(name);

    // Use white text for darker background colors, dark text for lighter ones
    final bool isDarkColor = _isDarkColor(avatarColor);
    final Color actualTextColor =
        textColor ?? (isDarkColor ? Colors.white : Colors.grey[800]!);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer circle with border
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: size * 0.025),
            color: avatarColor.withOpacity(0.2),
          ),
        ),
        // Inner circle with profile image or initial
        Container(
          width: size * 0.92,
          height: size * 0.92,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                profileImageUrl == null || profileImageUrl!.isEmpty
                    ? avatarColor
                    : Colors.grey[200],
            image:
                profileImageUrl != null && profileImageUrl!.isNotEmpty
                    ? DecorationImage(
                      image: NetworkImage(profileImageUrl!),
                      fit: BoxFit.cover,
                    )
                    : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child:
              profileImageUrl == null || profileImageUrl!.isEmpty
                  ? Center(
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: actualTextColor,
                        fontSize: size * 0.4,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                  : null,
        ),
      ],
    );
  }

  // Generate a color based on the user's name
  Color _getColorFromName(String name) {
    if (name.isEmpty) {
      return Colors.grey;
    }

    // Predefined vibrant colors for avatars
    final List<List<Color>> colorOptions = [
      [Colors.red.shade300, Colors.red.shade700],
      [Colors.pink.shade300, Colors.pink.shade700],
      [Colors.purple.shade300, Colors.purple.shade700],
      [Colors.deepPurple.shade300, Colors.deepPurple.shade700],
      [Colors.indigo.shade300, Colors.indigo.shade700],
      [Colors.blue.shade300, Colors.blue.shade700],
      [Colors.lightBlue.shade300, Colors.lightBlue.shade700],
      [Colors.cyan.shade300, Colors.cyan.shade700],
      [Colors.teal.shade300, Colors.teal.shade700],
      [Colors.green.shade300, Colors.green.shade700],
      [Colors.lightGreen.shade300, Colors.lightGreen.shade700],
      [Colors.lime.shade300, Colors.lime.shade700],
      [Colors.amber.shade300, Colors.amber.shade700],
      [Colors.orange.shade300, Colors.orange.shade700],
      [Colors.deepOrange.shade300, Colors.deepOrange.shade700],
      [Colors.brown.shade300, Colors.brown.shade700],
    ];

    // Use hash code to deterministically select a color
    final int colorIndex = name.hashCode.abs() % colorOptions.length;

    // Use the middle color for simplicity
    return colorOptions[colorIndex][0];
  }

  // Determine if a color is dark (to use white text) or light (to use dark text)
  bool _isDarkColor(Color color) {
    // Calculate relative luminance
    // Using the formula: 0.299*R + 0.587*G + 0.114*B
    final double luminance =
        (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;

    // Return true if the color is dark (luminance < 0.5)
    return luminance < 0.5;
  }

  String _getInitial(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';

    // If there's only one part, return its first letter
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    }

    // If there are multiple parts, return the first letter of the first and last parts
    final firstInitial =
        parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '';
    final lastInitial =
        parts.last.isNotEmpty ? parts.last[0].toUpperCase() : '';

    // If both initials are available, return them combined
    if (firstInitial.isNotEmpty && lastInitial.isNotEmpty) {
      return '$firstInitial$lastInitial';
    }

    // Otherwise fall back to just the first initial or a placeholder
    return firstInitial.isNotEmpty ? firstInitial : '?';
  }
}
