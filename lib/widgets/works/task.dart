import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teammate/utils/date.dart';

class TaskContent extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color themeColor;

  const TaskContent({Key? key, required this.data, required this.themeColor})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String title = data['taskTitle'] ?? 'Untitled Task';
    final String description = data['taskDescription'] ?? '';
    final bool isSubmitted = data['isSubmit'] ?? false;
    final Timestamp endDate = data['endTask'] ?? Timestamp.now();
    final DateTime dueDate = endDate.toDate();
    final bool isOverdue = DateTime.now().isAfter(dueDate) && !isSubmitted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Task title
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        // Task description
        if (description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(description, style: TextStyle(color: Colors.grey[700])),
        ],

        const SizedBox(height: 12),

        // Task due date and status
        Row(
          children: [
            Text(
              'Due: ${DateFormatter.formatDateShort(dueDate)}',
              style: TextStyle(
                color: isOverdue ? Colors.red : Colors.grey[700],
                fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            // Status chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:
                    isSubmitted
                        ? Colors.green
                        : isOverdue
                        ? Colors.red
                        : Colors.amber,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isSubmitted
                    ? 'Completed'
                    : isOverdue
                    ? 'Overdue'
                    : 'In Progress',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Task action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () {
                // View task details
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('View Details'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                // Submit task
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(isSubmitted ? 'Update' : 'Submit'),
            ),
          ],
        ),
      ],
    );
  }
}
