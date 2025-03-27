import 'package:flutter/material.dart';
import 'package:teammate/services/firestore_department_service.dart';
import 'package:teammate/services/firestore_user_service.dart';
import 'package:teammate/widgets/common/dialog/dialog_empty.dart';
import 'package:teammate/widgets/common/list_user.dart';


class AdminsTab extends StatelessWidget {
  final List<dynamic> adminIds;
  final String searchQuery;
  final FirestoreUserService userService;
  final bool isAdmin;
  final FirestoreDepartmentService departmentService;
  final String departmentId;
  final String projectId;

  const AdminsTab({
    super.key,
    required this.adminIds,
    required this.searchQuery,
    required this.userService,
    required this.isAdmin,
    required this.departmentService,
    required this.departmentId,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context) {
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
