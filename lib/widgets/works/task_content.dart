import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teammate/screens/details/task_detail_admin_page.dart';
import 'package:teammate/services/firestore_department_service.dart';
import 'package:teammate/services/firestore_project_service.dart';
import 'package:teammate/services/firestore_user_service.dart';
import 'package:teammate/utils/date.dart';
import 'package:teammate/widgets/common/button/button_ok_reaction.dart';
import 'package:teammate/widgets/common/comment.dart';

class TaskContent extends StatefulWidget {
  final Map<String, dynamic> data;
  final Color themeColor;

  const TaskContent({super.key, required this.data, required this.themeColor});

  @override
  State<TaskContent> createState() => _TaskContentState();
}

class _TaskContentState extends State<TaskContent> {
  bool _showComments = false;
  final FirestoreUserService _userService = FirestoreUserService();

  @override
  Widget build(BuildContext context) {
    final String title = widget.data['taskTitle'] ?? 'Untitled Task';
    final bool isSubmitted = widget.data['isSubmit'] ?? false;
    final bool isApproved = widget.data['isApproved'] ?? false;
    final bool isRejected = widget.data['isRejected'] ?? false;
    final Timestamp endDate = widget.data['endTask'] ?? Timestamp.now();
    final DateTime dueDate = endDate.toDate();
    final bool isOverdue =
        DateTime.now().isAfter(dueDate) && !isApproved && !isSubmitted;
    final Duration timeLeft = dueDate.difference(DateTime.now());
    final bool isUrgent =
        timeLeft.inDays <= 2 && !isApproved && !isSubmitted && !isRejected;
    final String taskId = widget.data['taskId'] ?? widget.data['id'] ?? '';
    final String creatorId = widget.data['creatorId'] ?? '';

    return InkWell(
      onTap: () {
        // Navigate to details page
        _checkUserRoleAndNavigate(context);
      },
      child: Card(
        shadowColor: Colors.transparent,
        elevation: 1.5,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Creator info (if available)
              if (creatorId.isNotEmpty) ...[
                FutureBuilder<String?>(
                  future: _userService.findNameById(creatorId),
                  builder: (context, snapshot) {
                    final String creatorName = snapshot.data ?? 'Unknown User';

                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.grey[200],
                          child: Text(
                            creatorName.isNotEmpty
                                ? creatorName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: widget.themeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Created by $creatorName',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (widget.data['startTask'] != null)
                                Text(
                                  'on ${_formatStartDate(widget.data['startTask'])}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: Colors.grey[200]),
                const SizedBox(height: 12),
              ],

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
                        isApproved,
                        isRejected,
                        isSubmitted,
                        isOverdue,
                        isUrgent,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getPriorityText(
                        isApproved,
                        isRejected,
                        isSubmitted,
                        isOverdue,
                        isUrgent,
                      ),
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

              // Task description if available
              if (widget.data['taskDescription'] != null &&
                  widget.data['taskDescription'].toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  widget.data['taskDescription'],
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 16),

              // Interaction bar with OK button and comment toggle
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // OK reaction button
                    OkReactionButton(
                      contentId: taskId,
                      contentType: 'task',
                      themeColor: widget.themeColor,
                    ),

                    // Comment button
                    InkWell(
                      onTap: () {
                        setState(() {
                          _showComments = !_showComments;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      splashColor: widget.themeColor.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.comment_outlined,
                              size: 18,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Comment',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Details button
                    InkWell(
                      onTap: () {
                        _checkUserRoleAndNavigate(context);
                      },
                      borderRadius: BorderRadius.circular(8),
                      splashColor: widget.themeColor.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Details',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Comments section
              if (_showComments) ...[
                const SizedBox(height: 8),
                Divider(color: Colors.grey[200]),
                const SizedBox(height: 8),
                CommentWidget(
                  contentId: taskId,
                  contentType: 'task',
                  themeColor: widget.themeColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatStartDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return '';
  }

  Future<void> _checkUserRoleAndNavigate(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // Navigate to regular details page if not logged in
      _navigateToDetailsPage(context, false);
      return;
    }

    final userId = currentUser.uid;

    final departmentId = widget.data['departmentId'];
    final department = await FirestoreDepartmentService().getDepartmentById(
      departmentId,
    );
    final projectId = department['projectId'];

    bool isAdminOrHead = false;

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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TaskDetailsAdminPage(
              data: widget.data,
              themeColor: widget.themeColor,
              isAdminOrHead: isAdminOrHead,
            ),
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
