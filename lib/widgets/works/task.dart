import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teammate/screens/detail/detail_task.dart';
import 'package:teammate/utils/date.dart';

class TaskContent extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color themeColor;

  const TaskContent({Key? key, required this.data, required this.themeColor})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String title = data['taskTitle'] ?? 'Untitled Task';
    final bool isSubmitted = data['isSubmit'] ?? false;
    final Timestamp endDate = data['endTask'] ?? Timestamp.now();
    final DateTime dueDate = endDate.toDate();
    final bool isOverdue = DateTime.now().isAfter(dueDate) && !isSubmitted;
    final Duration timeLeft = dueDate.difference(DateTime.now());
    final bool isUrgent = timeLeft.inDays <= 2 && !isSubmitted;

    return Card(
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
                    color: _getPriorityColor(isSubmitted, isOverdue, isUrgent),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildActionButton(
                  icon: Icons.remove_red_eye,
                  label: 'Details',
                  color: Colors.grey[700]!,
                  backgroundColor: Colors.grey[200]!,
                  onPressed: () {
                    // Navigate to details page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => TaskDetailsPage(
                              data: data,
                              themeColor: themeColor,
                            ),
                      ),
                    );
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
