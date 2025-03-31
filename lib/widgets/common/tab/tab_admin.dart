import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:teammate/services/firestore_department_service.dart';
import 'package:teammate/services/firestore_project_service.dart';
import 'package:teammate/services/firestore_user_service.dart';
import 'package:teammate/widgets/common/dialog/dialog_addAdmin.dart';
import 'package:teammate/widgets/common/dialog/dialog_empty.dart';
import 'package:teammate/widgets/common/list_user.dart';
import 'package:teammate/theme/app_colors.dart';

class AdminsTab extends StatefulWidget {
  final List<dynamic> adminIds;
  final String searchQuery;
  final FirestoreUserService userService;
  final FirestoreDepartmentService departmentService;
  final FirestoreProjectService projectService;
  final String departmentId;
  final String projectId;
  final bool isAdmin;
  final bool isHead; // เพิ่มพารามิเตอร์สำหรับตรวจสอบว่าเป็น head หรือไม่

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
    this.isHead = false, // กำหนดค่าเริ่มต้นเป็น false
  });

  @override
  State<AdminsTab> createState() => _AdminsTabState();
}

class _AdminsTabState extends State<AdminsTab> {
  String? _projectHeadId;
  bool _isCurrentUserHead = false;

  @override
  void initState() {
    super.initState();
    _checkIfUserIsHead();
  }

  Future<void> _checkIfUserIsHead() async {
    try {
      // ดึง ID ของ head ของโปรเจค
      final headId = await widget.projectService.getHeadIdByProjectId(
        widget.projectId,
      );

      // ตรวจสอบว่าผู้ใช้ปัจจุบันเป็น head หรือไม่
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && headId == currentUser.uid) {
        setState(() {
          _isCurrentUserHead = true;
        });
      }

      setState(() {
        _projectHeadId = headId;
      });
    } catch (e) {
      print('Error checking if user is head: $e');
    }
  }

  void _showAddAdminDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AddAdminDialog(
            data: {
              'projectId': widget.projectId,
              'departments': [widget.departmentId],
              'headId':
                  _projectHeadId ?? FirebaseAuth.instance.currentUser?.uid,
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // แสดงปุ่มถ้าผู้ใช้เป็น admin หรือเป็น head
    bool showAddButton = _isCurrentUserHead || widget.isHead;

    return Column(
      children: [
        // Add Admin button for admin or project head

        // Admins list
        Expanded(child: _buildAdminsContent(context)),
        if (showAddButton)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: ElevatedButton.icon(
              onPressed: () => _showAddAdminDialog(context),
              icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
              label: const Text(
                'ADD ADMIN',
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

  Widget _buildAdminsContent(BuildContext context) {
    if (widget.adminIds.isEmpty) {
      return EmptyState(
        message: 'No administrators in this department',
        isAdmin: widget.isAdmin || _isCurrentUserHead,
        projectId: widget.projectId,
        departmentId: widget.departmentId,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: widget.adminIds.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final adminId = widget.adminIds[index];
        return UserListItem(
          userId: adminId,
          isAdmin: true,
          showAdminBadge: false, // We're already in the admins tab
          showOptions:
              widget.isAdmin ||
              _isCurrentUserHead, // Show options if user is admin or head
          searchQuery: widget.searchQuery,
          userService: widget.userService,
          departmentService: widget.departmentService,
          departmentId: widget.departmentId,
        );
      },
    );
  }
}
