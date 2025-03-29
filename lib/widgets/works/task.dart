import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teammate/utils/date.dart';

class TaskContent extends StatefulWidget {
  final Map<String, dynamic> data;
  final Color themeColor;

  const TaskContent({Key? key, required this.data, required this.themeColor})
    : super(key: key);

  @override
  State<TaskContent> createState() => _TaskContentState();
}

class _TaskContentState extends State<TaskContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.data['taskTitle'] ?? 'Untitled Task';
    final String description = widget.data['taskDescription'] ?? '';
    final bool isSubmitted = widget.data['isSubmit'] ?? false;
    final Timestamp endDate = widget.data['endTask'] ?? Timestamp.now();
    final DateTime dueDate = endDate.toDate();
    final bool isOverdue = DateTime.now().isAfter(dueDate) && !isSubmitted;

    // Calculate task priority based on due date proximity
    final Duration timeLeft = dueDate.difference(DateTime.now());
    final bool isUrgent = timeLeft.inDays <= 2 && !isSubmitted;

    // Calculate progress for animation
    final double progress = isSubmitted ? 1.0 : 0.5;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Priority indicator and task metadata
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getPriorityColor(isSubmitted, isOverdue, isUrgent),
                  borderRadius: BorderRadius.circular(12),
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
              const SizedBox(width: 10),
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
                  fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (isSubmitted) ...[
                const SizedBox(width: 8),
                Icon(Icons.check_circle, size: 14, color: Colors.green[600]),
                const SizedBox(width: 2),
                Text(
                  'Completed',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Task title
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
              height: 1.3,
            ),
          ),

          const SizedBox(height: 12),

          // Task progress indicator
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            // Background
                            Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            // Progress
                            Container(
                              height: 6,
                              width:
                                  MediaQuery.of(context).size.width *
                                  0.8 *
                                  _progressAnimation.value *
                                  progress,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors:
                                      isSubmitted
                                          ? [
                                            Colors.green[400]!,
                                            Colors.green[600]!,
                                          ]
                                          : isOverdue
                                          ? [Colors.red[400]!, Colors.red[600]!]
                                          : [
                                            Colors.grey[600]!,
                                            Colors.grey[800]!,
                                          ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          // Description (collapsible)
          if (description.isNotEmpty) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                setState(() {
                  _expanded = !_expanded;
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ],

          const SizedBox(height: 20),

          // Task action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildActionButton(
                icon: Icons.remove_red_eye,
                label: 'Details',
                color: Colors.grey[700]!,
                backgroundColor: Colors.grey[200]!,
                onPressed: () {
                  // View details logic
                },
              ),
              const SizedBox(width: 10),
              _buildActionButton(
                icon: isSubmitted ? Icons.edit : Icons.check,
                label: isSubmitted ? 'Update' : 'Submit',
                color: Colors.white,
                backgroundColor: Colors.grey[800]!,
                onPressed: () {
                  // Submit or update logic
                },
              ),
            ],
          ),
        ],
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

  Color _getPriorityColor(bool isSubmitted, bool isOverdue, bool isUrgent) {
    if (isSubmitted) return Colors.green[600]!;
    if (isOverdue) return Colors.red[600]!;
    if (isUrgent) return Colors.orange[600]!;
    return Colors.grey[700]!;
  }

  String _getPriorityText(bool isSubmitted, bool isOverdue, bool isUrgent) {
    if (isSubmitted) return 'COMPLETED';
    if (isOverdue) return 'OVERDUE';
    if (isUrgent) return 'URGENT';
    return 'NORMAL';
  }
}
