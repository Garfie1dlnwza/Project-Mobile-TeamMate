import 'package:flutter/material.dart';
import 'package:teammate/screens/myworks/work_page2.dart';
import 'package:teammate/services/firestore_user_service.dart';
import 'package:teammate/theme/app_colors.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ProjectCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color projectColor;
  final FirestoreUserService userService;

  const ProjectCard({
    super.key,
    required this.data,
    required this.projectColor,
    required this.userService,
  });

  // Calculate progress based on combined tasks from all departments
  Future<Map<String, dynamic>> _calculateCombinedProgress() async {
    final String projectId = data['projectId'] ?? data['id'] ?? '';
    if (projectId.isEmpty) {
      return {
        'totalTasks': 0,
        'completedTasks': 0,
        'progress': 0.0,
        'progressPercent': 0,
      };
    }

    try {
      // Get all department IDs for this project
      List<String> departmentIds = [];
      if (data.containsKey('departments') &&
          data['departments'] != null &&
          data['departments'] is List) {
        final deptsList = data['departments'] as List<dynamic>;
        departmentIds = deptsList.map((item) => item.toString()).toList();
      }

      // If no departments, check for project-level tasks
      int totalTasks = 0;
      int completedTasks = 0;

      if (departmentIds.isEmpty) {
        // Use the original project-level task calculation
        return _calculateProjectLevelProgress();
      }

      // Get all tasks from all departments in this project
      for (String departmentId in departmentIds) {
        // Get tasks for this department
        QuerySnapshot tasksSnapshot =
            await FirebaseFirestore.instance
                .collection('tasks')
                .where('departmentId', isEqualTo: departmentId)
                .get();

        // Add to total count
        totalTasks += tasksSnapshot.docs.length;

        // Count approved tasks
        for (var doc in tasksSnapshot.docs) {
          Map<String, dynamic> taskData = doc.data() as Map<String, dynamic>;
          if (taskData['isApproved'] == true) {
            completedTasks++;
          }
        }
      }

      // Calculate progress
      double progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;
      int progressPercent = (progress * 100).round();

      return {
        'totalTasks': totalTasks,
        'completedTasks': completedTasks,
        'progress': progress,
        'progressPercent': progressPercent,
      };
    } catch (e) {
      print('Error calculating combined progress: $e');
      return _calculateProjectLevelProgress(); // Fallback to project level calculation
    }
  }

  // Original progress calculation (at project level only)
  Map<String, dynamic> _calculateProjectLevelProgress() {
    // Check if tasks exists and is not empty
    if (data['tasks'] == null ||
        data['tasks'] is! List ||
        (data['tasks'] as List).isEmpty) {
      return {
        'totalTasks': 0,
        'completedTasks': 0,
        'progress': 0.0,
        'progressPercent': 0,
      };
    }

    final int totalTasks = (data['tasks'] as List).length;

    // Get completed tasks count (approved tasks)
    int completedTasks = 0;

    // Check if completedTasks or approvedTasks field exists
    if (data['completedTasks'] != null && data['completedTasks'] is List) {
      completedTasks = (data['completedTasks'] as List).length;
    } else if (data['approvedTasks'] != null && data['approvedTasks'] is List) {
      completedTasks = (data['approvedTasks'] as List).length;
    } else {
      // If no specific field for completed tasks, we'll count approved tasks manually
      if (data['taskDetails'] != null && data['taskDetails'] is List) {
        for (var task in (data['taskDetails'] as List)) {
          if (task is Map && task['isApproved'] == true) {
            completedTasks++;
          }
        }
      }
    }

    final double progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;
    final int progressPercent = (progress * 100).round();

    return {
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
      'progress': progress,
      'progressPercent': progressPercent,
    };
  }

  // Format the due date appropriately
  String _formatDueDate() {
    // Check if dueDate exists
    if (data['dueDate'] == null) {
      return 'No deadline';
    }

    try {
      // Handle different date formats
      if (data['dueDate'] is Timestamp) {
        // Firebase Timestamp
        final Timestamp timestamp = data['dueDate'] as Timestamp;
        final DateTime dateTime = timestamp.toDate();
        return DateFormat('MMM d, yyyy').format(dateTime);
      } else if (data['dueDate'] is String) {
        // String date
        final String dateStr = data['dueDate'] as String;
        if (dateStr.isEmpty) {
          return 'No deadline';
        }

        try {
          final DateTime dateTime = DateTime.parse(dateStr);
          return DateFormat('MMM d, yyyy').format(dateTime);
        } catch (e) {
          // If parsing fails, return the string as is
          return dateStr;
        }
      } else if (data['dueDate'] is DateTime) {
        // DateTime object
        final DateTime dateTime = data['dueDate'] as DateTime;
        return DateFormat('MMM d, yyyy').format(dateTime);
      } else {
        // Unknown format
        return 'No deadline';
      }
    } catch (e) {
      print('Error formatting date: $e');
      return 'No deadline';
    }
  }

  // Get task count properly
  String _getTaskCountText(int totalTasks) {
    return totalTasks == 0
        ? 'No tasks'
        : '$totalTasks ${totalTasks == 1 ? 'Task' : 'Tasks'}';
  }

  @override
  Widget build(BuildContext context) {
    // Format due date
    final String dueDateDisplay = _formatDueDate();

    // Define a more elegant color based on project color with reduced opacity
    final elegantColor = Color.lerp(projectColor, Colors.white, 0.7)!;
    final accentColor = Color.lerp(projectColor, AppColors.primary, 0.4)!;

    return FutureBuilder<Map<String, dynamic>>(
      future: _calculateCombinedProgress(),
      builder: (context, snapshot) {
        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard(context, elegantColor, accentColor);
        }

        // Get progress data
        final progressData = snapshot.data ?? _calculateProjectLevelProgress();
        final int totalTasks = progressData['totalTasks'];
        final double progress = progressData['progress'];
        final int progressPercent = progressData['progressPercent'];

        // Get task count text
        final String taskCountText = _getTaskCountText(totalTasks);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: accentColor.withOpacity(0.05),
                blurRadius: 16,
                spreadRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              WorkPageTwo(title: 'MY WORK', data: data),
                    ),
                  );
                },
                splashColor: accentColor.withOpacity(0.05),
                highlightColor: accentColor.withOpacity(0.02),
                child: Column(
                  children: [
                    // Project Header with gradient overlay
                    Container(
                      height: 80,
                      decoration: BoxDecoration(color: elegantColor),
                      child: Stack(
                        children: [
                          // Subtle pattern overlay for texture
                          Opacity(
                            opacity: 0.06,
                            child: CustomPaint(
                              size: const Size(double.infinity, 80),
                              painter: PatternPainter(accentColor),
                            ),
                          ),

                          // Content
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Project icon in elegant container
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 6,
                                        spreadRadius: 0,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.folder_outlined,
                                    color: accentColor,
                                    size: 24,
                                  ),
                                ),

                                const SizedBox(width: 16),

                                // Project title and task count
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        data['name'] ?? 'Unnamed Project',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                          letterSpacing: 0.2,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            taskCountText,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.secondary,
                                            ),
                                          ),
                                          if (taskCountText != 'No tasks') ...[
                                            Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                              width: 3,
                                              height: 3,
                                              decoration: BoxDecoration(
                                                color: AppColors.secondary
                                                    .withOpacity(0.5),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            Text(
                                              dueDateDisplay,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.secondary,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Project details
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Project manager with elegant styling
                          FutureBuilder<String?>(
                            future: userService.findNameById(
                              data['headId'] ?? '',
                            ),
                            builder: (context, userSnapshot) {
                              final managerName =
                                  userSnapshot.data ?? 'Not assigned';
                              return Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(
                                        0.05,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.person_outline,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Project Manager',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.secondary,
                                        ),
                                      ),
                                      Text(
                                        managerName,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 20),

                          // Progress section with elegant styling
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Project Progress',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.labelText,
                                ),
                              ),
                              if (taskCountText == 'No tasks')
                                Text(
                                  'No tasks to track',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.secondary.withOpacity(0.7),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Stack(
                            children: [
                              // Progress bar background
                              Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),

                              // Progress indicator
                              Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeInOut,
                                    height: 40,
                                    width:
                                        MediaQuery.of(context).size.width *
                                        progress *
                                        0.7, // Adjust for card width and padding
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          accentColor.withOpacity(0.7),
                                          accentColor,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ],
                              ),

                              // Percentage text
                              Positioned.fill(
                                child: Center(
                                  child: Text(
                                    taskCountText == 'No tasks'
                                        ? 'No progress to show'
                                        : '$progressPercent% Complete',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          progressPercent > 50
                                              ? Colors.white
                                              : AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper method to build a loading card
  Widget _buildLoadingCard(
    BuildContext context,
    Color elegantColor,
    Color accentColor,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: accentColor.withOpacity(0.05),
            blurRadius: 16,
            spreadRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Project Header with gradient overlay (same as normal)
          Container(
            height: 80,
            decoration: BoxDecoration(color: elegantColor),
            child: Stack(
              children: [
                // Subtle pattern overlay for texture
                Opacity(
                  opacity: 0.06,
                  child: CustomPaint(
                    size: const Size(double.infinity, 80),
                    painter: PatternPainter(accentColor),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Project icon in elegant container
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.folder_outlined,
                          color: accentColor,
                          size: 24,
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Project title placeholder
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              data['name'] ?? 'Unnamed Project',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 100,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Loading indicators for project details
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Project manager placeholder
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.person_outline,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Project Manager',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.secondary,
                          ),
                        ),
                        Container(
                          width: 120,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Progress section placeholder
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Project Progress',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.labelText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for subtle background pattern
class PatternPainter extends CustomPainter {
  final Color color;

  PatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 0.5
          ..style = PaintingStyle.stroke;

    // Draw subtle diagonal lines
    for (int i = -20; i < size.width + size.height; i += 15) {
      canvas.drawLine(Offset(i.toDouble(), 0), Offset(0, i.toDouble()), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
