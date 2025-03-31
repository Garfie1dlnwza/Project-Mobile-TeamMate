// This class provides utility methods for calculating task progress
// for both departments and projects
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskProgressCalculator {
  // Calculate progress for a department based on task completion
  static Future<Map<String, dynamic>> calculateDepartmentProgress(
    String departmentId,
    FirebaseFirestore firestore,
  ) async {
    try {
      // Get tasks for this department
      final tasksSnapshot =
          await firestore
              .collection('tasks')
              .where('departmentId', isEqualTo: departmentId)
              .get();

      // Calculate progress metrics
      return _calculateProgressFromTasks(tasksSnapshot.docs);
    } catch (e) {
      print('Error calculating department progress: $e');
      return _getEmptyProgressResult();
    }
  }

  // Calculate progress for a project by aggregating all its departments
  static Future<Map<String, dynamic>> calculateProjectProgress(
    String projectId,
    List<String> departmentIds,
    FirebaseFirestore firestore,
  ) async {
    try {
      // If no department IDs, return zero progress
      if (departmentIds.isEmpty) {
        return _getEmptyProgressResult();
      }

      // Get all tasks for all departments in this project
      final tasksSnapshot =
          await firestore
              .collection('tasks')
              .where('departmentId', whereIn: departmentIds)
              .get();

      // Calculate progress metrics
      return _calculateProgressFromTasks(tasksSnapshot.docs);
    } catch (e) {
      print('Error calculating project progress: $e');
      return _getEmptyProgressResult();
    }
  }

  // Calculate project progress directly from project document
  static Map<String, dynamic> calculateProjectProgressFromDoc(
    Map<String, dynamic> projectData,
  ) {
    try {
      // Check if tasks exists and is not empty
      if (projectData['tasks'] == null ||
          projectData['tasks'] is! List ||
          (projectData['tasks'] as List).isEmpty) {
        return _getEmptyProgressResult();
      }

      final int totalTasks = (projectData['tasks'] as List).length;
      int completedTasks = 0;

      // Check if completedTasks or approvedTasks field exists
      if (projectData['completedTasks'] != null &&
          projectData['completedTasks'] is List) {
        completedTasks = (projectData['completedTasks'] as List).length;
      } else if (projectData['approvedTasks'] != null &&
          projectData['approvedTasks'] is List) {
        completedTasks = (projectData['approvedTasks'] as List).length;
      } else {
        // If no specific field for completed tasks, we'll count approved tasks manually
        if (projectData['taskDetails'] != null &&
            projectData['taskDetails'] is List) {
          for (var task in (projectData['taskDetails'] as List)) {
            if (task is Map && task['isApproved'] == true) {
              completedTasks++;
            }
          }
        }
      }

      // Calculate progress values
      double progressRatio = totalTasks > 0 ? completedTasks / totalTasks : 0.0;
      double progressPercent = progressRatio * 100;

      return {
        'totalTasks': totalTasks,
        'completedTasks': completedTasks,
        'progressPercent': progressPercent,
        'progressRatio': progressRatio,
      };
    } catch (e) {
      print('Error calculating project progress from doc: $e');
      return _getEmptyProgressResult();
    }
  }

  // Calculate progress values from a list of task documents
  static Map<String, dynamic> _calculateProgressFromTasks(
    List<QueryDocumentSnapshot> taskDocs,
  ) {
    int totalTasks = taskDocs.length;
    int completedTasks = 0;

    // Count completed (approved) tasks
    for (var taskDoc in taskDocs) {
      final taskData = taskDoc.data() as Map<String, dynamic>;
      if (taskData['isApproved'] == true) {
        completedTasks++;
      }
    }

    // Calculate progress values
    double progressRatio = totalTasks > 0 ? completedTasks / totalTasks : 0.0;
    double progressPercent = progressRatio * 100;

    return {
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
      'progressPercent': progressPercent,
      'progressRatio': progressRatio,
    };
  }

  // Get a default empty progress result
  static Map<String, dynamic> _getEmptyProgressResult() {
    return {
      'totalTasks': 0,
      'completedTasks': 0,
      'progressPercent': 0,
      'progressRatio': 0.0,
    };
  }

  // Get task count text
  static String getTaskCountText(Map<String, dynamic> data) {
    if (data['tasks'] == null || data['tasks'] is! List) {
      return 'No tasks';
    }

    final int taskCount = (data['tasks'] as List).length;
    return '$taskCount ${taskCount == 1 ? 'Task' : 'Tasks'}';
  }

  // Get task status text based on completion percentage
  static String getTaskStatusText(double progressPercent) {
    if (progressPercent == 0) {
      return 'Not started';
    } else if (progressPercent < 25) {
      return 'Just started';
    } else if (progressPercent < 50) {
      return 'In progress';
    } else if (progressPercent < 75) {
      return 'Moving along';
    } else if (progressPercent < 100) {
      return 'Almost done';
    } else {
      return 'Completed';
    }
  }
}
