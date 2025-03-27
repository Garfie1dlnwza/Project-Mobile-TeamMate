import 'package:flutter/material.dart';
import 'package:teammate/services/firestore_department_service.dart';
import 'package:teammate/services/firestore_user_service.dart';
import 'package:teammate/widgets/common/dialog/dialog_empty.dart';
import 'package:teammate/widgets/common/list_user.dart';

class AllMembersTab extends StatelessWidget {
  final List<dynamic> userIds;
  final List<dynamic> adminIds;
  final bool isAdmin;
  final String searchQuery;
  final FirestoreUserService userService;
  final FirestoreDepartmentService departmentService;
  final String departmentId;
  final String projectId;

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
  });

  @override
  Widget build(BuildContext context) {
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
