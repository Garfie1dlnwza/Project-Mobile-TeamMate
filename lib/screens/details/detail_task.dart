import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teammate/utils/date.dart';

class TaskDetailsPage extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color themeColor;

  const TaskDetailsPage({
    Key? key,
    required this.data,
    required this.themeColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String title = data['taskTitle'] ?? 'Untitled Task';
    final String description =
        data['taskDescription'] ?? 'No description provided';
    final bool isSubmitted = data['isSubmit'] ?? false;
    final Timestamp endDate = data['endTask'] ?? Timestamp.now();
    final DateTime dueDate = endDate.toDate();
    final bool isOverdue = DateTime.now().isAfter(dueDate) && !isSubmitted;
    final Duration timeLeft = dueDate.difference(DateTime.now());
    final bool isUrgent = timeLeft.inDays <= 2 && !isSubmitted;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        backgroundColor: themeColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and due date
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(isSubmitted, isOverdue, isUrgent),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _getPriorityText(isSubmitted, isOverdue, isUrgent),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: isOverdue ? Colors.red[600] : Colors.grey[700],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormatter.formatDateShort(dueDate),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isOverdue ? Colors.red[600] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              'Title',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),

            const SizedBox(height: 24),

            // Description
            Text(
              'Description',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Submit or update logic
                },
                icon: Icon(isSubmitted ? Icons.edit : Icons.check, size: 18),
                label: Text(isSubmitted ? 'Update Task' : 'Submit Task'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
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
