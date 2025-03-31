import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreDepartmentService {
  final CollectionReference _departmentsCollection = FirebaseFirestore.instance
      .collection('departments');

  Future<String> getDepartmentName(String departmentId) async {
    final doc = await _departmentsCollection.doc(departmentId).get();
    if (doc.exists) {
      return doc.get('name') ?? 'Unnamed Department';
    }
    throw Exception('Department not found');
  }

  Future<List<String>> getDepartmentIdsByUid(String uid) async {
    List<String> departmentIds = [];

    try {
      // Query departments where user is in the users array
      final userDepartments =
          await _departmentsCollection.where('users', arrayContains: uid).get();

      // Add these department IDs to our result list
      for (var doc in userDepartments.docs) {
        departmentIds.add(doc.id);
      }

      // Query departments where user is in the admins array
      final adminDepartments =
          await _departmentsCollection
              .where('admins', arrayContains: uid)
              .get();

      // Add these department IDs to our result list, avoiding duplicates
      for (var doc in adminDepartments.docs) {
        if (!departmentIds.contains(doc.id)) {
          departmentIds.add(doc.id);
        }
      }

      return departmentIds;
    } catch (e) {
      print("Error getting departments for user: $e");
      rethrow;
    }
  }

  // สร้าง department ใหม่ใน Firestore
  Future<String> createDepartment(Map<String, dynamic> departmentData) async {
    DocumentReference docRef = await _departmentsCollection.add(departmentData);
    return docRef.id;
  }

  // ดึง department จาก Firestore ด้วย ID
  Future<DocumentSnapshot> getDepartmentById(String departmentId) async {
    return await _departmentsCollection.doc(departmentId).get();
  }

  Stream<QuerySnapshot> getUserDepartmentStream(List<String> departmentIds) {
    if (departmentIds.isEmpty) {
      return Stream.empty();
    }
    return _departmentsCollection
        .where(FieldPath.documentId, whereIn: departmentIds)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get a stream of all departments
  Stream<QuerySnapshot> getDepartmentStream() {
    return _departmentsCollection.snapshots();
  }

  // เพิ่ม admin ให้กับ department
  Future<void> addAdminToDepartment({
    required String departmentId,
    required String adminId,
  }) async {
    try {
      await _departmentsCollection.doc(departmentId).update({
        'admins': FieldValue.arrayUnion([adminId]),
      });
    } catch (e) {
      print("Error adding admin to department: $e");
      rethrow;
    }
  }

  // เพิ่ม user ให้กับ department
  Future<void> addUserToDepartment({
    required String departmentId,
    required String userId,
  }) async {
    try {
      await _departmentsCollection.doc(departmentId).set({
        'users': FieldValue.arrayUnion([userId]),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error adding user to department: $e");
      rethrow;
    }
  }

  // add people to department (alternative name for same action)
  Future<void> addPeopleToDepartment(String departmentId, String userId) async {
    await addUserToDepartment(departmentId: departmentId, userId: userId);
  }

  // ลบ admin ออกจาก department
  Future<void> removeAdminFromDepartment(
    String departmentId,
    String userId,
  ) async {
    await _departmentsCollection.doc(departmentId).update({
      'admins': FieldValue.arrayRemove([userId]),
    });
  }

  // Helper method for adding items to array fields
  Future<void> _addItemToArrayField(
    String departmentId,
    String fieldName,
    String itemId,
  ) async {
    await _departmentsCollection.doc(departmentId).update({
      fieldName: FieldValue.arrayUnion([itemId]),
    });
  }

  // Helper method for removing items from array fields
  Future<void> _removeItemFromArrayField(
    String departmentId,
    String fieldName,
    String itemId,
  ) async {
    await _departmentsCollection.doc(departmentId).update({
      fieldName: FieldValue.arrayRemove([itemId]),
    });
  }

  // Add/remove task methods
  Future<void> addTaskToDepartment(String departmentId, String taskId) async {
    await _addItemToArrayField(departmentId, 'tasks', taskId);
  }

  Future<void> removeTaskFromDepartment(
    String departmentId,
    String taskId,
  ) async {
    await _removeItemFromArrayField(departmentId, 'tasks', taskId);
  }

  // Add/remove poll methods
  Future<void> addPollToDepartment(String departmentId, String pollId) async {
    await _addItemToArrayField(departmentId, 'polls', pollId);
  }

  Future<void> removePollFromDepartment(
    String departmentId,
    String pollId,
  ) async {
    await _removeItemFromArrayField(departmentId, 'polls', pollId);
  }

  // Add/remove document methods
  Future<void> addDocumentToDepartment(
    String departmentId,
    String documentId,
  ) async {
    await _addItemToArrayField(departmentId, 'documents', documentId);
  }

  Future<void> removeDocumentFromDepartment(
    String departmentId,
    String documentId,
  ) async {
    await _removeItemFromArrayField(departmentId, 'documents', documentId);
  }

  // Add/remove question methods
  Future<void> addQuestionToDepartment(
    String departmentId,
    String questionId,
  ) async {
    await _addItemToArrayField(departmentId, 'questions', questionId);
  }

  Future<void> removeQuestionFromDepartment(
    String departmentId,
    String questionId,
  ) async {
    await _removeItemFromArrayField(departmentId, 'questions', questionId);
  }

  // ตรวจสอบว่า user เป็น admin ของ department หรือไม่
  Future<bool> isUserAdminOfDepartment(
    String departmentId,
    String userId,
  ) async {
    DocumentSnapshot departmentDoc =
        await _departmentsCollection.doc(departmentId).get();
    Map<String, dynamic>? data = departmentDoc.data() as Map<String, dynamic>?;

    if (data == null) return false;

    List<dynamic> admins = data['admins'] ?? [];
    return admins.contains(userId);
  }
}
