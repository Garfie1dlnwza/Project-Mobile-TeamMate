import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:teammate/services/firestore_department_service.dart';
import 'package:teammate/services/firestore_project_service.dart';
import 'package:teammate/services/firestore_user_service.dart';
import 'package:teammate/widgets/common/dialog/dialog_addAdmin.dart';
import 'package:teammate/widgets/common/dialog/dialog_empty.dart';
import 'package:teammate/widgets/common/list_user.dart';
import 'package:teammate/theme/app_colors.dart';

class AdminsTab extends StatelessWidget {
  final List<dynamic> adminIds;
  final String searchQuery;
  final FirestoreUserService userService;
  final FirestoreDepartmentService departmentService;
  final FirestoreProjectService projectService;
  final String departmentId;
  final String projectId;
  final bool isAdmin;

  const AdminsTab({
    super.key,
    required this.adminIds,
    required this.searchQuery,
    required this.userService,
    required this.departmentService,
    required this.projectService,
    required this.departmentId,
    required this.projectId,
    required this.isAdmin,
  });

  void _showAddAdminDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AddAdminDialog(
            data: {
              'projectId': projectId,
              'departments': [departmentId],
              'headId': FirebaseAuth.instance.currentUser?.uid,
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Add Admin button for admin or project head
        if (isAdmin)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: ElevatedButton.icon(
              onPressed: () => _showAddAdminDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Admin'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

        // Admins list
        Expanded(child: _buildAdminsContent(context)),
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
          showOptions: isAdmin, // Show options only if user is admin
          searchQuery: searchQuery,
          userService: userService,
          departmentService: departmentService,
          departmentId: departmentId,
        );
      },
    );
  }
}
