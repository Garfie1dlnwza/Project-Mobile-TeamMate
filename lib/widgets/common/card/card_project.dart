import 'package:flutter/material.dart';
import 'package:teammate/screens/myworks/work_page2.dart';
import 'package:teammate/services/firestore_user_service.dart';
import 'package:teammate/theme/app_colors.dart';
import 'dart:ui';

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

  // Calculate progress based on completed tasks
  double _calculateProgress() {
    if (data['tasks'] == null || (data['tasks'] as List).isEmpty) {
      return 0.0;
    }

    final int totalTasks = (data['tasks'] as List).length;
    final int completedTasks =
        data['completedTasks'] != null
            ? (data['completedTasks'] as List).length
            : 0;

    return totalTasks > 0 ? completedTasks / totalTasks : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    // Calculate project progress
    final double progress = _calculateProgress();
    final int progressPercent = (progress * 100).round();

    // Format due date if available
    String dueDateDisplay = data['dueDate'] ?? 'No deadline';

    // Define a more elegant color based on project color with reduced opacity
    final elegantColor = Color.lerp(projectColor, Colors.white, 0.7)!;
    final accentColor = Color.lerp(projectColor, AppColors.primary, 0.4)!;

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
                      (context) => WorkPageTwo(title: 'MY WORK', data: data),
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
                                  Row(
                                    children: [
                                      Text(
                                        data['tasks'] != null
                                            ? '${(data['tasks'] as List).length} Tasks'
                                            : 'No tasks',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.secondary,
                                        ),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.symmetric(
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
                        future: userService.findNameById(data['headId']),
                        builder: (context, userSnapshot) {
                          final managerName = userSnapshot.data ?? 'Unknown';
                          return Row(
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
                      Text(
                        'Project Progress',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.labelText,
                        ),
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
                                    0.7,
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
                                '$progressPercent% Complete',
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
