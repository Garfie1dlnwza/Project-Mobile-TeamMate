import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;
  final String? profileImageUrl;
  final bool isOnline;
  final VoidCallback? onTap;
  final bool showShadow;

  const ProfileAvatar({
    super.key,
    required this.name,
    this.size = 36.0,
    this.backgroundColor,
    this.textColor,
    this.profileImageUrl,
    this.isOnline = false,
    this.onTap,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final String initial = _getInitial(name);

    // Get color from name or use provided background color
    final Color avatarColor = backgroundColor ?? _getColorFromName(name);

    // Determine text color based on background darkness
    final bool isDarkColor = _isDarkColor(avatarColor);
    final Color actualTextColor =
        textColor ?? (isDarkColor ? Colors.white : Colors.grey[800]!);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Stack(
          children: [
            // Main avatar circle
            Center(
              child: Container(
                width: size * 0.95,
                height: size * 0.95,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      profileImageUrl == null || profileImageUrl!.isEmpty
                          ? avatarColor
                          : Colors.grey[200],
                  boxShadow:
                      showShadow
                          ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: avatarColor.withOpacity(0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                              spreadRadius: 2,
                            ),
                          ]
                          : null,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.9),
                    width: size * 0.02,
                  ),
                  image:
                      profileImageUrl != null && profileImageUrl!.isNotEmpty
                          ? DecorationImage(
                            image: NetworkImage(profileImageUrl!),
                            fit: BoxFit.cover,
                          )
                          : null,
                ),
                child:
                    profileImageUrl == null || profileImageUrl!.isEmpty
                        ? Center(
                          child: Text(
                            initial,
                            style: TextStyle(
                              color: actualTextColor,
                              fontSize: size * 0.36,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        )
                        : null,
              ),
            ),

            // Optional online status indicator
            if (isOnline)
              Positioned(
                right: size * 0.05,
                bottom: size * 0.05,
                child: Container(
                  width: size * 0.28,
                  height: size * 0.28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                    border: Border.all(
                      color: Colors.white,
                      width: size * 0.035,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),

            // Subtle highlight effect (top-left inner white gradient)
            Center(
              child: ClipOval(
                child: Container(
                  width: size * 0.95,
                  height: size * 0.95,
                  foregroundDecoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.transparent,
                        Colors.black.withOpacity(0.05),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Generate a color based on the user's name
  Color _getColorFromName(String name) {
    if (name.isEmpty) {
      return Colors.grey;
    }

    // Minimal and modern color palette
    final List<Color> colorOptions = [
      const Color(0xFF5E97F6), // Blue
      const Color(0xFF4DD0E1), // Cyan
      const Color(0xFF4CAF50), // Green
      const Color(0xFFF06292), // Pink
      const Color(0xFF9575CD), // Purple
      const Color(0xFFFF8A65), // Orange
      const Color(0xFF7E57C2), // Deep Purple
      const Color(0xFF26A69A), // Teal
      const Color(0xFFAB47BC), // Purple
      const Color(0xFF66BB6A), // Light Green
      const Color(0xFFEC407A), // Pink
      const Color(0xFF42A5F5), // Light Blue
      const Color(0xFF78909C), // Blue Grey
      const Color(0xFF5C6BC0), // Indigo
      const Color(0xFFFFCA28), // Amber
      const Color(0xFF7CB342), // Light Green
    ];

    // Use hash code to deterministically select a color
    final int colorIndex = name.hashCode.abs() % colorOptions.length;
    return colorOptions[colorIndex];
  }

  // Determine if a color is dark (to use white text) or light (to use dark text)
  bool _isDarkColor(Color color) {
    // Calculate relative luminance using formula: 0.299*R + 0.587*G + 0.114*B
    final double luminance =
        (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
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
