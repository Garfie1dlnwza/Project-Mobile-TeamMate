import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreProjectService {
  final CollectionReference _projectsCollection = FirebaseFirestore.instance
      .collection('projects');

  Future<String> getProjectName(String projectId) async {
    final doc = await getProjectById(projectId);
    return doc.get('name') ?? 'Unnamed Project';
  }

  // สร้างโปรเจคใหม่ใน Firestore
  Future<String> createProject(Map<String, dynamic> projectData) async {
    try {
      DocumentReference docRef = await _projectsCollection.add(projectData);
      return docRef.id;
    } catch (e) {
      print("Error creating project: $e");
      rethrow;
    }
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

  // ดึงโปรเจคเฉพาะโดย ID
  Future<DocumentSnapshot> getProjectById(String projectId) async {
    try {
      return await _projectsCollection.doc(projectId).get();
    } catch (e) {
      print("Error getting project by ID: $e");
      rethrow;
    }
  }

  // อัปเดตข้อมูลโปรเจค
  Future<void> updateProject(
    String projectId,
    Map<String, dynamic> projectData,
  ) async {
    try {
      await _projectsCollection.doc(projectId).update(projectData);
    } catch (e) {
      print("Error updating project: $e");
      rethrow;
    }
  }

  Future<String?> getHeadNameByHeadId(String projectId) async {
    try {
      // First get the headId from the project
      final headId = await getHeadIdByProjectId(projectId);
      if (headId == null) return null;

      // Then get the user document to get the name
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(headId)
              .get();

      if (userDoc.exists) {
        return userDoc.get('name')
            as String?; // Assuming the name field is 'name'
      }
      return null;
    } catch (e) {
      print("Error getting head name by head ID: $e");
      return null;
    }
  }

  Future<String?> getHeadIdByProjectId(String projectId) async {
    try {
      DocumentSnapshot projectSnapshot =
          await _projectsCollection.doc(projectId).get();

      if (projectSnapshot.exists) {
        return projectSnapshot.get('headId') as String?;
      } else {
        print("Project with ID $projectId not found.");
        return null;
      }
    } catch (e) {
      print("Error getting headId by project ID: $e");
      return null;
    }
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
        throw Exception('No project found with department ID: $departmentId');
      }
    } catch (e) {
      print('Error in getProjectByDepartmentId: $e');
      rethrow;
    }
  }

  // ตรวจสอบว่า user เป็น head ของ project หรือไม่
  Future<bool> isUserHeadOfProject(String projectId, String userId) async {
    try {
      DocumentSnapshot projectDoc =
          await _projectsCollection.doc(projectId).get();
      if (!projectDoc.exists) {
        return false;
      }
      Map<String, dynamic>? data = projectDoc.data() as Map<String, dynamic>?;
      if (data == null) {
        return false;
      }
      // Check if headId is a single string or a list
      dynamic headId = data['headId'];
      if (headId is String) {
        return headId == userId;
      } else if (headId is List) {
        return headId.contains(userId);
      }
      return false;
    } catch (e) {
      print("Error checking if user is head of project: $e");
      return false;
    }
  }
}
