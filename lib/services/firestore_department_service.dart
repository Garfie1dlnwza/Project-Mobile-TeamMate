import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreDepartmentService {
  final CollectionReference _departmentsCollection = FirebaseFirestore.instance
      .collection('departments');

  // สร้าง department ใหม่ใน Firestore
  Future<String> createDepartment(Map<String, dynamic> departmentData) async {
    DocumentReference docRef = await FirebaseFirestore.instance
        .collection('departments')
        .add(departmentData);
    return docRef.id;
  }

  // Get a stream of all departments
  Stream<QuerySnapshot> getProjectsStream() {
    return _departmentsCollection.snapshots();
  }

  // เพิ่ม admin ให้กับ department
  Future addAdminToDepartment(String departmentId, String userId) async {
    await _departmentsCollection.doc(departmentId).update({
      'admins': FieldValue.arrayUnion([userId]),
    });
  }

  // ลบ admin ออกจาก department
  Future removeAdminFromDepartment(String departmentId, String userId) async {
    await _departmentsCollection.doc(departmentId).update({
      'admins': FieldValue.arrayRemove([userId]),
    });
  }

  // เพิ่ม task ให้กับ department
  Future addTaskToDepartment(String departmentId, String taskId) async {
    await _departmentsCollection.doc(departmentId).update({
      'tasks': FieldValue.arrayUnion([taskId]),
    });
  }

  // ลบ task ออกจาก department
  Future removeTaskFromDepartment(String departmentId, String taskId) async {
    await _departmentsCollection.doc(departmentId).update({
      'tasks': FieldValue.arrayRemove([taskId]),
    });
  }

  // เพิ่ม poll ให้กับ department
  Future addPollToDepartment(String departmentId, String pollId) async {
    await _departmentsCollection.doc(departmentId).update({
      'polls': FieldValue.arrayUnion([pollId]),
    });
  }

  // ลบ poll ออกจาก department
  Future removePollFromDepartment(String departmentId, String pollId) async {
    await _departmentsCollection.doc(departmentId).update({
      'polls': FieldValue.arrayRemove([pollId]),
    });
  }

  // เพิ่ม document ให้กับ department
  Future addDocumentToDepartment(String departmentId, String documentId) async {
    await _departmentsCollection.doc(departmentId).update({
      'documents': FieldValue.arrayUnion([documentId]),
    });
  }

  // ลบ document ออกจาก department
  Future removeDocumentFromDepartment(
    String departmentId,
    String documentId,
  ) async {
    await _departmentsCollection.doc(departmentId).update({
      'documents': FieldValue.arrayRemove([documentId]),
    });
  }

  // เพิ่ม question ให้กับ department
  Future addQuestionToDepartment(String departmentId, String questionId) async {
    await _departmentsCollection.doc(departmentId).update({
      'questions': FieldValue.arrayUnion([questionId]),
    });
  }

  // ลบ question ออกจาก department
  Future removeQuestionFromDepartment(
    String departmentId,
    String questionId,
  ) async {
    await _departmentsCollection.doc(departmentId).update({
      'questions': FieldValue.arrayRemove([questionId]),
    });
  }

  // ตรวจสอบว่า user เป็น admin ของ department หรือไม่
  Future<bool> isUserAdminOfDepartment(
    String departmentId,
    String userId,
  ) async {
    DocumentSnapshot departmentDoc =
        await _departmentsCollection.doc(departmentId).get();
    Map data = departmentDoc.data() as Map;
    List admins = data['admins'] ?? [];
    return admins.contains(userId);
  }
}
