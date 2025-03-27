import 'package:flutter/material.dart';
import 'package:teammate/widgets/common/dialog/dialog_addPeople.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final bool isAdmin;
  final String projectId;
  final String departmentId;

  const EmptyState({
    super.key,
    required this.message,
    required this.isAdmin,
    required this.projectId,
    required this.departmentId,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 72, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          if (isAdmin) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => AddPeopleDialog(
                        title: 'ADD PEOPLE',
                        projectId: projectId,
                        departmentId: departmentId,
                      ),
                );
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Add People'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
