import 'package:flutter/material.dart';
import 'package:teammate/screens/myworks/work_page2.dart';
import 'package:teammate/services/firestore_user_service.dart';


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

    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [projectColor, projectColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: projectColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WorkPageTwo(title: 'MY WORK', data: data),
              ),
            );
          },
          splashColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.white.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.folder_special_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              data['name'] ?? 'Unnamed Project',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                overflow: TextOverflow.ellipsis,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                FutureBuilder<String?>(
                  future: userService.findNameById(data['headId']),
                  builder: (context, userSnapshot) {
                    final managerName = userSnapshot.data ?? 'Unknown';
                    return Row(
                      children: [
                        const Icon(
                          Icons.person,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Project Manager: $managerName',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                if (data['tasks'] != null && (data['tasks'] as List).isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.task_alt,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Tasks: ${(data['tasks'] as List).length}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                // Progress indicator
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress: $progressPercent%',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dueDateDisplay,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
