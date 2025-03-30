import 'package:flutter/material.dart';
import 'package:teammate/services/firestore_department_service.dart';
import 'package:teammate/services/firestore_user_service.dart';
import 'package:teammate/widgets/common/dialog/dialog_empty.dart';
import 'package:teammate/widgets/common/list_user.dart';
import 'package:teammate/theme/app_colors.dart';

class AllMembersTab extends StatelessWidget {
  final List<dynamic> userIds;
  final List<dynamic> adminIds;
  final bool isAdmin;
  final String searchQuery;
  final FirestoreUserService userService;
  final FirestoreDepartmentService departmentService;
  final String departmentId;
  final String projectId;
  final bool showAddButton;
  final VoidCallback? onAddButtonPressed;

  const AllMembersTab({
    super.key,
    required this.userIds,
    required this.adminIds,
    required this.isAdmin,
    required this.searchQuery,
    required this.userService,
    required this.departmentService,
    required this.departmentId,
    required this.projectId,
    this.showAddButton = false,
    this.onAddButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildMembersContent(context)),

        if (showAddButton && onAddButtonPressed != null)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
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
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMembersContent(BuildContext context) {
    if (userIds.isEmpty) {
      return EmptyState(
        message: 'No members in this department',
        isAdmin: isAdmin,
        projectId: projectId,
        departmentId: departmentId,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: userIds.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final userId = userIds[index];
        final isUserAdmin = adminIds.contains(userId);
        return UserListItem(
          userId: userId,
          isAdmin: isUserAdmin,
          showAdminBadge: true,
          showOptions: isAdmin && !isUserAdmin,
          searchQuery: searchQuery,
          userService: userService,
          departmentService: departmentService,
          departmentId: departmentId,
        );
      },
    );
  }
}
