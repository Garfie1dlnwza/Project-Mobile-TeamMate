import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:teammate/theme/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  final String name;
  final double size;
  final String? imageUrl;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onTap;
  final BoxBorder? border;

  const ProfileAvatar({
    Key? key,
    required this.name,
    this.size = 40,
    this.imageUrl,
    this.backgroundColor = AppColors.secondary,
    this.textColor = Colors.white,
    this.onTap,
    this.border, String? profileImageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: onTap,
      child:
          imageUrl != null && imageUrl!.isNotEmpty
              ? _buildNetworkAvatar(initial)
              : _buildInitialAvatar(initial),
    );
  }

  Widget _buildNetworkAvatar(String fallbackInitial) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, border: border),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          fit: BoxFit.cover,
          placeholder:
              (context, url) => Container(
                color: backgroundColor.withOpacity(0.3),
                child: Center(
                  child: SizedBox(
                    width: size / 3,
                    height: size / 3,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        backgroundColor.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              ),
          errorWidget:
              (context, url, error) => _buildInitialAvatar(fallbackInitial),
        ),
      ),
    );
  }

  Widget _buildInitialAvatar(String initial) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: border,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }
}

class ProfileAvatarGroup extends StatelessWidget {
  final List<String> imageUrls;
  final List<String> names;
  final double avatarSize;
  final double overlap;
  final int maxDisplayed;
  final VoidCallback? onMoreTap;

  const ProfileAvatarGroup({
    Key? key,
    required this.imageUrls,
    required this.names,
    this.avatarSize = 36,
    this.overlap = 0.3,
    this.maxDisplayed = 4,
    this.onMoreTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate how many we can display
    final int totalToShow =
        imageUrls.length > maxDisplayed ? maxDisplayed : imageUrls.length;

    // Calculate total width
    final double totalWidth =
        avatarSize + (avatarSize * (1 - overlap) * (totalToShow - 1));

    return SizedBox(
      width: totalWidth,
      height: avatarSize,
      child: Stack(
        children: [
          // Display avatars with specified overlap
          for (int i = 0; i < totalToShow; i++)
            Positioned(
              left: i * (avatarSize * (1 - overlap)),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child:
                    i < totalToShow - 1 || imageUrls.length <= maxDisplayed
                        ? ProfileAvatar(
                          imageUrl: i < imageUrls.length ? imageUrls[i] : null,
                          name: i < names.length ? names[i] : '?',
                          size: avatarSize,
                        )
                        : _buildMoreAvatars(
                          imageUrls.length - maxDisplayed + 1,
                        ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMoreAvatars(int count) {
    return GestureDetector(
      onTap: onMoreTap,
      child: Container(
        width: avatarSize,
        height: avatarSize,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            "+$count",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final String? subtitle;
  final VoidCallback? onAvatarTap;
  final Widget? trailing;
  final double avatarSize;

  const ProfileHeader({
    Key? key,
    this.imageUrl,
    required this.name,
    this.subtitle,
    this.onAvatarTap,
    this.trailing,
    this.avatarSize = 50,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ProfileAvatar(
          imageUrl: imageUrl,
          name: name,
          size: avatarSize,
          onTap: onAvatarTap,
          border: Border.all(color: AppColors.background, width: 2),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class ProfileGrid extends StatelessWidget {
  final List<Map<String, dynamic>> profiles;
  final Function(Map<String, dynamic> profile)? onProfileTap;
  final int crossAxisCount;
  final double spacing;
  final double avatarSize;

  const ProfileGrid({
    Key? key,
    required this.profiles,
    this.onProfileTap,
    this.crossAxisCount = 4,
    this.spacing = 16.0,
    this.avatarSize = 60.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: profiles.length,
      itemBuilder: (context, index) {
        final profile = profiles[index];
        final name = profile['name'] as String? ?? '';
        final imageUrl = profile['imageUrl'] as String?;

        return GestureDetector(
          onTap: onProfileTap != null ? () => onProfileTap!(profile) : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProfileAvatar(name: name, imageUrl: imageUrl, size: avatarSize),
              const SizedBox(height: 8),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}
