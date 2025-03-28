import 'package:flutter/material.dart';
import 'package:teammate/services/firestore_department_service.dart';
import 'package:teammate/services/firestore_user_service.dart';
import 'package:teammate/widgets/common/dialog/dialog_empty.dart';
import 'package:teammate/widgets/common/list_user.dart';
import 'package:teammate/theme/app_colors.dart';

class AdminsTab extends StatelessWidget {
  final List<dynamic> adminIds;
  final String searchQuery;
  final FirestoreUserService userService;
  final bool isAdmin;
  final FirestoreDepartmentService departmentService;
  final String departmentId;
  final String projectId;
  final bool showAddButton;
  final VoidCallback? onAddButtonPressed;

  const AdminsTab({
    super.key,
    required this.adminIds,
    required this.searchQuery,
    required this.userService,
    required this.isAdmin,
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
        Expanded(child: _buildAdminsContent(context)),
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

  Widget _buildAdminsContent(BuildContext context) {
    if (adminIds.isEmpty) {
      return EmptyState(
        message: 'No administrators in this department',
        isAdmin: isAdmin,
        projectId: projectId,
        departmentId: departmentId,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: adminIds.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final adminId = adminIds[index];
        return UserListItem(
          userId: adminId,
          isAdmin: true,
          showAdminBadge: false, // We're already in the admins tab
          showOptions: false, // No options for admins in this tab
          searchQuery: searchQuery,
          userService: userService,
          departmentService: departmentService,
          departmentId: departmentId,
        );
      },
    );
  }
}
