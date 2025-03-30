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

  Future<List<Map<String, dynamic>>> getTasksByDateAndDepartments({
    required List<String> departmentIds,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    List<Map<String, dynamic>> results = [];

    try {
      for (String deptId in departmentIds) {
        // ทดลองดึงงานเฉพาะตาม departmentId ก่อน
        QuerySnapshot snapshot =
            await _firestore
                .collection('tasks')
                .where('departmentId', isEqualTo: deptId)
                .get();

        // กรองด้วย endTask ตามช่วงเวลาที่ต้องการในโค้ด
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final Timestamp taskEndTime = data['endTask'] as Timestamp;

          // ตรวจสอบว่าอยู่ในช่วงเวลาที่ต้องการหรือไม่
          if (taskEndTime.toDate().isAfter(startDate) &&
              taskEndTime.toDate().isBefore(
                endDate.add(Duration(seconds: 1)),
              )) {
            results.add({
              'id': doc.id,
              'taskId': data['taskId'] ?? doc.id,
              'taskTitle': data['taskTitle'] ?? 'Untitled Task',
              'taskDescription': data['taskDescription'] ?? '',
              'startTask': data['startTask'] as Timestamp,
              'endTask': data['endTask'] as Timestamp,
              'isSubmit': data['isSubmit'] ?? false,
              'isApproved': data['isApproved'] ?? false,
              'isRejected': data['isRejected'] ?? false,
              'departmentId': data['departmentId'] ?? '',
            });
          }
        }
      }

      return results;
    } catch (e) {
      print('Error getTasksByDateAndDepartments: $e');
      return [];
    }
  }

  // ดึงงานสำหรับวันที่กำหนด โดยตรวจสอบทั้ง users และ admins
  Future<List<Map<String, dynamic>>> getTasksForDay(DateTime date) async {
    try {
      // Get current user
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // คำนวณช่วงเวลาของวัน
      final DateTime startOfDay = DateTime(date.year, date.month, date.day);
      final DateTime endOfDay = DateTime(
        date.year,
        date.month,
        date.day,
        23,
        59,
        59,
      );

      // ดึงแผนกที่ผู้ใช้เป็นสมาชิกหรือแอดมิน
      QuerySnapshot userDepartmentsSnapshot =
          await _firestore
              .collection('departments')
              .where(
                Filter.or(
                  Filter('users', arrayContains: currentUser.uid),
                  Filter('admins', arrayContains: currentUser.uid),
                ),
              )
              .get();

      List<String> departmentIds =
          userDepartmentsSnapshot.docs.map((doc) => doc.id).toList();

      // ถ้าไม่มีแผนก ให้คืนค่าลิสต์ว่าง
      if (departmentIds.isEmpty) {
        return [];
      }

      // ใช้เมธอดที่มีอยู่เพื่อดึงงานตามช่วงเวลา
      return await getTasksByDateAndDepartments(
        departmentIds: departmentIds,
        startDate: startOfDay,
        endDate: endOfDay,
      );
    } catch (e) {
      print('Error getting tasks for day: $e');
      return [];
    }
  }

  // ดึงแผนกทั้งหมดที่ผู้ใช้เป็นสมาชิกหรือแอดมิน
  Future<List<Map<String, dynamic>>> getUserDepartments() async {
    try {
      // Get current user
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // ดึงแผนกที่ผู้ใช้เป็นสมาชิกหรือแอดมิน
      QuerySnapshot userDepartmentsSnapshot =
          await _firestore
              .collection('departments')
              .where(
                Filter.or(
                  Filter('users', arrayContains: currentUser.uid),
                  Filter('admins', arrayContains: currentUser.uid),
                ),
              )
              .get();

      return userDepartmentsSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // เช็คว่าผู้ใช้เป็นแอดมินหรือไม่
        List<String> admins = List<String>.from(data['admins'] ?? []);
        bool isAdmin = admins.contains(currentUser.uid);

        return {
          'id': doc.id,
          'name': data['name'] ?? 'ไม่มีชื่อแผนก',
          'isAdmin': isAdmin,
        };
      }).toList();
    } catch (e) {
      print('Error getting user departments: $e');
      return [];
    }
  }

  // Other methods from your original service...
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
    } catch (e) {
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

  // ดึงงานทั้งหมดสำหรับเดือนที่กำหนด (ใช้ในหน้า Calendar)
  Future<List<Map<String, dynamic>>> getTasksForMonth(
    int month,
    int year,
  ) async {
    try {
      // Get current user
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // คำนวณวันแรกและวันสุดท้ายของเดือน
      final DateTime startOfMonth = DateTime(year, month, 1);
      final DateTime endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

      // ดึงแผนกที่ผู้ใช้เป็นสมาชิกหรือแอดมิน
      QuerySnapshot userDepartmentsSnapshot =
          await _firestore
              .collection('departments')
              .where(
                Filter.or(
                  Filter('users', arrayContains: currentUser.uid),
                  Filter('admins', arrayContains: currentUser.uid),
                ),
              )
              .get();

      List<String> departmentIds =
          userDepartmentsSnapshot.docs.map((doc) => doc.id).toList();

      // ถ้าไม่มีแผนก ให้คืนค่าลิสต์ว่าง
      if (departmentIds.isEmpty) {
        return [];
      }

      // ใช้เมธอดที่มีอยู่เพื่อดึงงานตามช่วงเวลา
      return await getTasksByDateAndDepartments(
        departmentIds: departmentIds,
        startDate: startOfMonth,
        endDate: endOfMonth,
      );
    } catch (e) {
      print('Error getting tasks for month: $e');
      return [];
    }
  }

  // ดึงชื่อแผนกจาก ID
  Future<String> getDepartmentName(String departmentId) async {
    try {
      DocumentSnapshot departmentDoc =
          await _firestore.collection('departments').doc(departmentId).get();

      if (departmentDoc.exists) {
        Map<String, dynamic> data =
            departmentDoc.data() as Map<String, dynamic>;
        return data['name'] ?? 'ไม่มีชื่อแผนก';
      }
      return 'ไม่พบแผนก';
    } catch (e) {
      print('Error getting department name: $e');
      return 'ข้อผิดพลาด';
    }
  }

  // เพิ่มงานใหม่ (เวอร์ชันสั้นสำหรับหน้า Calendar)
  Future<String?> addTask(Map<String, dynamic> taskData) async {
    try {
      if (!taskData.containsKey('departmentId') ||
          taskData['departmentId'] == null) {
        throw Exception('Department ID is required');
      }

      // แปลง taskData เป็นพารามิเตอร์สำหรับ createTask
      return await createTask(
        departmentId: taskData['departmentId'],
        taskTitle: taskData['title'] ?? 'Untitled Task',
        taskDescription: taskData['description'] ?? '',
        endTask: taskData['dueDate'] ?? DateTime.now().add(Duration(days: 1)),
        attachments: taskData['attachments'],
      );
    } catch (e) {
      print('Error adding task: $e');
      return null;
    }
  }
}
