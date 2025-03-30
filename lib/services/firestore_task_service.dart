import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreTaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new task with comment subcollection support
  Future<String?> createTask({
    required String departmentId,
    required String taskTitle,
    required String taskDescription,
    required DateTime endTask,
    List<String>? attachments,
  }) async {
    try {
      // Get current user
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Create task document
      DocumentReference taskRef = _firestore.collection('tasks').doc();

      final String taskId = taskRef.id; // Get the generated task ID

      // Prepare task data with comment subcollection support
      Map<String, dynamic> taskData = {
        'taskId': taskId,
        'taskTitle': taskTitle.trim(),
        'taskDescription': taskDescription.trim(),
        'startTask': Timestamp.now(), // Current timestamp as start
        'endTask': Timestamp.fromDate(endTask),
        'creatorId': currentUser.uid,
        'isSubmit': false,
        'isApproved': false,
        'attachments': attachments ?? [],
        'createdAt': FieldValue.serverTimestamp(),
        'departmentId': departmentId,
      };

      // Save task to Firestore
      await taskRef.set(taskData);

      // Add task ID to department's tasks array
      await _firestore.collection('departments').doc(departmentId).update({
        'tasks': FieldValue.arrayUnion([taskRef.id]),
      });

      return taskRef.id;
    } catch (e) {
      print('Error creating task: $e');
      return null;
    }
  }

  // Add a comment to a task
  Future<void> addCommentToTask({
    required String taskId,
    required String message,
  }) async {
    try {
      // Get current user
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Reference to the comments subcollection
      CollectionReference commentsRef = _firestore
          .collection('tasks')
          .doc(taskId)
          .collection('comments');

      // Prepare comment data
      Map<String, dynamic> commentData = {
        'userId': currentUser.uid,
        'message': message.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Add comment to subcollection
      await commentsRef.add(commentData);
    } catch (e)
    
     {
      print('Error adding comment: $e');
    }
  }

  // Get comments for a specific task
  Stream<QuerySnapshot> getTaskComments(String taskId) {
    return _firestore
        .collection('tasks')
        .doc(taskId)
        .collection('comments')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Update task submission status
  Future<bool> updateTaskSubmissionStatus({
    required String taskId,
    required bool isSubmitted,
  }) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'isSubmit': isSubmitted,
      });
      return true;
    } catch (e) {
      print('Error updating task submission status: $e');
      return false;
    }
  }

  // Get a specific task by ID
  Future<DocumentSnapshot?> getTaskById(String taskId) async {
    try {
      return await _firestore.collection('tasks').doc(taskId).get();
    } catch (e) {
      print('Error fetching task: $e');
      return null;
    }
  }

  Stream<QuerySnapshot> getTaskbyDepartmentID(String departmentId) {
    try {
      return _firestore
          .collection('tasks')
          .where('departmentId', isEqualTo: departmentId)
          .snapshots();
    } catch (e) {
      print('Error fetching polls: $e');
      rethrow;
    }
  }

  // Delete a task
  Future<bool> deleteTask(String taskId, String departmentId) async {
    try {
      // Remove task from department's tasks array
      await _firestore.collection('departments').doc(departmentId).update({
        'tasks': FieldValue.arrayRemove([taskId]),
      });

      // Delete the task document
      await _firestore.collection('tasks').doc(taskId).delete();

      return true;
    } catch (e) {
      print('Error deleting task: $e');
      return false;
    }
  }
}
