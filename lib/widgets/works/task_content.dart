import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teammate/screens/details/task_detail_admin_page.dart';
import 'package:teammate/services/firestore_department_service.dart';
import 'package:teammate/services/firestore_project_service.dart';
import 'package:teammate/utils/date.dart';

class TaskContent extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color themeColor;

  const TaskContent({super.key, required this.data, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    final String title = data['taskTitle'] ?? 'Untitled Task';
    final bool isSubmitted = data['isSubmit'] ?? false;
    final bool isApproved = data['isApproved'] ?? false;
    final bool isRejected = data['isRejected'] ?? false;
    final Timestamp endDate = data['endTask'] ?? Timestamp.now();
    final DateTime dueDate = endDate.toDate();
    final bool isOverdue =
        DateTime.now().isAfter(dueDate) && !isApproved && !isSubmitted;
    final Duration timeLeft = dueDate.difference(DateTime.now());
    final bool isUrgent =
        timeLeft.inDays <= 2 && !isApproved && !isSubmitted && !isRejected;

    return InkWell(
      onTap: () {
        // Navigate to details page
        _checkUserRoleAndNavigate(context);
      },
      child: Card(
        elevation: 1.5,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(
                        isSubmitted,
                        isOverdue,
                        isUrgent,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getPriorityText(isSubmitted, isOverdue, isUrgent),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: isOverdue ? Colors.red[400] : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormatter.formatDateShort(dueDate),
                    style: TextStyle(
                      fontSize: 13,
                      color: isOverdue ? Colors.red[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Task title
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 16),

              // Task action buttons
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.end,
              //   children: [
              //     _buildActionButton(
              //       icon: Icons.remove_red_eye,
              //       label: 'Details',
              //       color: Colors.grey[700]!,
              //       backgroundColor: Colors.grey[200]!,
              //       onPressed: () {
              //         // Navigate to details page
              //         _checkUserRoleAndNavigate(context);
              //       },
              //     ),
              //     const SizedBox(width: 10),
              //   ],
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkUserRoleAndNavigate(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // Navigate to regular details page if not logged in
      _navigateToDetailsPage(context, false);
      return;
    }

    final userId = currentUser.uid;

    final departmentId = data['departmentId'];
    final department = await FirestoreDepartmentService().getDepartmentById(
      departmentId,
    );
    final projectId = department['projectId'];

    bool isAdminOrHead = false;
    print('✅ User ID: $userId');
    print('✅ Department ID: $departmentId');
    print('✅ Project ID: $projectId');

    try {
      // Check if user is head of the project
      final FirestoreProjectService projectService = FirestoreProjectService();
      final isHead = await projectService.isUserHeadOfProject(
        projectId,
        userId,
      );

      // Check if user is admin of the department
      final FirestoreDepartmentService departmentService =
          FirestoreDepartmentService();
      final isAdmin = await departmentService.isUserAdminOfDepartment(
        departmentId,
        userId,
      );

      isAdminOrHead = isHead || isAdmin;
    } catch (e) {
      print('Error checking user role: $e');
    }

    // Navigate to the appropriate page
    _navigateToDetailsPage(context, isAdminOrHead);
  }

  void _navigateToDetailsPage(BuildContext context, bool isAdminOrHead) {
    // if (isAdminOrHead) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TaskDetailsAdminPage(
              data: data,
              themeColor: themeColor,
              isAdminOrHead: isAdminOrHead,
            ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Color _getPriorityColor(
    bool isApproved,
    bool isRejected,
    bool isSubmitted,
    bool isOverdue,
    bool isUrgent,
  ) {
    if (isApproved) return Colors.green[600]!;
    if (isRejected) return Colors.red[400]!;
    if (isSubmitted) return Colors.blue[600]!;
    if (isOverdue) return Colors.red[600]!;
    if (isUrgent) return Colors.orange[600]!;
    return Colors.grey[700]!;
  }

  String _getPriorityText(
    bool isApproved,
    bool isRejected,
    bool isSubmitted,
    bool isOverdue,
    bool isUrgent,
  ) {
    if (isApproved) return 'APPROVED';
    if (isRejected) return 'REJECTED';
    if (isSubmitted) return 'SUBMITTED';
    if (isOverdue) return 'OVERDUE';
    if (isUrgent) return 'URGENT';
    return 'NORMAL';
  }
}
