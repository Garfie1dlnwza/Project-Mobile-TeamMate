import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teammate/services/firestore_user_service.dart';
import 'package:teammate/services/firestore_department_service.dart';
import 'package:teammate/utils/member.dart';

class UserListItem extends StatelessWidget {
  final String userId;
  final bool isAdmin;
  final bool showAdminBadge;
  final bool showOptions;
  final String searchQuery;
  final FirestoreUserService userService;
  final FirestoreDepartmentService departmentService;
  final String departmentId;

  const UserListItem({
    super.key,
    required this.userId,
    required this.isAdmin,
    required this.showAdminBadge,
    required this.showOptions,
    required this.searchQuery,
    required this.userService,
    required this.departmentService,
    required this.departmentId,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: userService.getUserById(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            title: Text('Loading...'),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person_outline, color: Colors.grey),
            ),
            title: Text(
              snapshot.hasError ? 'Error loading user' : 'User not found',
            ),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;

        if (userData == null) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person_outline, color: Colors.grey),
            ),
            title: const Text('No user data'),
          );
        }

        final String userName = userData['name'] ?? 'No name';
        final String userEmail = userData['email'] ?? 'No email';

        // Filter by search query if needed
        if (searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase();
          final nameMatch = userName.toLowerCase().contains(query);
          final emailMatch = userEmail.toLowerCase().contains(query);

          if (!nameMatch && !emailMatch) {
            return const SizedBox.shrink(); // Hide if doesn't match search
          }
        }

        // Get initials for avatar
        final String initials = PeopleUtils.getInitials(userName);
        final Color avatarColor = PeopleUtils.getAvatarColor(userName);

        return Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: avatarColor,
              radius: 24,
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (showAdminBadge && isAdmin)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Admin',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                userEmail,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
          ),
        );
      },
    );
  }
}
