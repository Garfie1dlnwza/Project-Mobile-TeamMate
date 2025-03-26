import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreProjectService {
  final CollectionReference _projectsCollection = FirebaseFirestore.instance
      .collection('projects');

  Future<String> createProject(Map<String, dynamic> projectData) async {
    DocumentReference docRef = await _projectsCollection.add(projectData);
    return docRef.id;
  }

  // ดึงสตรีมของโปรเจคสำหรับผู้ใช้
  Stream<QuerySnapshot> getUserProjectsStream(List<String> projectIds) {
    if (projectIds.isEmpty) {
      return Stream.empty();
    }
    return _projectsCollection
        .where(FieldPath.documentId, whereIn: projectIds)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ดึงสตรีมของโปรเจคทั้งหมด
  Stream<QuerySnapshot> getProjectsStream() {
    return _projectsCollection
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ดึงโปรเจคเฉพาะโดย ID
  Future<DocumentSnapshot> getProjectById(String projectId) async {
    return await _projectsCollection.doc(projectId).get();
  }

  // อัปเดตข้อมูลโปรเจค
  Future<void> updateProject(
    String projectId,
    Map<String, dynamic> projectData,
  ) async {
    await _projectsCollection.doc(projectId).update(projectData);
  }

  // ลบโปรเจค
  Future<void> deleteProject(String projectId) async {
    await _projectsCollection.doc(projectId).delete();
  }

  // ดึงโปรเจคโดยใช้ department ID
  Future<DocumentSnapshot> getProjectByDepartmentId(String departmentId) async {
    try {
      // Query projects where the departments array contains the specified departmentId
      QuerySnapshot querySnapshot =
          await _projectsCollection
              .where('departments', arrayContains: departmentId)
              .limit(1)
              .get();

      // Check if we found any matching project
      if (querySnapshot.docs.isNotEmpty) {
        // Return the first matching project document
        return querySnapshot.docs.first;
      } else {
        // If no project found, throw an error
        throw Exception('No project found with department ID: $departmentId');
      }
    } catch (e) {
      // Handle any errors during the query process
      print('Error in getProjectByDepartmentId: $e');
      throw e;
    }
  }
}
