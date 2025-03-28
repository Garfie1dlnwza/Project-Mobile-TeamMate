import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teammate/services/firestore_project_service.dart';
import 'package:teammate/services/firestore_user_service.dart';
import 'package:teammate/theme/app_colors.dart';
import 'package:teammate/widgets/common/profile.dart';

class HeadTab extends StatelessWidget {
  final String? headId;
  final String searchQuery;
  final FirestoreUserService userService;
  final FirestoreProjectService projectService;
  final bool isAdmin;
  final bool isHead;
  final String projectId;
  final bool showAddButton;
  final VoidCallback? onAddButtonPressed;

  const HeadTab({
    Key? key,
    required this.headId,
    required this.searchQuery,
    required this.userService,
    required this.projectService,
    required this.isAdmin,
    required this.isHead,
    required this.projectId,
    this.showAddButton = false,
    this.onAddButtonPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildHeadContent(context)),
        // Add people button at the bottom of the tab
        if (showAddButton && onAddButtonPressed != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            color: Colors.white,
            child: ElevatedButton.icon(
              onPressed: onAddButtonPressed,
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: const Text(
                'ADD PEOPLE',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeadContent(BuildContext context) {
    if (headId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No project head assigned',
              style: TextStyle(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: userService.getUserById(headId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(
            child: Text(
              'Project head not found',
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;

        if (userData == null) {
          return const Center(
            child: Text(
              'No user data available',
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        // Check if the user matches the search query
        final String fullName =
            '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}';
        final String email = userData['email'] ?? '';

        if (searchQuery.isNotEmpty &&
            !fullName.toLowerCase().contains(searchQuery.toLowerCase()) &&
            !email.toLowerCase().contains(searchQuery.toLowerCase())) {
          return const Center(
            child: Text('No matching results', style: TextStyle(fontSize: 16)),
          );
        }

        return Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _buildHeadProfileCard(userData, context),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeadProfileCard(
    Map<String, dynamic> userData,
    BuildContext context,
  ) {
    final String fullName = '${userData['name'] ?? ''}';
    final String email = userData['email'] ?? '';
    final String? profileImageUrl = userData['profileImageUrl'];
    final String role = userData['role'] ?? 'Project Head';
    final String phone = userData['phone'] ?? 'Not provided';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Header with gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryGradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: const Column(
              children: [
                Text(
                  'PROJECT HEAD',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Team Leader & Project Manager',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),

          // Profile section
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Profile image using ProfileAvatar
                ProfileAvatar(
                  name: fullName,
                  size: 120,
                  profileImageUrl: profileImageUrl,
                  backgroundColor: AppColors.primary,
                ),
                const SizedBox(height: 12),

                // User name
                Text(
                  fullName,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                // Role badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    role,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildInfoTile(
                        icon: Icons.email,
                        title: 'Email',
                        value: email,
                      ),
                      const Divider(height: 24),
                      _buildInfoTile(
                        icon: Icons.phone,
                        title: 'Phone',
                        value: phone,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Contact buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _buildContactButton(
                        icon: Icons.email,
                        label: 'Send Email',
                        onTap: () {
                          // Implement email functionality
                        },
                        isPrimary: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildContactButton(
                        icon: Icons.chat,
                        label: 'Message',
                        onTap: () {
                          // Implement messaging functionality
                        },
                        isPrimary: false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        backgroundColor: isPrimary ? AppColors.primary : Colors.white,
        foregroundColor: isPrimary ? Colors.white : AppColors.primary,
        elevation: isPrimary ? 2 : 0,
        side: BorderSide(
          color: isPrimary ? Colors.transparent : AppColors.primary,
          width: 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
